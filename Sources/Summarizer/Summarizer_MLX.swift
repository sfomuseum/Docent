import Foundation
import Logging

import MLX
import MLXLLM
import MLXLMCommon
import MLXDocent

enum MLXSummarizerErrors: Error {
    case missingModel
    case unknownModel
    case invalidDownloadLocation
    
    public var errorDescription: String? {
        switch self {
        case .missingModel:
            return "URI is missing ?model= parameter"
        case .unknownModel:
            return "Invalid or unsupported model"
        case .invalidDownloadLocation:
            return "Invalid download location"
        }
    }
}
    
public struct MLXSummarizer: Summarizer {
    
    var logger: Logger?
    var model_name: String
    var model_context: ModelContext
    
    public init(_ summarizer_uri: String, logger: Logger?) async throws {
        
        logger?.debug("initialize MLX summarizer with \(summarizer_uri)")
        
        var model: MLXModel
        
        let model_rsp = await loadMLXModel(summarizer_uri, logger: logger)
        
        switch model_rsp {
        case .failure(let error):
            throw error
        case .success(let m):
            model = m
        }
        
        self.logger = logger
        self.model_name = model.name
        self.model_context = model.context
    }
    
    public init(_ model_context: ModelContext, logger: Logger?) async throws {
        self.model_context = model_context
        self.model_name = model_context.configuration.name // ??
        self.logger = logger
    }
    
    public func summarize(text: String, maxLength: Int) async -> Result<String, any Error> {
        
        let t1 = Date()
        
        defer {
            let t2 = Date()
            logger?.debug("Time to summarize text \(t2.timeIntervalSince(t1)) seconds")
        }
        
        let local_instructions = default_summarizer_instructions.replacingOccurrences(of: "{MAX_LENGTH}", with: "\(maxLength)")
        let prompt = text
        
        let session = ChatSession(self.model_context)
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

    public func model() -> String {
        return model_name
    }
}

