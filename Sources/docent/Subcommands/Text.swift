import Foundation

public enum TextErrors: Error {
    case missingInput
    case isDirectory
    case dataConversion
    
    public var errorDescription: String? {
        switch self {
        case .missingInput:
            return "No text to work with."
        case .isDirectory:
            return "Path to file is a directory."
        case .dataConversion:
            return "Failed to convert text (String) to Data."
        }
    }
}

public func TextFromArgsAsData(args: [String]) throws -> Data {
    
    var body: String
    
    do {
        body = try TextFromArgs(args: args)
    } catch {
        throw error
    }
    
    guard let data = body.data(using: .utf8) else {
        throw TextErrors.dataConversion
    }
    
    return data
}

public func TextFromArgs(args: [String]) throws -> String {
    
    var body: String = ""
    
    switch args.count {
    case 0:
        throw TextErrors.missingInput
    case 1:
        
        switch args[0] {
        case "-":
            
            let data = FileHandle.standardInput.readDataToEndOfFile()
            body = String(data: data, encoding: .utf8) ?? ""
            
        default:
            
            var isDir: ObjCBool = false
            let exists = FileManager.default.fileExists(atPath: args[0], isDirectory: &isDir)
            
            if !exists {
                body = args[0]
            } else {
                                    
                if isDir.boolValue {
                    throw TextErrors.isDirectory
                }
                
                do {
                    body = try String(contentsOfFile: args[0], encoding: .utf8)
                } catch {
                    throw error
                }
            }

        }
        
    default:
        body = args.joined(separator: " ")
    }
            
    guard body != "" else {
        throw TextErrors.missingInput
    }
        
    
    return body
}
