import ArgumentParser

import Logging
import WallLabel

enum ParseErrors: Error {
    case invalidParser
    case stringifyError
}

struct Label: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Parse the text of a wall label in to JSON-encoded structured data.")
    
    @Option(help: "The parser scheme is to use for parsing wall label text.")
    var parser_uri: String = "mlx://?model=mlx-community/Olmo-3-7B-Instruct-8bit"
    
    @Option(help: "The label text to parse in to structured data.")
    var label_text: String = ""
    
    @Option(help: "Optional custom instructions to use when parsing wall label text.")
    var instructions: String = ""
    
    @Option(help: "Enable verbose logging")
    var verbose: Bool = false
    
    func run() async throws {
        
        var logger = Logger(label: "org.sfomuseum.docent.label")

        if verbose {
            logger.logLevel = .debug
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
        
        let parse_rsp = await label_parser.parse(text: label_text)
        
        switch parse_rsp {
        case .success(let label):
            
            let encode_rsp = label.marshalJSON()
            
            switch (encode_rsp) {
            case .success(let data):
                
                guard let str_data = String(data: data, encoding: .utf8) else {
                    throw ParseErrors.stringifyError
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
