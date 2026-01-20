import Cocoa
import SwiftUI

class InputLauncherWindow: NSWindow {
    private let viewModel: OpenCodeViewModel
    
    init(viewModel: OpenCodeViewModel) {
        self.viewModel = viewModel
        
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        setupWindow()
    }
    
    private func setupWindow() {
        isOpaque = false
        backgroundColor = .clear
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
        viewModel.logStore.log("入力ランチャー: 送信処理開始", category: "InputLauncherWindow")
        await viewModel.sendMessage()
        hide()
    }
    
    func show() {
        viewModel.logStore.log("InputLauncherWindow表示開始", category: "InputLauncherWindow")
        centerOnScreen()
        orderFrontRegardless()
        makeKey()
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
