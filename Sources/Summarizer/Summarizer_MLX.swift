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
    var model: LMModel
    
    public init(_ Summarizer_uri: String, logger: Logger?) throws {
        
        guard let u = URL(string: Summarizer_uri) else {
            throw SummarizerErrors.invalidURI
        }
        
        guard let components = URLComponents(url: u, resolvingAgainstBaseURL: false) else {
            throw SummarizerErrors.invalidURI
        }
        
        guard let model_name = components.queryItems?.first(where: { $0.name == "model" })?.value else {
            throw MLXSummarizerErrors.missingModel
        }
        var model: LMModel?
        
        for m in MLXService.availableModels {
            
            if m.name == model_name {
                model = m
                break
            }
        }
        
        if model == nil {
            throw MLXSummarizerErrors.unknownModel
        }
        
        self.logger = logger
        self.model = model!
    }
    
    public func summarize(text: String, maxLength: Int) async -> Result<String, any Error> {
        
        let mlxService = MLXService()
        //let selectedModel: LMModel = MLXService.availableModels.first!
        
        let prompt: String = "Analyze this text and generate a summary that is not longer than \(maxLength) characters. Focus on retaining the meaning of the text rather than the exact text itself. Be consistent not uniform. The text to summary is: " + text
        var result: String = ""
        
        var messages: [Message] = [
            .system("Your goal is to analyze texts and summarize them in to new texts no longer than \(maxLength) characters. Focus on retaining the meaning of the text rather than the exact text itself. Be consistent not uniform.")
        ]
        
        messages.append(.user(prompt))
        messages.append(.assistant(""))
        
        do {
            for await generation in try await mlxService.generate(
                messages: messages, model: self.model, logger: self.logger)
            {
                switch generation {
                case .chunk(let chunk):
                    result += chunk
                case .info(let info):
                    self.logger?.debug("INFO \(info)")
                case .toolCall(_):
                    // print("TOOL \(call)")
                    break
                }
            }
        } catch {
            return .failure(error)
        }
        
        self.logger?.debug("DONE \(result)")
        
        return .success(result)
    }

}

