import Foundation
import Logging

import MLX
import MLXLLM
import MLXLMCommon

enum MLXParserErrors: Error {
    case missingModel
    case unknownModel
}
    
public struct MLXParser: Parser {
    
    var instructions: String
    var logger: Logger?
    var model: ModelContext
    
    public init(_ parser_uri: String, instructions: String, logger: Logger?) async throws {
        
        guard let u = URL(string: parser_uri) else {
            throw ParserErrors.invalidURI
        }
        
        guard let components = URLComponents(url: u, resolvingAgainstBaseURL: false) else {
            throw ParserErrors.invalidURI
        }
        
        guard let model_name = components.queryItems?.first(where: { $0.name == "model" })?.value else {
            throw MLXParserErrors.missingModel
        }

        var model: ModelContext?
        
        do {
            model = try await loadModel(id: model_name, progressHandler: { status in
                logger?.debug("Loading \(model_name) \(status.fractionCompleted * 100)% complete")
            })
        } catch {
            throw error
        }
        
        self.instructions = instructions
        self.logger = logger
        self.model = model!
    }
    
    public func parse(text: String) async -> Result<WallLabel, any Error> {
        
        let t1 = Date()
        
        defer {
            let t2 = Date()
            logger?.debug("Time to parse wall label \(t2.timeIntervalSince(t1)) seconds")
        }
        
        let prompt =  text
        
        let session = ChatSession(self.model)
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

}

