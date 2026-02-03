import ArgumentParser
import Foundation
import Logging
import GRPCCore
import GRPCNIOTransportHTTP2
import Logging



struct GrpcSummarize: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "gRPC client for interacting with a \"docent\" server to summarize a text.")
    
    @Option(help: "The host name for the gRPC server.")
    var host: String = "127.0.0.1"
    
    @Option(help: "The port for the gRPC server.")
    var port: Int = 8080
    
    @Option(help: "The TLS certificate chain to use for encrypted connections.")
    var tls_certificate: String = ""

    @Option(help: "The TLS certificate for the CA that signed the TLS certificate used for encrypted connections.")
    var tls_ca_certificate: String = ""
    
    @Option(help: "The maximum length of the summary text. This value may be overridden by the gRPC server.")
    var max_length: Int = 77
    
    @Option(help: "The maximum number of attempts to make summarizing the text to be no longer than the value of the --max_length flag. This value may be overridden by the gRPC server.")
    var max_retries: Int = 1
    
    @Option(help:"A gocloud.dev/runtimevar compatible URI containing a shared authentication token to include with requests. Currently supported schemes: file://, constant://")
    var token_uri: String = ""
    
    @Option(help: "Enable verbose logging")
    var verbose: Bool = false
    
    @Argument(help: "The text to operate on. If \"-\" then data is read from STDIN. If the first argument is a valid path to a local file then the text of that file will be used. Otherwise all remaining arguments will be concatenated (with a space) and used as the text to process.")
    var args: [String]
    
    func run() async throws {
        
        var logger = Logger(label: "org.sfomuseum.docent.grpc-summarize")

        if verbose {
            logger.logLevel = .debug
        }
        
        let transportSecurity = grpcClientTransortSecurity(tls_certificate: tls_certificate, tls_ca_certificate: tls_ca_certificate, logger: logger)
        
        var interceptors: [ClientInterceptor] = []
        
        do {
            interceptors = try grpcClientInterceptors(token_uri: token_uri, logger: logger)
        } catch {
            throw error
        }
        
        try await withGRPCClient(
            
            transport: .http2NIOPosix(
                target: .dns(host: self.host, port: self.port),
                transportSecurity: transportSecurity
            ),
            interceptors: interceptors
            
        ) { client in
            
            var input: String
            
            do {
                 input = try TextFromArgs(args: args)
            } catch {
                logger.error("Failed to derive text from args \(error)")
                throw error
            }

                
                var req = OrgSfomuseumDocentService_SummarizeTextRequest()
                req.body = input
                req.maxRetries = Int32(max_retries)
            req.maxLength = Int32(max_length)
            
                let server = OrgSfomuseumDocentService_DocentService.Client(wrapping: client)
                
                let rsp = try await server.summarizeText(req)
            
            do {
                try print(rsp.jsonString())
            } catch {
                throw error
            }

        }
        
    }
    
}
