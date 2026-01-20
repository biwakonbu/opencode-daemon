import Cocoa
import SwiftUI
import os.log

class WindowStateManager: ObservableObject {
    static let shared = WindowStateManager()
    
    @Published private(set) var isChatWindowVisible = false
    
    private var floatingChatWindow: FloatingChatWindow?
    private var inputLauncherWindow: InputLauncherWindow?
    private var viewModel: OpenCodeViewModel?
    
    private init() {}
    
    func setup(viewModel: OpenCodeViewModel) {
        self.viewModel = viewModel
        viewModel.logStore.log("WindowStateManager初期化完了", category: "WindowManager")
    }
    
    func showChatWindow() {
        viewModel?.logStore.log("チャットウィンドウ表示開始", category: "WindowManager")
        viewModel?.logStore.log("現在のスレッド: \(Thread.isMainThread)", category: "WindowManager")
        hideInputLauncher()
        
        if floatingChatWindow == nil, let viewModel = viewModel {
            floatingChatWindow = FloatingChatWindow(viewModel: viewModel)
            viewModel.logStore.log("新しいFloatingChatWindowを作成", category: "WindowManager")
        }
        
        floatingChatWindow?.show()
        isChatWindowVisible = true
        viewModel?.logStore.log("チャットウィンドウ表示完了, 可視状態: \(isChatWindowVisible)", category: "WindowManager")
        viewModel?.logStore.log("ウィンドウインスタンス: \(String(describing: floatingChatWindow))", category: "WindowManager")
    }
    
    func hideChatWindow() {
        viewModel?.logStore.log("チャットウィンドウ非表示開始", category: "WindowManager")
        floatingChatWindow?.hide()
        isChatWindowVisible = false
        viewModel?.logStore.log("チャットウィンドウ非表示完了, 可視状態: \(isChatWindowVisible)", category: "WindowManager")
    }
    
    func toggleChatWindow() {
        viewModel?.logStore.log("チャットウィンドウ切り替え, 現在の可視状態: \(isChatWindowVisible)", category: "WindowManager")
        if isChatWindowVisible {
            hideChatWindow()
        } else {
            showChatWindow()
        }
    }
    
    func showInputLauncher() {
        viewModel?.logStore.log("入力ランチャー表示開始", category: "WindowManager")
        if inputLauncherWindow == nil, let viewModel = viewModel {
            inputLauncherWindow = InputLauncherWindow(viewModel: viewModel)
            viewModel.logStore.log("新しいInputLauncherWindowを作成", category: "WindowManager")
        }
        
        inputLauncherWindow?.show()
        viewModel?.logStore.log("入力ランチャー表示完了", category: "WindowManager")
    }
    
    func hideInputLauncher() {
        viewModel?.logStore.log("入力ランチャー非表示開始", category: "WindowManager")
        inputLauncherWindow?.hide()
        viewModel?.logStore.log("入力ランチャー非表示完了", category: "WindowManager")
    }
    
    func restartApp() {
        let logStore = viewModel?.logStore ?? RuntimeLogStore.shared
        logStore.log("アプリ再起動開始", category: "WindowManager")
        
        let appPath = Bundle.main.bundlePath
        logStore.log("バンドルパス: \(appPath)", category: "WindowManager")
        
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [appPath]
        task.launch()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            logStore.log("アプリを終了します", category: "WindowManager")
            NSApplication.shared.terminate(nil)
        }
    }
}
