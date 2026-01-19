import Cocoa
import SwiftUI

class StatusBar {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
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
        
        setupPopover()
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 400, height: 500)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: ContentView(viewModel: viewModel))
    }
    
    @objc private func statusBarButtonClicked() {
        guard let popover = popover, statusItem?.button != nil else { return }
        
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }
    
    private func showPopover() {
        guard let popover = popover, let button = statusItem?.button else { return }
        
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func closePopover() {
        popover?.performClose(nil)
    }
}
