import AppKit
import Foundation
import os.log
import UserNotifications

class NotificationCenterService {
    private let logger = OSLog(subsystem: "com.opencodemenu.app", category: "NotificationCenter")
    private var isAuthorized = false
    private var notificationsEnabled = false
    private var useAlerts = false
    
    init() {
        useAlerts = !isBundleAvailable()
    }
    
    private func isBundleAvailable() -> Bool {
        let bundle = Bundle.main
        let url = bundle.bundleURL
        return url.pathExtension == "app" && bundle.bundleIdentifier != nil
    }
    
    @MainActor
    func requestNotificationAuthorization() {
        guard !isAuthorized else { return }
        
        if useAlerts {
            os_log("NSAlertを使用します", log: logger, type: .info)
            return
        }
        
        do {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, error in
                guard let self = self else { return }
                self.isAuthorized = granted
                self.notificationsEnabled = granted
                if let error = error {
                    os_log("通知許可リクエストエラー: %@", log: self.logger, type: .error, error.localizedDescription)
                } else if granted {
                    os_log("通知許可が付与されました", log: self.logger, type: .info)
                } else {
                    os_log("通知許可が拒否されました", log: self.logger, type: .info)
                }
            }
        } catch {
            os_log("通知初期化エラー: %@", log: self.logger, type: .error, error.localizedDescription)
            notificationsEnabled = false
            useAlerts = true
        }
    }
    
    @MainActor
    func sendSuccessNotification(title: String, message: String) {
        if useAlerts {
            showAlert(title: title, message: message, alertStyle: .informational)
        } else {
            sendNotification(title: title, message: message, alertStyle: .informational)
        }
    }
    
    @MainActor
    func sendErrorNotification(title: String, message: String) {
        if useAlerts {
            showAlert(title: title, message: message, alertStyle: .critical)
        } else {
            sendNotification(title: title, message: message, alertStyle: .critical)
        }
    }
    
    @MainActor
    func sendInfoNotification(title: String, message: String) {
        if useAlerts {
            showAlert(title: title, message: message, alertStyle: .informational)
        } else {
            sendNotification(title: title, message: message, alertStyle: .informational)
        }
    }
    
    @MainActor
    private func sendNotification(title: String, message: String, alertStyle: NSAlert.Style) {
        guard notificationsEnabled else {
            os_log("通知無効: %@ - %@", log: logger, type: .info, title, message)
            showAlert(title: title, message: message, alertStyle: alertStyle)
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                os_log("通知送信エラー: %@", log: self.logger, type: .error, error.localizedDescription)
                Task { @MainActor in
                    self.useAlerts = true
                    self.showAlert(title: title, message: message, alertStyle: alertStyle)
                }
            } else {
                os_log("通知送信成功: %@ - %@", log: self.logger, type: .info, title, message)
            }
        }
    }
    
    @MainActor
    private func showAlert(title: String, message: String, alertStyle: NSAlert.Style) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = alertStyle
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
