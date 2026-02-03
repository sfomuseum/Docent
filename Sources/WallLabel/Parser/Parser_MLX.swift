import Foundation
import Logging

import MLX
import MLXLLM
import MLXLMCommon
import Hub

enum MLXParserErrors: Error, LocalizedError {
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
    
public struct MLXParser: Parser {
    
    var instructions: String
    var logger: Logger?
    var model_name: String
    var model_context: ModelContext
    
    public init(_ parser_uri: String, instructions: String, logger: Logger?) async throws {
        
        logger?.debug("initialize MLX label parser with \(parser_uri)")
        
        guard let u = URL(string: parser_uri) else {
            throw ParserErrors.invalidURI
        }
        
        guard let components = URLComponents(url: u, resolvingAgainstBaseURL: false) else {
            throw ParserErrors.invalidURI
        }
        
        guard let model_name = components.queryItems?.first(where: { $0.name == "model" })?.value else {
            throw MLXParserErrors.missingModel
        }

        var hub = defaultHubApi
    
        if let downloads = components.queryItems?.first(where: { $0.name == "downloads" })?.value {
            
            guard let downloads_url = URL(string: downloads) else {
                throw MLXParserErrors.invalidDownloadLocation
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
        
        self.instructions = instructions
        self.logger = logger
        self.model_name = model_name
        self.model_context = model_context!
    }
    
    public init(_ model_context: ModelContext, instructions: String, logger: Logger?) async throws {
        self.instructions = instructions
        self.model_context = model_context
        self.model_name = model_context.configuration.name // ??
        self.logger = logger
    }
    
    public func parse(text: String) async -> Result<WallLabel, any Error> {
        
        let t1 = Date()
        
        defer {
            let t2 = Date()
            logger?.debug("Time to parse wall label \(t2.timeIntervalSince(t1)) seconds")
        }
        
        let prompt =  text
        
        let session = ChatSession(self.model_context)
        let result: String
                       
        do {
            session.instructions = instructions
            result = try await session.respond(to: prompt)
        } catch {
            logger?.error("Failed to parse label text, \(error)")
            return .failure(error)
        }
        
        // self.logger?.debug("\(result)")        
        let data = result.data(using: .utf8)
        
        do {
            
            var label = try JSONDecoder().decode(WallLabelNotGenerable.self, from: data!)
            
            label.input = text
            label.timestamp = Int(NSDate().timeIntervalSince1970)
            label.latitude = 0.0
            label.longitude = 0.0

            return .success(label)
        } catch {
            logger?.error("Failed to decode wall label text, \(error)")
            return .failure(error)
        }
        
    }

    public func model() -> String {
        return model_name
    }
}

