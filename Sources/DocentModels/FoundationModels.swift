import FoundationModels
import Logging

enum FoundationModelErrors: Error {
    case foundationModelsUnavailable
    
    public var errorDescription: String? {
        switch self {
        case .foundationModelsUnavailable:
            return "FoundationModels are unavailable"
        }
    }
}
 
@available(iOS 26.0, macOS 26.0, *)
public func loadFoundationModels(_ logger: Logger? = nil) throws -> Void {
    
    var models_ok = false
    
    switch SystemLanguageModel.default.availability {
    case .available:
        models_ok = true
    case .unavailable(.appleIntelligenceNotEnabled):
        logger?.error("AppleIntelligence not enabled")
    case .unavailable(.deviceNotEligible):
        logger?.error("Device not eligible for AppleIntelligence")
    case .unavailable(.modelNotReady):
        logger?.error("FoundationModel not ready")
    case .unavailable(let other):
        logger?.error("Uknown error loading FoundationModels, \(other)")
    }
    
    if !models_ok {
        throw FoundationModelErrors.foundationModelsUnavailable
    }
}

