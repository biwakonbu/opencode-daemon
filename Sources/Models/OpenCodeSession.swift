import Foundation

struct OpenCodeSession: Codable, Identifiable {
    let id: String
    let slug: String
    let version: String
    let projectID: String
    let directory: String
    let title: String
    let created: Int64
    var updated: Int64

    var isActive: Bool = true

    struct SessionTime: Codable {
        let created: Int64
        let updated: Int64
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case slug
        case version
        case projectID
        case directory
        case title
        case time
        case created
        case updated
    }

    var createdAt: Date {
        return dateFromEpoch(created)
    }

    var updatedAt: Date {
        return dateFromEpoch(updated)
    }

    init(
        id: String = UUID().uuidString, slug: String = "", version: String = "", projectID: String = "", directory: String = "",
        title: String = "", created: Int64 = 0, updated: Int64 = 0, isActive: Bool = true
    ) {
        self.id = id
        self.slug = slug
        self.version = version
        self.projectID = projectID
        self.directory = directory
        self.title = title
        self.created = created
        self.updated = updated
        self.isActive = isActive
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        slug = (try? container.decode(String.self, forKey: .slug)) ?? ""
        version = (try? container.decode(String.self, forKey: .version)) ?? ""
        projectID = (try? container.decode(String.self, forKey: .projectID)) ?? ""
        directory = (try? container.decode(String.self, forKey: .directory)) ?? ""
        title = (try? container.decode(String.self, forKey: .title)) ?? ""

        if let time = try? container.decode(SessionTime.self, forKey: .time) {
            created = time.created
            updated = time.updated
        } else {
            let createdValue = Self.decodeEpoch(from: container, forKey: .created) ?? 0
            let updatedValue = Self.decodeEpoch(from: container, forKey: .updated) ?? createdValue
            created = createdValue
            updated = updatedValue
        }

        isActive = true
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(slug, forKey: .slug)
        try container.encode(version, forKey: .version)
        try container.encode(projectID, forKey: .projectID)
        try container.encode(directory, forKey: .directory)
        try container.encode(title, forKey: .title)
        try container.encode(SessionTime(created: created, updated: updated), forKey: .time)
    }

    mutating func update() {
        updated = Int64(Date().timeIntervalSince1970 * 1000.0)
        isActive = true
    }

    private func dateFromEpoch(_ value: Int64) -> Date {
        let seconds: TimeInterval
        if value > 10_000_000_000 {
            seconds = TimeInterval(value) / 1000.0
        } else {
            seconds = TimeInterval(value)
        }
        return Date(timeIntervalSince1970: seconds)
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
}
