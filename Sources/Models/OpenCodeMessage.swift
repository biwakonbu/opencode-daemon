import Foundation

struct OpenCodeMessage: Codable, Identifiable {
    let id: String
    let sessionId: String
    let content: String
    let role: String
    let timestamp: Date

    init(id: String = UUID().uuidString, sessionId: String, content: String, role: String, timestamp: Date = Date()) {
        self.id = id
        self.sessionId = sessionId
        self.content = content
        self.role = role
        self.timestamp = timestamp
    }
}

struct OpenCodeModel: Codable {
    let providerID: String
    let modelID: String
}

struct OpenCodeMessagePart: Codable {
    let type: String
    let text: String?
    let mime: String?
    let filename: String?
    let url: String?

    static func text(_ value: String) -> OpenCodeMessagePart {
        OpenCodeMessagePart(type: "text", text: value, mime: nil, filename: nil, url: nil)
    }

    static func file(url: String, mime: String, filename: String? = nil) -> OpenCodeMessagePart {
        OpenCodeMessagePart(type: "file", text: nil, mime: mime, filename: filename, url: url)
    }
}

struct SendMessageRequest {
    let sessionId: String
    let parts: [OpenCodeMessagePart]
    let model: OpenCodeModel?
}

struct SendMessageResponse: Decodable {
    let id: String
    let content: String
    let role: String
    let timestamp: Date

    private enum CodingKeys: String, CodingKey {
        case id
        case role
        case timestamp
        case time
        case created
        case updated
        case content
        case parts
        case info
    }

    private enum InfoKeys: String, CodingKey {
        case id
        case role
        case time
    }

    private enum TimeKeys: String, CodingKey {
        case created
        case completed
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let info = try? container.nestedContainer(keyedBy: InfoKeys.self, forKey: .info) {
            id = (try? info.decode(String.self, forKey: .id)) ?? UUID().uuidString
            role = (try? info.decode(String.self, forKey: .role)) ?? "assistant"
            timestamp = Self.decodeDate(from: info)
        } else {
            id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
            role = (try? container.decode(String.self, forKey: .role)) ?? "assistant"
            timestamp = Self.decodeDate(from: container)
        }

        let parts = (try? container.decode([OpenCodeMessagePart].self, forKey: .parts)) ?? []
        let text = Self.combineText(from: parts)
        if !text.isEmpty {
            content = text
        } else if let contentValue = try? container.decode(String.self, forKey: .content) {
            content = contentValue
        } else {
            content = ""
        }
    }

    private static func combineText(from parts: [OpenCodeMessagePart]) -> String {
        let texts = parts.compactMap { part in
            part.type == "text" ? part.text : nil
        }
        return texts.joined(separator: "\n")
    }

    private static func decodeDate(from container: KeyedDecodingContainer<CodingKeys>) -> Date {
        if let date = try? container.decode(Date.self, forKey: .timestamp) {
            return date
        }
        if let time = try? container.nestedContainer(keyedBy: TimeKeys.self, forKey: .time),
            let created = decodeEpoch(from: time, forKey: .created)
        {
            return dateFromEpoch(created)
        }
        if let created = decodeEpoch(from: container, forKey: .created) {
            return dateFromEpoch(created)
        }
        if let updated = decodeEpoch(from: container, forKey: .updated) {
            return dateFromEpoch(updated)
        }
        return Date()
    }

    private static func decodeDate(from container: KeyedDecodingContainer<InfoKeys>) -> Date {
        if let time = try? container.nestedContainer(keyedBy: TimeKeys.self, forKey: .time),
            let created = decodeEpoch(from: time, forKey: .created)
        {
            return dateFromEpoch(created)
        }
        return Date()
    }

    private static func decodeEpoch(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> Int64? {
        if let value = try? container.decode(Int64.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Double.self, forKey: key) {
            return Int64(value)
        }
        if let value = try? container.decode(String.self, forKey: key) {
            return Int64(value)
        }
        return nil
    }

    private static func decodeEpoch(from container: KeyedDecodingContainer<TimeKeys>, forKey key: TimeKeys) -> Int64? {
        if let value = try? container.decode(Int64.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Double.self, forKey: key) {
            return Int64(value)
        }
        if let value = try? container.decode(String.self, forKey: key) {
            return Int64(value)
        }
        return nil
    }

    private static func dateFromEpoch(_ value: Int64) -> Date {
        let seconds: TimeInterval
        if value > 10_000_000_000 {
            seconds = TimeInterval(value) / 1000.0
        } else {
            seconds = TimeInterval(value)
        }
        return Date(timeIntervalSince1970: seconds)
    }
}
