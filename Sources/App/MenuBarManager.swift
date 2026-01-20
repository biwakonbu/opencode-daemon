import Cocoa
import SwiftUI

class MenuBarManager {
    private var statusItem: NSStatusItem?
    private let viewModel: OpenCodeViewModel
    
    init(viewModel: OpenCodeViewModel) {
        self.viewModel = viewModel
    }
    
    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "macwindow", accessibilityDescription: "OpenCode")
        }
        
        statusItem?.button?.action = #selector(statusBarButtonClicked)
        statusItem?.button?.target = self
    }
    
    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
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
        WindowStateManager.shared.showChatWindow()
    }
    
    @objc private func showInputLauncher() {
        WindowStateManager.shared.showInputLauncher()
    }
    
    @objc private func restartApp() {
        WindowStateManager.shared.restartApp()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
