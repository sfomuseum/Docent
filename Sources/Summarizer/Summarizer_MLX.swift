import Foundation
import Logging

import MLX
import MLXLLM
import MLXLMCommon

enum MLXSummarizerErrors: Error {
    case missingModel
    case unknownModel
}
    
public struct MLXSummarizer: Summarizer {
    
    var logger: Logger?
    var model: ModelContext
    
    public init(_ Summarizer_uri: String, logger: Logger?) async throws {
        
        guard let u = URL(string: Summarizer_uri) else {
            throw SummarizerErrors.invalidURI
        }
        
        guard let components = URLComponents(url: u, resolvingAgainstBaseURL: false) else {
            throw SummarizerErrors.invalidURI
        }
        
        guard let model_name = components.queryItems?.first(where: { $0.name == "model" })?.value else {
            throw MLXSummarizerErrors.missingModel
        }
        var model: ModelContext?
        
        do {
            model = try await loadModel(id: model_name)
        } catch {
            throw error
        }
        
        self.logger = logger
        self.model = model!
    }
    
    public func summarize(text: String, maxLength: Int) async -> Result<String, any Error> {
        
        let prompt: String = "Analyze this text and generate a summary that is not longer than \(maxLength) characters. Focus on retaining the meaning of the text rather than the exact text itself. Be consistent not uniform. The text to summary is: " + text
        
        let session = ChatSession(self.model)
        let result: String
        
        do {
            result = try await session.respond(to: prompt)
        } catch {
            return .failure(error)
        }
        
        self.logger?.debug("DONE \(result)")
        return .success(result)
    }

}

