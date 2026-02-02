import Foundation
import Logging
  
enum DisabledSummarizerErrors: Error, LocalizedError {
    case disabled
    
    public var errorDescription: String? {
        switch self {
        case .disabled:
            return "Service is disabled"
        }
    }
}

public struct DisabledSummarizer: Summarizer {
    
    var logger: Logger?
    
    public init(_ Summarizer_uri: String, logger: Logger?) throws {
        self.logger = logger
    }
    
    public func summarize(text: String, maxLength: Int) async -> Result<String, any Error> {
        
        let t1 = Date()
        
        defer {
            let t2 = Date()
            logger?.debug("Time to summarize text \(t2.timeIntervalSince(t1)) seconds")
        }
        
        return .failure(DisabledSummarizerErrors.disabled)
    }

    public func model() -> String {
        return "n/a"
    }
}

