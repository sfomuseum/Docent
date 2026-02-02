import FoundationModels
import Foundation

import Logging

@available(iOS 26.0, macOS 26.0, *)
struct FoundationModelSummarizer: Summarizer {
    
    var logger: Logger?
    var model_name: String
    
    init(_ summarizer_uri: String, logger: Logger?) async throws {
        self.logger = logger
        
        let proc = ProcessInfo()
        self.model_name = String(format:"apple/foundationmodels#%@", proc.operatingSystemVersionString)
    }
    
    func summarize(text: String, maxLength: Int) async -> Result<String, any Error> {

        let t1 = Date()
        
        defer {
            let t2 = Date()
            logger?.debug("Time to summarize text \(t2.timeIntervalSince(t1)) seconds")
        }
        
        let local_instructions = default_summarizer_instructions.replacingOccurrences(of: "{MAX_LENGTH}", with: "\(maxLength)")

            do {

                let session = LanguageModelSession(instructions: local_instructions)
                
                let response = try await session.respond(
                    to: text,
                )
                                
                return .success(response.content)

            } catch {
                logger?.error("Failed to generate summary \(error)")
                return .failure(error)
            }

    }
    
    public func model() -> String {
        return model_name
    }
    
}
