import ArgumentParser
import Foundation
import Logging
import WallLabel
import Summarizer
import GRPCCore
import GRPCNIOTransportHTTP2
import GRPCProtobuf
import DocentModels

enum GrpcServerError: Error, LocalizedError {
    case invalidEncoderURI
    case invalidText
    case invalidURI
    case missingModel
    case invalidDownloadLocation
    
    public var errorDescription: String? {
        switch self {
        case .invalidEncoderURI:
            return "Failed to construct encoder URI from model(s)."
        case .invalidText:
            return "Input text is invalid."
        case .invalidURI:
            return "Invalid URI (failed to parse)"
        case .missingModel:
            return "Missing ?model= parameter"
        case .invalidDownloadLocation:
            return "Invalid download location"
        }
    }
}

class Tools: @unchecked Sendable {
    final var labelParser: Parser
    final var summarizer: Summarizer
    final var summarizerMaxLength: Int
    final var summarizerMaxAttempts: Int
    
    init(labelParser: Parser, summarizer: Summarizer, summarizerMaxLength: Int, summarizerMaxAttempts: Int) {
        self.labelParser = labelParser
        self.summarizer = summarizer
        self.summarizerMaxLength = summarizerMaxLength
        self.summarizerMaxAttempts = summarizerMaxAttempts
    }
}

struct GrpcServer: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "gRPC server for exposing \"docent\"-related tasks.")
    
    @Option(help: "The host name to listen for new connections")
    var host: String = "127.0.0.1"
    
    @Option(help: "The port to listen on")
    var port: Int = 8080
    
    @Option(help: "A URI denoting the framework and model to use for parsing wall labels.")
    var label_parser_uri: String = default_label_parser_uri
    
    @Option(help: "A URI denoting the framework and model to use for summarizing text.")
    var summarizer_uri: String = default_summarizer_uri
    
    @Option(help: "The default value and maximum length for summary texts.")
    var summarizer_max_length: Int = 77

    @Option(help: "The default value and maximum length for retrying text-summarizing.")
    var summarizer_max_attempts: Int = 20
    
    @Option(help: "Sets the maximum message size in bytes the server may receive. If 0 then the swift-grpc defaults will be used.")
    var max_receive_message_length = 0
    
    @Option(help: "The TLS certificate chain to use for encrypted connections")
    var tls_certificate: String = ""
    
    @Option(help: "The TLS private key to use for encrypted connections")
    var tls_key: String = ""
    
    @Option(help: "The TLS certificate for the CA that signed the TLS certificate used for encrypted connections.")
    var tls_ca_certificate: String = ""
    
    @Option(help: "...")
    var token_uri: String = ""
    
    @Option(help: "Enable verbose logging")
    var verbose: Bool = false
    
    func run() async throws {
        
        var logger = Logger(label: "org.sfomuseum.docent.grpcd")

        if verbose {
            logger.logLevel = .debug
        }
        
        var transportSecurity = HTTP2ServerTransport.Posix.TransportSecurity.plaintext
        
        // https://github.com/grpc/grpc-swift/issues/2219
        
        if tls_certificate != "" && tls_key != ""  {
            
            let certSource:  TLSConfig.CertificateSource   = .file(path: tls_certificate, format: .pem)
            let keySource:   TLSConfig.PrivateKeySource    = .file(path: tls_key, format: .pem)
            
            transportSecurity = HTTP2ServerTransport.Posix.TransportSecurity.tls(
                certificateChain: [ certSource ],
                privateKey: keySource,
            )
        }
        
        // Keepalive configs necessary because this:
        // https://github.com/grpc/grpc-swift-2/issues/5#issuecomment-2984421768
        
        // https://github.com/grpc/grpc-swift-nio-transport/blob/15f9bfee04d19c1d720f34c6c6b3e8214bf557db/Sources/GRPCNIOTransportCore/Server/HTTP2ServerTransport.swift#L85
        
        let client_keepalive = HTTP2ServerTransport.Config.ClientKeepaliveBehavior.init(
            // Default is 300 (5 minutes)
            minPingIntervalWithoutCalls: .seconds(1),
            // Default is false
            allowWithoutCalls: true
        )
        
        // https://github.com/grpc/grpc-swift-nio-transport/blob/15f9bfee04d19c1d720f34c6c6b3e8214bf557db/Sources/GRPCNIOTransportCore/Server/HTTP2ServerTransport.swift#L52
        
        var server_keepalive = HTTP2ServerTransport.Config.Keepalive.defaults
        server_keepalive.clientBehavior = client_keepalive
        
        var interceptors: [ServerInterceptor] = []
        
        if token_uri != "" {
            logger.debug("Configure token interceptor")
            
            do {
                let token_interceptor = try ServerTokenInterceptor(token_uri, logger: logger)
                interceptors.append(token_interceptor)
            } catch {
                logger.error("Failed to create server interceptor, \(error)")
                throw error
            }
            
        }
        
        let transport = HTTP2ServerTransport.Posix(
            address: .ipv4(host: self.host, port: self.port),
            transportSecurity: transportSecurity,
            config: .defaults { config in
                if max_receive_message_length > 0 {
                    config.rpc.maxRequestPayloadSize = max_receive_message_length
                }
                config.connection.keepalive = server_keepalive
              }
        )
        
        var label_parser: Parser?
        var summarizer: Summarizer?
        var tools: Tools!
        
        do {
            
            if label_parser_uri == summarizer_uri && label_parser_uri.starts(with: "mlx://"){
                
                var model: MLXModel
                
                let model_rsp = await loadMLXModel(label_parser_uri, logger: logger)
                
                switch model_rsp {
                case .failure(let error):
                    throw error
                case .success(let m):
                    model = m
                }
                
                let instructions = default_label_parser_instructions + not_generable_label_parser_instructions
                
                label_parser = try await MLXParser(model.context, instructions: instructions, logger: logger)
                summarizer = try await MLXSummarizer(model.context, logger: logger)
                
                // END OF I am not happy to have to do it this way
                
            } else {
                label_parser = try await NewParser(label_parser_uri, logger: logger)
                summarizer = try await NewSummarizer(summarizer_uri, logger: logger)
            }
            
            tools = Tools(
                labelParser: label_parser!,
                summarizer: summarizer!,
                summarizerMaxLength: summarizer_max_length,
                summarizerMaxAttempts: summarizer_max_attempts,
            )
            
        } catch {
            logger.error("Failed to configure tools")
            throw error
        }
        
        let service = DocentService(tools, logger: logger)
        
        let server = GRPCServer(
            transport: transport,
            services: [service],
            interceptors: interceptors
        )
                
        try await withThrowingDiscardingTaskGroup { group in
            // Why does this time out?
            // let address = try await transport.listeningAddress
            logger.info("listening for requests on \(self.host):\(self.port))")
            group.addTask { try await server.serve() }
        }
    }
}

struct DocentService: OrgSfomuseumDocentService_DocentService.SimpleServiceProtocol {

    var tools: Tools
    var logger: Logger
    
    init(_ tools: Tools, logger: Logger) {
        self.tools = tools
        self.logger = logger
    }
    
    func parseWallLabel(request: OrgSfomuseumDocentService_ParseWallLabelRequest, context: GRPCCore.ServerContext) async throws -> OrgSfomuseumDocentService_ParseWallLabelResponse {
        
        let t1 = Date()
        
        defer {
            let t2 = Date()
            logger.info("Time to parse label text \(t2.timeIntervalSince(t1)) seconds")
        }
        
        let rsp = await self.tools.labelParser.parse(text: request.body)
        
        switch rsp {
        case .failure(let error):
            logger.error("Failed to parse label text, \(error)")
            throw RPCError(code: .internalError, message: error.localizedDescription)
        case .success(let wl):
  
            let enc_rsp = wl.marshalJSON()
            
            switch enc_rsp {
            case .failure(let error):
                throw RPCError(code: .internalError, message: error.localizedDescription)
            case .success(let data):
                
                guard let body = String(data: data, encoding: .utf8) else {
                    throw RPCError(code: .internalError, message: "Unable to convert data to string")
                }
                
                var rsp = OrgSfomuseumDocentService_ParseWallLabelResponse()
                rsp.body = body
                rsp.model = tools.labelParser.model()
                return rsp
            }
            
        }
        
    }
    
    func summarizeText(request: OrgSfomuseumDocentService_SummarizeTextRequest, context: GRPCCore.ServerContext) async throws -> OrgSfomuseumDocentService_SummarizeTextResponse {
                
        let t1 = Date()
        
        defer {
            let t2 = Date()
            logger.info("Time to summary text \(t2.timeIntervalSince(t1)) seconds")
        }
        
        var max_len = tools.summarizerMaxLength
        var max_retries = 1
        
        if request.hasMaxLength {
        
            if request.maxLength > tools.summarizerMaxLength {
                throw RPCError(code: .invalidArgument, message: "Invalid max length")
            }
            
            max_len = Int(request.maxLength)
        }
        
        if request.hasMaxRetries {
            
            if request.maxRetries > tools.summarizerMaxAttempts {
                throw RPCError(code: .invalidArgument, message: "Invalid max retries")
            }
            
            logger.debug("Summarize text with \(request.maxRetries) retries")
            max_retries = Int(request.maxRetries)
        }
        
            let req = SummarizeWithRetriesRequest(
                text: request.body,
                max_length: max_len,
                max_attempts: max_retries
            )
            
            let rsp = await SummarizeWithRetries(tools.summarizer, req, logger: logger)
            
            switch rsp {
            case .failure(let error):
                logger.error("Failed to summarize text, \(error)")
                throw RPCError(code: .internalError, message: error.localizedDescription)
            case .success(let sum_rsp):
                
                var rsp = OrgSfomuseumDocentService_SummarizeTextResponse()
                rsp.body = sum_rsp.summary
                rsp.model = tools.summarizer.model()
                rsp.attempts = Int32(sum_rsp.attempts)
                return rsp
            }
        
    }
}
