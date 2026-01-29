import Foundation

/// WallLabelNotGenerable  is a struct describing structured wall label data and geolocation data for an image of an object.
public struct WallLabelNotGenerable: WallLabel, Codable {
    /// The title of the object
    var title: String?
    
    /// The date attributed to an object, typically when that object was created
    var date: String?
    
    /// The individual or organization responsible for creating an object.
    var creator: String?
    
    /// The name of an individual, persons or organization who donated or are lending an object.
    var creditline: String?
    
    /// The location that an object was produced in.
    var location: String?
    
    /// The medium or media used to create the object.
    var medium: String?
    
    /// The unique identifier for an object.
    var accession_number: String?
    
    /// The Unix timestamp when a photo of an object was captured.
    var timestamp: Int?
    
    /// The latitude location coordinate of the camera capturing a photo of an object.
    var latitude: Float64?
    
    /// The longitude location coordinate of the camera capturing a photo of an object.
    var longitude: Float64?
    
    /// The raw text of a wall label that was parsed in to a WallLabel struct
    var input: String?
    
    init(_ raw: String) {
        input = raw
    }
    
    /// Function to update (or not) a given property
    public mutating func setProperty(key: String, value: Any) -> Bool {
        
        switch(key) {
        case "title":
            self.title = "\(value)"
        case "date":
            self.date = "\(value)"
        case "creator":
            self.creator = "\(value)"
        case "medium":
            self.medium = "\(value)"
        case "location":
            self.location = "\(value)"
        case "creditline":
            self.creditline = "\(value)"
        case "accession_number":
            self.accession_number = "\(value)"
            /*
             case "latitude":
             self.latitude = value as? Float64
             case "longitude":
             self.longitude = value as? Float64
             case "created":
             self.timestamp = value as? Int
             */
        default:
            return false
        }
        
        return true
        
    }
    
    /// Encode the WallLabel instance as JSON.
    public func marshalJSON() -> Result<Data, Error> {
        
        let encoder = JSONEncoder()
        // encoder.outputFormatting = .prettyPrinted
        
        do {
            let enc = try encoder.encode(self)
            return .success(enc)
        } catch {
            return .failure(error)
        }
    }
}
