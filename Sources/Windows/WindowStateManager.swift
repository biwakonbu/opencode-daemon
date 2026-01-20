import Cocoa
import SwiftUI

class WindowStateManager: ObservableObject {
    static let shared = WindowStateManager()
    
    @Published private(set) var isChatWindowVisible = false
    
    private var floatingChatWindow: FloatingChatWindow?
    private var inputLauncherWindow: InputLauncherWindow?
    private var viewModel: OpenCodeViewModel?
    
    private init() {}
    
    func setup(viewModel: OpenCodeViewModel) {
        self.viewModel = viewModel
    }
    
    func showChatWindow() {
        hideInputLauncher()
        
        if floatingChatWindow == nil, let viewModel = viewModel {
            floatingChatWindow = FloatingChatWindow(viewModel: viewModel)
        }
        
        floatingChatWindow?.show()
        isChatWindowVisible = true
    }
    
    func hideChatWindow() {
        floatingChatWindow?.hide()
        isChatWindowVisible = false
    }
    
    func toggleChatWindow() {
        if isChatWindowVisible {
            hideChatWindow()
        } else {
            showChatWindow()
        }
    }
    
    func showInputLauncher() {
        if inputLauncherWindow == nil, let viewModel = viewModel {
            inputLauncherWindow = InputLauncherWindow(viewModel: viewModel)
        }
        
        inputLauncherWindow?.show()
    }
    
    func hideInputLauncher() {
        inputLauncherWindow?.hide()
    }
    
    func restartApp() {
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [Bundle.main.bundlePath]
        task.launch()
        NSApplication.shared.terminate(nil)
    }
}
