import Logging
import Foundation
import MLXLMCommon
import Hub

enum MLXDocentError: Error, LocalizedError {
    case invalidURI
    case missingModel
    case invalidDownloadLocation
    
    public var errorDescription: String? {
        switch self {
        case .invalidURI:
            return "Invalid URI (failed to parse)"
        case .missingModel:
            return "Missing ?model= parameter"
        case .invalidDownloadLocation:
            return "Invalid download location"
        }
    }
}

public struct MLXModel {
    public let context: ModelContext
    public let name: String
}

public func loadMLXModel(_ uri: String, logger: Logger? = nil) async -> Result<MLXModel, Error> {
    
    guard let u = URL(string: uri) else {
        return .failure(MLXDocentError.invalidURI)
    }
    
    guard let components = URLComponents(url: u, resolvingAgainstBaseURL: false) else {
        return .failure(MLXDocentError.invalidURI)
    }
    
    guard let model_name = components.queryItems?.first(where: { $0.name == "model" })?.value else {
        return .failure(MLXDocentError.missingModel)
    }
    
    logger?.debug("Load model \(model_name)")
    
    var hub = defaultHubApi

    if let downloads = components.queryItems?.first(where: { $0.name == "downloads" })?.value {
        
        guard let downloads_url = URL(string: downloads) else {
            return .failure(MLXDocentError.invalidDownloadLocation)
        }
        
        logger?.debug("Use custom downloads location \(downloads_url.absoluteString)")
        hub = HubApi(downloadBase: downloads_url)
    }
    
    var model_context: ModelContext?
    let model_logger = logger
    
    do {
        model_context = try await loadModel(hub: hub, id: model_name, progressHandler: { status in
            model_logger?.debug("Loading \(model_name) \(status.fractionCompleted * 100)% complete")
        })
    } catch {
        logger?.error("Failed to load model \(model_name), \(error)")
        return .failure(error)
    }
    
    let rsp = MLXModel(context: model_context!, name: model_name)
    return .success(rsp)
}
