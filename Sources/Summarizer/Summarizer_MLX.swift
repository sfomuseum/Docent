import Foundation
import Logging

import MLX
import MLXLLM
import MLXLMCommon
import Hub

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
        
        guard let u = URL(string: summarizer_uri) else {
            throw SummarizerErrors.invalidURI
        }
        
        guard let components = URLComponents(url: u, resolvingAgainstBaseURL: false) else {
            throw SummarizerErrors.invalidURI
        }
        
        guard let model_name = components.queryItems?.first(where: { $0.name == "model" })?.value else {
            throw MLXSummarizerErrors.missingModel
        }
        
        var hub = defaultHubApi
    
        if let downloads = components.queryItems?.first(where: { $0.name == "downloads" })?.value {
            
            guard let downloads_url = URL(string: downloads) else {
                throw MLXSummarizerErrors.invalidDownloadLocation
            }
            
            logger?.debug("Use custom downloads location \(downloads_url.absoluteString)")
            hub = HubApi(downloadBase: downloads_url)
        }
        
        var model_context: ModelContext?
        
        do {
            model_context = try await loadModel(hub: hub, id: model_name, progressHandler: { status in
                logger?.debug("Loading \(model_name) \(status.fractionCompleted * 100)% complete")
            })
        } catch {
            throw error
        }
        
        self.logger = logger
        self.model_name = model_name
        self.model_context = model_context!
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

