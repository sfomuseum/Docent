import FoundationModels
import Foundation

import Logging

@available(iOS 26.0, macOS 26.0, *)
struct FoundationModelParser: Parser {
    
    var instructions: String
    var model_name: String
    var logger: Logger?
    
    init(_ parser_uri: String, instructions: String, logger: Logger?) throws {
        
        let proc = ProcessInfo()
        self.model_name = String(format:"apple/foundationmodels#%@", proc.operatingSystemVersionString)
        
        self.instructions = default_label_parser_instructions
        self.logger = logger
    }
    
    func parse(text: String) async -> Result<WallLabel, any Error> {
        
        let t1 = Date()
        
        defer {
            let t2 = Date()
            logger?.debug("Time to parse wall label \(t2.timeIntervalSince(t1)) seconds")
        }
        
        var label = WallLabelGenerable(text)
        label.timestamp = Int(NSDate().timeIntervalSince1970)
        label.latitude = 0.0
        label.longitude = 0.0
        
            do {

                let session = LanguageModelSession(instructions: self.instructions)
                
                let response = try await session.respond(
                    to: text,
                    generating: WallLabelGenerable.self
                )
                
                label.title = response.content.title
                label.date = response.content.date
                label.creator = response.content.creator
                label.location = response.content.location
                label.accession_number = response.content.accession_number
                label.medium = response.content.medium
                label.creditline = response.content.creditline
                                
                return .success(label)

            } catch {
                logger?.error("Failed to parse label text, \(error)")
                return .failure(error)
            }

    }
    
    public func model() -> String {
        return model_name
    }
    
}
