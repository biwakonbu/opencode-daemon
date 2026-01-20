import Cocoa
import SwiftUI

class AppStatusWindow: NSWindow {
    private let viewModel: OpenCodeViewModel
    private let windowManager: WindowStateManager
    private let logStore: RuntimeLogStore
    private let configResult: ConfigLoadResult
    private let resolvedEndpoint: String
    private let launchDate: Date
    private let checkAccessibilityPermission: () -> Bool

    init(
        viewModel: OpenCodeViewModel,
        windowManager: WindowStateManager,
        logStore: RuntimeLogStore,
        configResult: ConfigLoadResult,
        resolvedEndpoint: String,
        launchDate: Date,
        checkAccessibilityPermission: @escaping () -> Bool
    ) {
        self.viewModel = viewModel
        self.windowManager = windowManager
        self.logStore = logStore
        self.configResult = configResult
        self.resolvedEndpoint = resolvedEndpoint
        self.launchDate = launchDate
        self.checkAccessibilityPermission = checkAccessibilityPermission

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 640),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )

        setupWindow()
    }

    private func setupWindow() {
        title = "設定と状態"
        isReleasedWhenClosed = false
        setFrameAutosaveName("AppStatusWindow")

        let rootView = AppStatusView(
            viewModel: viewModel,
            windowManager: windowManager,
            logStore: logStore,
            configResult: configResult,
            resolvedEndpoint: resolvedEndpoint,
            launchDate: launchDate,
            checkAccessibilityPermission: checkAccessibilityPermission
        )

        let hostingView = NSHostingView(rootView: rootView)
        contentView = hostingView
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        center()
        makeKeyAndOrderFront(nil)
    }
}
