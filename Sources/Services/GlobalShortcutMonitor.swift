import AppKit
import Foundation
import HotKey
import os.log

protocol GlobalShortcutDelegate: AnyObject {
    func didCaptureRect(_ rect: CGRect)
    func didToggleChatWindow()
    func didShowInputLauncher()
}

class GlobalShortcutMonitor {
    weak var delegate: GlobalShortcutDelegate?
    private var monitors: [Any] = []
    private var isShiftPressed = false
    private var overlay: ScreenSelectionOverlay?
    private let logStore: RuntimeLogStore

    private var chatWindowHotKey: HotKey?
    private var inputLauncherHotKey: HotKey?

    init(logStore: RuntimeLogStore = .shared) {
        self.logStore = logStore
    }

    @MainActor
    func startMonitoring() {
        setupHotKeys()
        setupEventMonitors()
        logStore.log("グローバルショートカット監視を開始", category: "GlobalShortcut")
    }

    func stopMonitoring() {
        chatWindowHotKey = nil
        inputLauncherHotKey = nil
        monitors.forEach { NSEvent.removeMonitor($0) }
        monitors.removeAll()
        logStore.log("グローバルショートカット監視を停止", category: "GlobalShortcut")
    }

    private func setupHotKeys() {
        logStore.log("HotKey設定開始", category: "GlobalShortcut")
        logStore.log("KeyCombo.O = \(KeyCombo(key: .o, modifiers: [.command, .shift]))", category: "GlobalShortcut")
        logStore.log("KeyCombo.I = \(KeyCombo(key: .i, modifiers: [.command, .shift]))", category: "GlobalShortcut")

        let chatKeyCombo = KeyCombo(key: .o, modifiers: [.command, .shift])
        chatWindowHotKey = HotKey(keyCombo: chatKeyCombo)
        chatWindowHotKey?.keyDownHandler = { [weak self] in
            self?.logStore.log("Cmd+Shift+O検出: チャットウィンドウ切り替え", category: "GlobalShortcut")
            DispatchQueue.main.async {
                self?.delegate?.didToggleChatWindow()
            }
        }
        logStore.log("ChatWindowHotKey created: \(chatWindowHotKey != nil)", category: "GlobalShortcut")

        let inputKeyCombo = KeyCombo(key: .i, modifiers: [.command, .shift])
        inputLauncherHotKey = HotKey(keyCombo: inputKeyCombo)
        inputLauncherHotKey?.keyDownHandler = { [weak self] in
            self?.logStore.log("Cmd+Shift+I検出: 入力ランチャー表示", category: "GlobalShortcut")
            DispatchQueue.main.async {
                self?.delegate?.didShowInputLauncher()
            }
        }
        logStore.log("InputLauncherHotKey created: \(inputLauncherHotKey != nil)", category: "GlobalShortcut")

        logStore.log("HotKey設定完了", category: "GlobalShortcut")
    }

    private func setupEventMonitors() {
        let flagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }
        if let monitor = flagsMonitor {
            monitors.append(monitor)
        }

        let mouseDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            self?.handleMouseDown(event)
        }
        if let monitor = mouseDownMonitor {
            monitors.append(monitor)
        }

        let mouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { [weak self] event in
            self?.handleMouseUp(event)
        }
        if let monitor = mouseUpMonitor {
            monitors.append(monitor)
        }
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        let newShiftPressed = event.modifierFlags.contains(.shift)

        if newShiftPressed != isShiftPressed {
            isShiftPressed = newShiftPressed
            logStore.log("Shiftキー状態変更: \(isShiftPressed ? "押下" : "解放")", category: "GlobalShortcut")
        }
    }

    private func handleMouseDown(_ event: NSEvent) {
        guard isShiftPressed else { return }
        guard overlay == nil else { return }
        guard let mainScreen = NSScreen.main else {
            logStore.log("メインスクリーンが見つかりません", level: .error, category: "GlobalShortcut")
            return
        }

        logStore.log("Shift+マウスダウン検出: オーバーレイを表示", category: "GlobalShortcut")
        showOverlay(on: mainScreen)
    }

    private func handleMouseUp(_ event: NSEvent) {
        guard isShiftPressed else { return }
        guard overlay != nil else { return }

        logStore.log("Shift+マウスアップ検出: キャプチャ終了", category: "GlobalShortcut")
    }

    private func showOverlay(on screen: NSScreen) {
        overlay = ScreenSelectionOverlay(screen: screen)
        overlay?.selectionDelegate = self
        overlay?.showOverlay(on: screen)
    }

    private func hideOverlay() {
        overlay?.hideOverlay()
        overlay = nil
    }

    func checkAccessibilityPermissions(prompt: Bool = true) -> Bool {
        let options: [String: Any] = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)

        if !trusted {
            logStore.log("アクセシビリティ権限がありません", category: "GlobalShortcut")
        } else {
            logStore.log("アクセシビリティ権限が付与されています", category: "GlobalShortcut")
        }

        return trusted
    }
}

extension GlobalShortcutMonitor: ScreenSelectionDelegate {
    func didSelectRect(_ rect: CGRect) {
        logStore.log("矩形選択完了: \(NSStringFromRect(rect))", category: "GlobalShortcut")
        hideOverlay()
        delegate?.didCaptureRect(rect)
    }

    func didCancelSelection() {
        logStore.log("矩形選択キャンセル", category: "GlobalShortcut")
        hideOverlay()
    }
}
