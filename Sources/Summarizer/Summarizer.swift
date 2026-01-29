import Foundation
import Logging

public enum SummarizerErrors: Error {
    case invalidURI
    case unsupportedSummarizer
    case invalidSummarizer
}

public protocol Summarizer {
    
    init(_ summarizer_uri: String, logger: Logger?) throws
    func summarize(text: String, maxLength: Int) async -> Result<String, Error>
}

public func NewSummarizer(_ summarizer_uri: String, logger: Logger?) throws -> Summarizer {
    
    guard let u = URL(string: summarizer_uri) else {
        throw SummarizerErrors.invalidURI
    }
    
    var summarizer: Summarizer
    
    do {
        switch (u.scheme) {
        case "mlx":
            summarizer = try MLXSummarizer(summarizer_uri, logger: logger)
        case "foundation":
            
            if #available(iOS 26.0, macOS 26.0, *) {
                summarizer = try FoundationModelSummarizer(summarizer_uri, logger: logger)
            } else {
                throw SummarizerErrors.unsupportedSummarizer
            }
            
        default:
            throw SummarizerErrors.invalidSummarizer
        }
    } catch {
        throw error
    }
    
    return summarizer
}
