
import Foundation

// Early pass at something which can mimic the aaronland/gocloud/runtimevar functionality.
// So far only file:// and constant:// URI schemes are supported.

public enum RuntimeVarErrors: Error {
    case invalidURI
    case invalidScheme
    case missingParameter
    case notExists
    case isDirectory
    
    public var errorDescription: String? {
        switch self {
        case .invalidURI:
            return "Invalid or unsupported scheme"
        case .invalidScheme:
            return "Invalid or unsupported model"
        case .missingParameter:
            return "Missing or empty parameter"
        case .notExists:
            return "Path is missing"
        case .isDirectory:
            return "Path references a directory"
        }
    }
}

public func StringVar(_ uri: String) -> Result<String, Error> {
    
    guard let u = URL(string: uri) else {
        return .failure(RuntimeVarErrors.invalidURI)
    }
    
    guard let components = URLComponents(url: u, resolvingAgainstBaseURL: false) else {
        return .failure(RuntimeVarErrors.invalidURI)
    }
    
    switch u.scheme {
    case "file":
        
        let path = u.path()
        
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
        
        if !exists {
            return .failure(RuntimeVarErrors.notExists)
        }
        
        if isDir.boolValue {
            return .failure(RuntimeVarErrors.isDirectory)
        }
        
        do {
            let body = try String(contentsOfFile: path, encoding: .utf8)
            return .success(body)
        } catch {
            return .failure(error)
        }
        
    case "constant":
        
        guard let val = components.queryItems?.first(where: { $0.name == "val" })?.value else {
            return .failure(RuntimeVarErrors.missingParameter)
        }
        
        return .success(val)
        
    default:
        return .failure(RuntimeVarErrors.invalidScheme)
    }
    
    
}
