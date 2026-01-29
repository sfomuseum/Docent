import FoundationModels
import Foundation

import Logging

@available(iOS 26.0, macOS 26.0, *)
struct FoundationModelSummarizer: Summarizer {
    
    var logger: Logger?
    
    init(_ summarizer_uri: String, logger: Logger?) async throws {
        self.logger = logger
    }
    
    func summarize(text: String, maxLength: Int) async -> Result<String, any Error> {
        
        let instructions = "Analyze this text and generate a summary that is not longer than \(maxLength) characters. Focus on retaining the meaning of the text rather than the exact text itself. Be consistent not uniform."
        
            do {

                let session = LanguageModelSession(instructions: instructions)
                
                let response = try await session.respond(
                    to: text,
                    // generating: WallLabelGenerable.self
                )
                                
                return .success(response.content)

            } catch {
                return .failure(error)
            }

    }
    
    
    
}
