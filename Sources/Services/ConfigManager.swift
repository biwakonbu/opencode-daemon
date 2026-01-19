import Foundation

class ConfigManager {
    private let configPath: String
    private let legacyConfigPath: String
    private let openCodeAuthPath: String
    
    init() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let projectDir = homeDir.appendingPathComponent("github/chrome-to-opencode")
        self.configPath = projectDir.appendingPathComponent(".config.json").path
        self.legacyConfigPath = projectDir.appendingPathComponent(".opencodemenu.json").path
        self.openCodeAuthPath = homeDir.appendingPathComponent(".local/share/opencode/auth.json").path
    }
    
    private struct OpenCodeAuth: Codable {
        let type: String
        let key: String
    }
    
    private func loadOpenCodeAuthKey() -> String? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: openCodeAuthPath)) else {
            return nil
        }
        
        guard let authDict = try? JSONSerialization.jsonObject(with: data) as? [String: [String: String]] else {
            return nil
        }
        
        for (_, authData) in authDict {
            if let key = authData["key"] {
                return key
            }
        }
        
        return nil
    }
    
    func loadConfig() throws -> Config {
        let url = resolveConfigURL()
        let data = try Data(contentsOf: url)
        var config = try JSONDecoder().decode(Config.self, from: data)
        
        if config.apiKey == "your-api-key-here" || config.apiKey.isEmpty {
            if let openCodeKey = loadOpenCodeAuthKey() {
                config.apiKey = openCodeKey
            }
        }
        
        return config
    }
    
    func saveConfig(_ config: Config) throws {
        let url = URL(fileURLWithPath: configPath)
        let data = try JSONEncoder().encode(config)
        try data.write(to: url)
    }
    
    func getConfigPath() -> String {
        return configPath
    }
    
    private func resolveConfigURL() -> URL {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: configPath) {
            return URL(fileURLWithPath: configPath)
        }
        if fileManager.fileExists(atPath: legacyConfigPath) {
            return URL(fileURLWithPath: legacyConfigPath)
        }
        return URL(fileURLWithPath: configPath)
    }
}
