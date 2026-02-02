import ArgumentParser

import Logging
import WallLabel

enum ParseLabelErrors: Error {
    case invalidParser
    case stringifyError
    
    public var errorDescription: String? {
        switch self {
        case .invalidParser:
            return "Invalid or unsupported label parser URI."
        case .stringifyError:
            return "Failed to stringify response."
        }
    }
}

struct ParseLabel: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Parse the text of a wall label in to JSON-encoded structured data.")
    
    @Option(help: "The parser scheme is to use for parsing wall label text.")
    var parser_uri: String = default_label_parser_uri
    
    @Option(help: "Optional custom instructions to use when parsing wall label text.")
    var instructions: String = ""
    
    @Option(help: "Enable verbose logging")
    var verbose: Bool = false
    
    @Argument(help: "The text to parse. If \"-\" then data is read from STDIN. If the first argument is a valid path to a local file then the text of that file will be used. Otherwise all remaining arguments will be concatenated (with a space) and used as the text to parse.")
    var args: [String]
    
    func run() async throws {
        
        var logger = Logger(label: "org.sfomuseum.docent.label")

        if verbose {
            logger.logLevel = .debug
        }
        
        var text: String
        
        do {
             text = try TextFromArgs(args: args)
        } catch {
            logger.error("Failed to derive text from args \(error)")
            throw error
        }
        
        var label_parser: Parser
        
        do {
            
            if instructions != "" {
                label_parser = try await NewParserWithInstructions(parser_uri, instructions: instructions, logger: logger)
            } else {
                label_parser = try await NewParser(parser_uri, logger: logger)
            }
            
        } catch {
            throw error
        }
        
        let parse_rsp = await label_parser.parse(text: text)
        
        switch parse_rsp {
        case .success(let label):
            
            let encode_rsp = label.marshalJSON()
            
            switch (encode_rsp) {
            case .success(let data):
                
                guard let str_data = String(data: data, encoding: .utf8) else {
                    throw ParseLabelErrors.stringifyError
                }
                
                print(str_data)
            case .failure(let err):
                throw err
            }
            
        case .failure(let err):
            throw err
        }
        
    }
}
