import Cocoa
import SwiftUI
import os.log

public class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarManager: MenuBarManager?
    private var configManager: ConfigManager?
    private var apiClient: OpenCodeAPIClient?
    private var screenshotCapture: ScreenshotCapture?
    private var viewModel: OpenCodeViewModel?
    private var globalShortcutMonitor: GlobalShortcutMonitor?
    private var mcpImageAnalyzer: MCPImageAnalyzer?
    private var notificationCenter: NotificationCenterService?
    private let logStore = RuntimeLogStore.shared
    private let logger = OSLog(subsystem: "com.opencodemenu.app", category: "AppDelegate")

    @MainActor
    public func applicationDidFinishLaunching(_ notification: Notification) {
        Task {
            await setupApp()
        }
    }

    @MainActor
    private func setupApp() async {
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

            WindowStateManager.shared.setup(viewModel: viewModel)

            let menuBarManager = MenuBarManager(viewModel: viewModel)
            self.menuBarManager = menuBarManager
            menuBarManager.setup()

            let notificationCenter = NotificationCenterService()
            self.notificationCenter = notificationCenter
            notificationCenter.requestNotificationAuthorization()

            let globalShortcutMonitor = GlobalShortcutMonitor(logStore: logStore)
            globalShortcutMonitor.delegate = self
            self.globalShortcutMonitor = globalShortcutMonitor

            if !globalShortcutMonitor.checkAccessibilityPermissions() {
                showAlert(
                    title: "アクセシビリティ権限が必要",
                    message: "スクリーンショット機能を使用するには、システム環境設定 > プライバシーとセキュリティ > アクセシビリティ でこのアプリを許可してください"
                )
            }

            globalShortcutMonitor.startMonitoring()

            let mcpImageAnalyzer = MCPImageAnalyzer(
                apiClient: apiClient,
                viewModel: viewModel,
                notificationCenter: notificationCenter,
                logStore: logStore
            )
            self.mcpImageAnalyzer = mcpImageAnalyzer

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

extension AppDelegate: GlobalShortcutDelegate {
    func didToggleChatWindow() {
        logStore.log("チャットウィンドウ切り替えコールバック受信 (AppState)", category: "Shortcut")
        logStore.log("現在のスレッド: \(Thread.isMainThread)", category: "Shortcut")
        Task { @MainActor in
            WindowStateManager.shared.toggleChatWindow()
        }
    }

    func didShowInputLauncher() {
        logStore.log("入力ランチャー表示コールバック受信 (AppState)", category: "Shortcut")
        logStore.log("現在のスレッド: \(Thread.isMainThread)", category: "Shortcut")
        Task { @MainActor in
            WindowStateManager.shared.showInputLauncher()
        }
    }

    func didCaptureRect(_ rect: CGRect) {
        Task { @MainActor in
            await handleRectCapture(rect)
        }
    }

    @MainActor
    private func handleRectCapture(_ rect: CGRect) async {
        logStore.log("矩形キャプチャ検出: \(rect)", category: "Capture")

        guard let mainScreen = NSScreen.main else {
            logStore.log("メインスクリーンが見つかりません", level: .error, category: "Capture")
            notificationCenter?.sendErrorNotification(title: "エラー", message: "メインスクリーンが見つかりません")
            return
        }

        do {
            let rectCapture = ScreenshotRectCapture()
            let imageData = try rectCapture.captureRectAsData(rect, from: mainScreen)
            logStore.log("キャプチャ成功: \(imageData.count) bytes", category: "Capture")
            viewModel?.setPendingImageData(imageData)
            WindowStateManager.shared.showInputLauncher()
        } catch {
            logStore.log("キャプチャ失敗: \(error.localizedDescription)", level: .error, category: "Capture")
            notificationCenter?.sendErrorNotification(title: "エラー", message: "スクリーンショットの取得に失敗しました")
        }
    }
}
// test
