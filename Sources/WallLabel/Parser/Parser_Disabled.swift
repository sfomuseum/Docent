import Foundation
import Logging
  
enum DisabledParserErrors: Error, LocalizedError {
    case disabled
    
    public var errorDescription: String? {
        switch self {
        case .disabled:
            return "Service is disabled"
        }
    }
}

public struct DisabledParser: Parser {

    var logger: Logger?
    
    public init(_ parser_uri: String, instructions: String, logger: Logger?) throws {
        self.logger = logger
    }
    
    public func parse(text: String) async -> Result<WallLabel, any Error> {
        
        let t1 = Date()
        
        defer {
            let t2 = Date()
            logger?.debug("Time to parse wall label \(t2.timeIntervalSince(t1)) seconds")
        }
        
        return .failure(DisabledParserErrors.disabled)
    }

    public func model() -> String {
        return "n/a"
    }
}

