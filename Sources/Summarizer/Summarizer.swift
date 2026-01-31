import Foundation
import Logging

public enum SummarizerErrors: Error {
    case invalidURI
    case unsupportedSummarizer
    case invalidSummarizer
    case missingModel
    case exceedsMaxAttempts
}

public struct SummarizeWithRetriesRequest {
    public var text: String
    public var max_length: Int
    public var max_attempts: Int
}

public struct SummarizeWithRetriesResponse {
    public var summary: String
    public var attempts: Int
    public var timeToComplete: Int64
    public var model: String
}

public func SummarizeWithRetries(_ summarizer: Summarizer, _ req: SummarizeWithRetriesRequest, logger: Logger?) async -> Result<SummarizeWithRetriesResponse, Error> {
    
    var attempts: Int = 0
    var summary: String = req.text
    
    var max_length = req.max_length
    var max_attempts = req.max_attempts
    
    let t1 = Date()
    
    while attempts == 0 || summary.count > max_length {
        
        attempts += 1
        
        let rsp = await summarizer.summarize(text: summary, maxLength: max_length)
        
        switch rsp {
        case .failure(let error):
            return .failure(error)
        case .success(let text):
            summary = text
        }
            
        if summary.count <= max_length {
            break
        }
        
        if attempts >= max_attempts {
            return .failure(SummarizerErrors.exceedsMaxAttempts)
        }
    }
    
    let t2 = Date()
    let ttc = Int64(t2.timeIntervalSince(t1))

    let rsp = SummarizeWithRetriesResponse(summary: summary, attempts: attempts, timeToComplete: ttc, model: summarizer.model())
    return .success(rsp)
}

public protocol Summarizer {
    
    init(_ summarizer_uri: String, logger: Logger?) async throws
    func summarize(text: String, maxLength: Int) async -> Result<String, Error>
    func model() -> String
}

public func NewSummarizer(_ summarizer_uri: String, logger: Logger?) async throws -> Summarizer {
    
    guard let u = URL(string: summarizer_uri) else {
        throw SummarizerErrors.invalidURI
    }
    
    var summarizer: Summarizer
    
    do {
        switch (u.scheme) {
        case "mlx":
            summarizer = try await MLXSummarizer(summarizer_uri, logger: logger)
        case "disabled":
            summarizer =  try DisabledSummarizer(summarizer_uri, logger: logger)
        case "foundation":
            
            if #available(iOS 26.0, macOS 26.0, *) {
                summarizer = try await FoundationModelSummarizer(summarizer_uri, logger: logger)
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
