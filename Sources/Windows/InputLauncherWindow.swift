import Cocoa
import SwiftUI

class InputLauncherWindow: NSWindow {
    private let viewModel: OpenCodeViewModel
    
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    
    init(viewModel: OpenCodeViewModel) {
        self.viewModel = viewModel
        
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 320),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        setupWindow()
    }
    
    private func setupWindow() {
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        let inputLauncherView = InputLauncherView(
            viewModel: viewModel,
            onSendMessage: { [weak self] in
                Task { @MainActor in
                    await self?.handleSendMessage()
                }
            },
            onCancel: { [weak self] in
                self?.viewModel.logStore.log("入力ランチャー: キャンセルボタン押下", category: "InputLauncherWindow")
                self?.hide()
            }
        )
        
        let hostingView = NSHostingView(rootView: inputLauncherView)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = .clear
        
        contentView = hostingView
    }
    
    private func handleSendMessage() async {
        let trimmedMessage = viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard viewModel.pendingImageData != nil || !trimmedMessage.isEmpty else { return }
        viewModel.logStore.log("入力ランチャー: 送信処理開始", category: "InputLauncherWindow")
        await viewModel.sendLauncherPrompt()
        if viewModel.errorMessage == nil {
            hide()
        }
    }
    
    func show() {
        viewModel.logStore.log("InputLauncherWindow表示開始", category: "InputLauncherWindow")
        
        NSApp.activate(ignoringOtherApps: true)
        centerOnScreen()
        makeKeyAndOrderFront(nil)
        NotificationCenter.default.post(name: .inputLauncherFocusRequested, object: self)
        
        viewModel.logStore.log("InputLauncherWindow表示完了", category: "InputLauncherWindow")
    }
    
    func hide() {
        viewModel.logStore.log("InputLauncherWindow非表示開始, 現在の可視状態: \(isVisible)", category: "InputLauncherWindow")
        orderOut(nil)
        viewModel.logStore.log("InputLauncherWindow非表示完了", category: "InputLauncherWindow")
    }
    
    private func centerOnScreen() {
        guard let screen = NSScreen.main else {
            viewModel.logStore.log("メインスクリーンが見つかりません", level: .error, category: "InputLauncherWindow")
            return
        }
        
        let screenFrame = screen.visibleFrame
        let windowFrame = frame
        
        let x = screenFrame.midX - windowFrame.width / 2
        let y = screenFrame.midY - windowFrame.height / 2
        
        setFrameOrigin(NSPoint(x: x, y: y))
    }
}
