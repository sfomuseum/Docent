import Foundation
import Logging

public enum ParserErrors: Error {
    case invalidURI
    case unsupportedParser
    case invalidParser
}

public protocol Parser {
    
    init(_ parser_uri: String, instructions: String, logger: Logger?) async throws
    func parse(text: String) async -> Result<WallLabel, Error>
    func model() -> String
}

public func NewParser(_ parser_uri: String, logger: Logger?) async throws -> Parser {
    
    guard let u = URL(string: parser_uri) else {
        throw ParserErrors.invalidURI
    }
    
    var instructions: String
    
    switch (u.scheme) {
    case "mlx":
        instructions = default_label_parser_instructions + not_generable_label_parser_instructions
    default:
        instructions = default_label_parser_instructions
    }
    
    return try await NewParserWithInstructions(parser_uri, instructions: instructions, logger: logger)
}

public func NewParserWithInstructions(_ parser_uri: String, instructions: String, logger: Logger?) async throws -> Parser {
    
    guard let u = URL(string: parser_uri) else {
        throw ParserErrors.invalidURI
    }
    
    var label_parser: Parser
    
    do {
        switch (u.scheme) {
        case "disabled":
            label_parser = try DisabledParser(parser_uri, instructions: instructions, logger: logger)
        case "mlx":
            label_parser = try await MLXParser(parser_uri, instructions: instructions, logger: logger)
        case "foundation":
            
            if #available(iOS 26.0, macOS 26.0, *) {
                label_parser = try FoundationModelParser(parser_uri, instructions: instructions, logger: logger)
            } else {
                throw ParserErrors.unsupportedParser
            }
            
        default:
            throw ParserErrors.invalidParser
        }
    } catch {
        throw error
    }
    
    return label_parser
}
