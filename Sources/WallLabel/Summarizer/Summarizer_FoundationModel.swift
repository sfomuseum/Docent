import FoundationModels
import Foundation

import Logging

@available(iOS 26.0, macOS 26.0, *)
struct FoundationModelSummarizer: Summarizer {
    
    var instructions: String
    var logger: Logger?
    
    init(_ summarizer_uri: String, instructions: String, logger: Logger?) throws {
        self.instructions = instructions
        self.logger = logger
    }
    
    func summarize(text: String) async -> Result<String, any Error> {
        
            do {

                let session = LanguageModelSession(instructions: self.instructions)
                
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
