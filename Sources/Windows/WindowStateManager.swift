import Cocoa
import SwiftUI

class WindowStateManager: ObservableObject {
    static let shared = WindowStateManager()
    
    @Published private(set) var isChatWindowVisible = false
    
    private var floatingChatWindow: FloatingChatWindow?
    private var inputLauncherWindow: InputLauncherWindow?
    private var viewModel: OpenCodeViewModel?
    
    private init() {}
    
    @MainActor
    func setup(viewModel: OpenCodeViewModel) {
        self.viewModel = viewModel
        viewModel.logStore.log("WindowStateManager初期化完了", category: "WindowManager")
    }
    
    @MainActor
    func showChatWindow() {
        viewModel?.logStore.log("チャットウィンドウ表示開始", category: "WindowManager")
        hideInputLauncher()
        
        if floatingChatWindow == nil, let viewModel = viewModel {
            floatingChatWindow = FloatingChatWindow(viewModel: viewModel)
            viewModel.logStore.log("新しいFloatingChatWindowを作成", category: "WindowManager")
        }
        
        floatingChatWindow?.show()
        isChatWindowVisible = true
        viewModel?.logStore.log("チャットウィンドウ表示完了, 可視状態: \(isChatWindowVisible)", category: "WindowManager")
    }
    
    @MainActor
    func hideChatWindow() {
        viewModel?.logStore.log("チャットウィンドウ非表示開始", category: "WindowManager")
        floatingChatWindow?.hide()
        isChatWindowVisible = false
        viewModel?.logStore.log("チャットウィンドウ非表示完了, 可視状態: \(isChatWindowVisible)", category: "WindowManager")
    }
    
    @MainActor
    func toggleChatWindow() {
        viewModel?.logStore.log("チャットウィンドウ切り替え, 現在の可視状態: \(isChatWindowVisible)", category: "WindowManager")
        if isChatWindowVisible {
            hideChatWindow()
        } else {
            showChatWindow()
        }
    }
    
    @MainActor
    func showInputLauncher() {
        viewModel?.logStore.log("入力ランチャー表示開始", category: "WindowManager")
        hideChatWindow()
        if inputLauncherWindow == nil, let viewModel = viewModel {
            inputLauncherWindow = InputLauncherWindow(viewModel: viewModel)
            viewModel.logStore.log("新しいInputLauncherWindowを作成", category: "WindowManager")
        }
        
        inputLauncherWindow?.show()
        viewModel?.logStore.log("入力ランチャー表示完了", category: "WindowManager")
    }
    
    @MainActor
    func hideInputLauncher() {
        viewModel?.logStore.log("入力ランチャー非表示開始", category: "WindowManager")
        inputLauncherWindow?.hide()
        viewModel?.logStore.log("入力ランチャー非表示完了", category: "WindowManager")
    }
    
    @MainActor
    func restartApp() {
        let logStore = viewModel?.logStore ?? RuntimeLogStore.shared
        logStore.log("アプリ再起動開始", category: "WindowManager")
        
        let appBundlePath = Bundle.main.bundlePath
        logStore.log("バンドルパス: \(appBundlePath)", category: "WindowManager")
        
        let appUrl = URL(fileURLWithPath: appBundlePath)
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        
        NSWorkspace.shared.openApplication(at: appUrl, configuration: config) { app, error in
            if let error = error {
                RuntimeLogStore.shared.log("アプリ再起動エラー: \(error.localizedDescription)", level: .error, category: "WindowManager")
            } else {
                RuntimeLogStore.shared.log("アプリ起動成功", category: "WindowManager")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    RuntimeLogStore.shared.log("既存プロセスを終了します", category: "WindowManager")
                    NSApplication.shared.terminate(nil)
                }
            }
        }
    }
}
