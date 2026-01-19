import Foundation

struct Config: Codable {
    var apiKey: String
    var apiEndpoint: String
    var sessionTimeout: Int
    var defaultModelProvider: String?
    var defaultModelID: String?
    
    enum CodingKeys: String, CodingKey {
        case apiKey
        case apiEndpoint
        case sessionTimeout
        case defaultModelProvider
        case defaultModelID
    }
}
