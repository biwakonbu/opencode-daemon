import Cocoa
import SwiftUI
import os.log

public class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBar: StatusBar?
    private var configManager: ConfigManager?
    private var apiClient: OpenCodeAPIClient?
    private var screenshotCapture: ScreenshotCapture?
    private var viewModel: OpenCodeViewModel?
    private let logStore = RuntimeLogStore.shared
    private let logger = OSLog(subsystem: "com.opencodemenu.app", category: "AppDelegate")
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        setupApp()
    }
    
    @MainActor
    private func setupApp() {
        logStore.log("アプリケーション初期化を開始", category: "App")
        do {
            let configManager = ConfigManager()
            self.configManager = configManager
            
            let config = try configManager.loadConfig()
            os_log("API Endpoint: %@", log: logger, type: .info, config.apiEndpoint)
            os_log("API Key: %@", log: logger, type: .info, config.apiKey.isEmpty ? "未設定" : "設定済")
            logStore.log("API Endpoint: \(config.apiEndpoint)", category: "Config")
            logStore.log("API Key: \(config.apiKey.isEmpty ? "未設定" : "設定済")", category: "Config")
            
            let apiClient = OpenCodeAPIClient(logStore: logStore)
            apiClient.setConfig(config)
            self.apiClient = apiClient
            
            let screenshotCapture = ScreenshotCapture()
            self.screenshotCapture = screenshotCapture
            
            let viewModel = OpenCodeViewModel(
                apiClient: apiClient,
                screenshotCapture: screenshotCapture,
                logStore: logStore
            )
            self.viewModel = viewModel
            
            statusBar = StatusBar(viewModel: viewModel)
            statusBar?.setup()
            logStore.log("アプリケーション初期化完了", category: "App")
            
        } catch {
            os_log("エラー: %@", log: logger, type: .error, error.localizedDescription)
            logStore.log("初期化エラー: \(error.localizedDescription)", level: .error, category: "App")
            showAlert(title: "エラー", message: "アプリケーションの初期化に失敗しました: \(error.localizedDescription)")
            NSApplication.shared.terminate(self)
        }
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
