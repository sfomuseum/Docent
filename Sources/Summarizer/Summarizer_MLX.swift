import Foundation
import Logging

import MLX
import MLXLLM
import MLXLMCommon

enum MLXSummarizerErrors: Error {
    case missingModel
    case unknownModel
    
    public var errorDescription: String? {
        switch self {
        case .missingModel:
            return "URI is missing ?model= parameter"
        case .unknownModel:
            return "Invalid or unsupported model"
        }
    }
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
            model = try await loadModel(id: model_name, progressHandler: { status in
                logger?.debug("Loading \(model_name) \(status.fractionCompleted * 100)% complete")
            })
        } catch {
            throw error
        }
        
        self.logger = logger
        self.model = model!
    }
    
    public init(_ model: ModelContext, logger: Logger?) async throws {
        self.model = model
        self.logger = logger
    }
    
    public func summarize(text: String, maxLength: Int) async -> Result<String, any Error> {
        
        let t1 = Date()
        
        defer {
            let t2 = Date()
            logger?.debug("Time to summarize text \(t2.timeIntervalSince(t1)) seconds")
        }
        
        let local_instructions = instructions.replacingOccurrences(of: "{MAX_LENGTH}", with: "\(maxLength)")
        let prompt = text
        
        let session = ChatSession(self.model)
        let result: String
                        
        do {
            session.instructions = local_instructions
            result = try await session.respond(to: prompt)
        } catch {
            logger?.error("Failed to generate summary \(error)")
            return .failure(error)
        }

        return .success(result)
    }

}

