import Cocoa
import SwiftUI

class MenuBarManager {
    private var statusItem: NSStatusItem?
    private let viewModel: OpenCodeViewModel
    private let logStore: RuntimeLogStore
    private let configResult: ConfigLoadResult
    private let resolvedEndpoint: String
    private let appLaunchDate: Date
    private let checkAccessibilityPermission: () -> Bool
    private var statusWindow: AppStatusWindow?

    init(
        viewModel: OpenCodeViewModel,
        configResult: ConfigLoadResult,
        resolvedEndpoint: String,
        appLaunchDate: Date,
        checkAccessibilityPermission: @escaping () -> Bool
    ) {
        self.viewModel = viewModel
        self.logStore = .shared
        self.configResult = configResult
        self.resolvedEndpoint = resolvedEndpoint
        self.appLaunchDate = appLaunchDate
        self.checkAccessibilityPermission = checkAccessibilityPermission
    }

    func setup() {
        logStore.log("MenuBarManager setup開始", category: "MenuBar")
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "macwindow", accessibilityDescription: "OpenCode")
        }

        statusItem?.button?.action = #selector(statusBarButtonClicked)
        statusItem?.button?.target = self

        createMenu()

        logStore.log("MenuBarManager setup完了", category: "MenuBar")
    }

    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        logStore.log("メニューバーボタンクリック検出", category: "MenuBar")

        if let menu = statusItem?.menu, let button = statusItem?.button {
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height), in: button)
        }
    }

    private func createMenu() {
        let menu = NSMenu()

        let showChatItem = menu.addItem(withTitle: "チャットウィンドウを表示", action: #selector(showChatWindow), keyEquivalent: "o")
        showChatItem.target = self

        let showInputItem = menu.addItem(withTitle: "入力ランチャーを表示", action: #selector(showInputLauncher), keyEquivalent: "i")
        showInputItem.target = self

        let showStatusItem = menu.addItem(withTitle: "設定と状態を表示", action: #selector(showStatusWindow), keyEquivalent: "")
        showStatusItem.target = self

        menu.addItem(NSMenuItem.separator())

        let restartItem = menu.addItem(withTitle: "再起動", action: #selector(restartApp), keyEquivalent: "")
        restartItem.target = self

        menu.addItem(NSMenuItem.separator())

        let quitItem = menu.addItem(withTitle: "終了", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self

        statusItem?.menu = menu
    }

    @objc private func showChatWindow() {
        logStore.log("チャットウィンドウ表示メニュー選択", category: "MenuBar")
        Task { @MainActor in
            WindowStateManager.shared.showChatWindow()
        }
    }

    @objc private func showInputLauncher() {
        logStore.log("入力ランチャー表示メニュー選択", category: "MenuBar")
        Task { @MainActor in
            WindowStateManager.shared.showInputLauncher()
        }
    }

    @objc private func showStatusWindow() {
        logStore.log("設定と状態表示メニュー選択", category: "MenuBar")
        Task { @MainActor in
            if statusWindow == nil {
                statusWindow = AppStatusWindow(
                    viewModel: viewModel,
                    windowManager: WindowStateManager.shared,
                    logStore: logStore,
                    configResult: configResult,
                    resolvedEndpoint: resolvedEndpoint,
                    launchDate: appLaunchDate,
                    checkAccessibilityPermission: checkAccessibilityPermission
                )
            }
            statusWindow?.show()
        }
    }

    @objc private func restartApp() {
        logStore.log("再起動メニュー選択", category: "MenuBar")
        Task { @MainActor in
            WindowStateManager.shared.restartApp()
        }
    }

    @objc private func quitApp() {
        logStore.log("終了メニュー選択", category: "MenuBar")
        NSApplication.shared.terminate(nil)
    }
}
