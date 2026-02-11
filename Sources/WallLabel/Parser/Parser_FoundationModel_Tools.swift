import FoundationModels
import Foundation
import AccessionNumbers

@available(macOS 26.0, *)
struct AccessionNumbers: Tool {
    let name = "findAccessionNumbers"
    let description = "Find accession numbers in a text"
    
    @Generable
    struct Arguments {
        @Guide(description: "The text to parse for accession numbers.")
        let text: String
    }
    
    func call(arguments: Arguments) async throws -> [String] {
        
        var results: [String]  = []
        
        // Load defs from resources here...
        // let decoder = JSONDecoder()
        // def = try decoder.decode(Definition.self, from: data)
        
        var candidates  = [Definition]()
        
        let rsp = ExtractFromText(text: arguments.text, definitions: candidates)
                
        switch rsp {
        case .failure(let error):
            throw error
        case .success(let matches):
            
            for m in matches {
                results.append("\(m.accession_number) (\(m.organization))")
            }
        }
        
        return results
    }
}
