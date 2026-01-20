import Combine
import Foundation

enum RuntimeLogLevel: String, Codable {
    case info = "INFO"
    case warning = "WARN"
    case error = "ERROR"
}

struct RuntimeLogEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let level: RuntimeLogLevel
    let category: String
    let message: String

    init(id: UUID = UUID(), timestamp: Date = Date(), level: RuntimeLogLevel, category: String, message: String) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.category = category
        self.message = message
    }

    var formattedTimestamp: String {
        RuntimeLogEntry.dateFormatter.string(from: timestamp)
    }

    var formattedLine: String {
        "\(formattedTimestamp) [\(level.rawValue)] [\(category)] \(message)"
    }

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}

final class RuntimeLogStore: ObservableObject {
    static let shared = RuntimeLogStore()

    @Published private(set) var entries: [RuntimeLogEntry] = []

    private let queue = DispatchQueue(label: "RuntimeLogStore")
    private let fileURL: URL
    private let maxEntries = 500

    private init() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let projectDir = homeDir.appendingPathComponent("github/chrome-to-opencode")
        self.fileURL = projectDir.appendingPathComponent("opencode_app.log")
        loadExistingLogs()
    }

    func log(_ message: String, level: RuntimeLogLevel = .info, category: String = "App") {
        let entry = RuntimeLogEntry(level: level, category: category, message: message)
        let line = entry.formattedLine

        queue.async {
            self.appendLine(line)
        }

        DispatchQueue.main.async {
            self.entries.append(entry)
            if self.entries.count > self.maxEntries {
                self.entries.removeFirst(self.entries.count - self.maxEntries)
            }
        }
    }

    func clear() {
        queue.async {
            try? "".write(to: self.fileURL, atomically: true, encoding: .utf8)
        }
        DispatchQueue.main.async {
            self.entries = []
        }
    }

    func logFilePath() -> String {
        fileURL.path
    }

    private func appendLine(_ line: String) {
        let data = (line + "\n").data(using: .utf8) ?? Data()
        if FileManager.default.fileExists(atPath: fileURL.path) {
            if let handle = try? FileHandle(forWritingTo: fileURL) {
                defer { try? handle.close() }
                handle.seekToEndOfFile()
                handle.write(data)
            }
        } else {
            try? data.write(to: fileURL)
        }
    }

    private func loadExistingLogs() {
        guard let data = try? Data(contentsOf: fileURL),
            let text = String(data: data, encoding: .utf8)
        else {
            return
        }

        let lines = text.split(separator: "\n").map(String.init)
        let entries = lines.suffix(maxEntries).map { parseLine($0) }
        DispatchQueue.main.async {
            self.entries = entries
        }
    }

    private func parseLine(_ line: String) -> RuntimeLogEntry {
        if let match = RuntimeLogStore.lineRegex.firstMatch(in: line, range: NSRange(location: 0, length: line.utf16.count)) {
            let timestamp = extractGroup(line, match: match, index: 1)
            let level = extractGroup(line, match: match, index: 2)
            let category = extractGroup(line, match: match, index: 3)
            let message = extractGroup(line, match: match, index: 4)

            let date = RuntimeLogEntry.dateFormatter.date(from: timestamp) ?? Date()
            let levelValue = RuntimeLogLevel(rawValue: level) ?? .info
            return RuntimeLogEntry(timestamp: date, level: levelValue, category: category, message: message)
        }

        return RuntimeLogEntry(level: .info, category: "Log", message: line)
    }

    private func extractGroup(_ line: String, match: NSTextCheckingResult, index: Int) -> String {
        guard let range = Range(match.range(at: index), in: line) else {
            return ""
        }
        return String(line[range])
    }

    private static let lineRegex = try! NSRegularExpression(
        pattern: #"^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}) \[([A-Z]+)\] \[([^\]]+)\] (.*)$"#,
        options: []
    )
}
