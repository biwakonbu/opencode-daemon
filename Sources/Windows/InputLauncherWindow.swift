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
                self?.hide()
            }
        )
        
        let hostingView = NSHostingView(rootView: inputLauncherView)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = .clear
        
        contentView = hostingView
    }
    
    private func handleSendMessage() async {
        await viewModel.sendMessage()
        hide()
    }
    
    func show() {
        centerOnScreen()
        orderFrontRegardless()
        makeKey()
    }
    
    func hide() {
        orderOut(nil)
        viewModel.inputMessage = ""
    }
    
    private func centerOnScreen() {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowFrame = frame
        
        let x = screenFrame.midX - windowFrame.width / 2
        let y = screenFrame.midY - windowFrame.height / 2
        
        setFrameOrigin(NSPoint(x: x, y: y))
    }
}
