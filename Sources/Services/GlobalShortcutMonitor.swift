import AppKit
import Foundation
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
    private var logger = OSLog(subsystem: "com.opencodemenu.app", category: "GlobalShortcut")
    
    func startMonitoring() {
        setupEventMonitors()
        os_log("グローバルショートカット監視を開始", log: logger, type: .info)
    }
    
    func stopMonitoring() {
        monitors.forEach { NSEvent.removeMonitor($0) }
        monitors.removeAll()
        os_log("グローバルショートカット監視を停止", log: logger, type: .info)
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
        
        let keyUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyUp) { [weak self] event in
            self?.handleKeyUp(event)
        }
        if let monitor = keyUpMonitor {
            monitors.append(monitor)
        }
        
        let keyDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyDown(event)
        }
        if let monitor = keyDownMonitor {
            monitors.append(monitor)
        }
    }
    
    private func handleFlagsChanged(_ event: NSEvent) {
        let newShiftPressed = event.modifierFlags.contains(.shift)
        
        if newShiftPressed != isShiftPressed {
            isShiftPressed = newShiftPressed
            os_log("Shiftキー状態変更: %@", log: logger, type: .debug, isShiftPressed ? "押下" : "解放")
        }
    }
    
    private func handleMouseDown(_ event: NSEvent) {
        guard isShiftPressed else { return }
        guard overlay == nil else { return }
        guard let mainScreen = NSScreen.main else {
            os_log("メインスクリーンが見つかりません", log: logger, type: .error)
            return
        }
        
        os_log("Shift+マウスダウン検出: オーバーレイを表示", log: logger, type: .info)
        showOverlay(on: mainScreen)
    }
    
    private func handleMouseUp(_ event: NSEvent) {
        guard isShiftPressed else { return }
        guard overlay != nil else { return }
        
        os_log("Shift+マウスアップ検出: キャプチャ終了", log: logger, type: .info)
    }
    
    private func handleKeyUp(_ event: NSEvent) {
        if event.keyCode == 53 {
            os_log("ESCキー検出: 選択キャンセル", log: logger, type: .debug)
        }
    }
    
    private func handleKeyDown(_ event: NSEvent) {
        let modifiers = event.modifierFlags
        let hasCommand = modifiers.contains(.command)
        let hasShift = modifiers.contains(.shift)
        
        guard hasCommand && hasShift else { return }
        
        switch event.keyCode {
        case 31:
            os_log("Cmd+Shift+O検出: チャットウィンドウ切り替え", log: logger, type: .info)
            delegate?.didToggleChatWindow()
        case 34:
            os_log("Cmd+Shift+I検出: 入力ランチャー表示", log: logger, type: .info)
            delegate?.didShowInputLauncher()
        default:
            break
        }
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
    
    func checkAccessibilityPermissions() -> Bool {
        let options: [String: Any] = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !trusted {
            os_log("アクセシビリティ権限がありません", log: logger, type: .info)
        } else {
            os_log("アクセシビリティ権限が付与されています", log: logger, type: .info)
        }
        
        return trusted
    }
}

extension GlobalShortcutMonitor: ScreenSelectionDelegate {
    func didSelectRect(_ rect: CGRect) {
        os_log("矩形選択完了: %@", log: logger, type: .info, NSStringFromRect(rect))
        hideOverlay()
        delegate?.didCaptureRect(rect)
    }
    
    func didCancelSelection() {
        os_log("矩形選択キャンセル", log: logger, type: .debug)
        hideOverlay()
    }
}
