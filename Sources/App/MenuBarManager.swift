import Cocoa
import SwiftUI

class MenuBarManager {
    private var statusItem: NSStatusItem?
    private let viewModel: OpenCodeViewModel
    private let logStore: RuntimeLogStore
    
    init(viewModel: OpenCodeViewModel) {
        self.viewModel = viewModel
        self.logStore = .shared
    }
    
    func setup() {
        logStore.log("MenuBarManager setup開始", category: "MenuBar")
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "macwindow", accessibilityDescription: "OpenCode")
        }
        
        statusItem?.button?.action = #selector(statusBarButtonClicked)
        statusItem?.button?.target = self
        logStore.log("MenuBarManager setup完了", category: "MenuBar")
    }
    
    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        logStore.log("メニューバーボタンクリック検出", category: "MenuBar")
        showContextMenu()
    }
    
    private func showContextMenu() {
        let menu = NSMenu()
        
        let showChatItem = menu.addItem(withTitle: "チャットウィンドウを表示", action: #selector(showChatWindow), keyEquivalent: "o")
        showChatItem.target = self
        
        let showInputItem = menu.addItem(withTitle: "入力ランチャーを表示", action: #selector(showInputLauncher), keyEquivalent: "i")
        showInputItem.target = self
        
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
        WindowStateManager.shared.showChatWindow()
    }
    
    @objc private func showInputLauncher() {
        logStore.log("入力ランチャー表示メニュー選択", category: "MenuBar")
        WindowStateManager.shared.showInputLauncher()
    }
    
    @objc private func restartApp() {
        logStore.log("再起動メニュー選択", category: "MenuBar")
        WindowStateManager.shared.restartApp()
    }
    
    @objc private func quitApp() {
        logStore.log("終了メニュー選択", category: "MenuBar")
        NSApplication.shared.terminate(nil)
    }
}
