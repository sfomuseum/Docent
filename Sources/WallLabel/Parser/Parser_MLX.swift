import Foundation
import Logging

import MLX
import MLXLLM
import MLXLMCommon
import MLXDocent

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
        
        var model: MLXModel
        
        let model_rsp = await loadMLXModel(parser_uri, logger: logger)
        
        switch model_rsp {
        case .failure(let error):
            throw error
        case .success(let m):
            model = m
        }        
        
        self.instructions = instructions
        self.logger = logger
        self.model_name = model.name
        self.model_context = model.context
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

