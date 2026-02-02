import ArgumentParser
import Foundation
import Logging
import GRPCCore
import GRPCNIOTransportHTTP2
import Logging

struct GrpcParseLabel: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "gRPC client for interacting with a \"docent\" server to parse a label.")
    
    @Option(help: "The host name for the gRPC server.")
    var host: String = "127.0.0.1"
    
    @Option(help: "The port for the gRPC server.")
    var port: Int = 8080
    
    @Option(help: "Enable verbose logging")
    var verbose: Bool = false
    
    @Argument(help: "The text to operate on. If \"-\" then data is read from STDIN. If the first argument is a valid path to a local file then the text of that file will be used. Otherwise all remaining arguments will be concatenated (with a space) and used as the text to process.")
    var args: [String]
    
    func run() async throws {
        
        var logger = Logger(label: "org.sfomuseum.docent.grpc.client")

        if verbose {
            logger.logLevel = .debug
        }
        
        try await withGRPCClient(
            
            transport: .http2NIOPosix(
                target: .ipv4(address: self.host, port: self.port),
                transportSecurity: .plaintext
            )
            
        ) { client in
            
            var input: String
            
            do {
                 input = try TextFromArgs(args: args)
            } catch {
                logger.error("Failed to derive text from args \(error)")
                throw error
            }

                
                var req = OrgSfomuseumDocentService_ParseWallLabelRequest()
                req.body = input
                
                let server = OrgSfomuseumDocentService_DocentService.Client(wrapping: client)
                let rsp = try await server.parseWallLabel(req)
                
                print(rsp.body)

        }
        
    }
    
}
