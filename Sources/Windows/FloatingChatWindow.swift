import Cocoa
import SwiftUI

class FloatingChatWindow: NSWindow {
    private let viewModel: OpenCodeViewModel
    
    init(viewModel: OpenCodeViewModel) {
        self.viewModel = viewModel
        
        super.init(
            contentRect: NSRect(x: 20, y: 0, width: 340, height: 600),
            styleMask: [.borderless, .resizable],
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
        
        let hostingView = NSHostingView(rootView: FloatingChatView(viewModel: viewModel))
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.15).cgColor
        hostingView.layer?.cornerRadius = 12
        
        contentView = hostingView
        
        positionWindow()
    }
    
    private func positionWindow() {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowHeight = frame.height
        
        let targetX: CGFloat = 20
        let targetY = screenFrame.origin.y + (screenFrame.height - windowHeight) / 2
        
        setFrameOrigin(NSPoint(x: targetX, y: targetY))
    }
    
    func show() {
        positionWindow()
        orderFrontRegardless()
        makeKey()
    }
    
    func hide() {
        orderOut(nil)
    }
}
