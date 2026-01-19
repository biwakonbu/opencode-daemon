import Foundation
import Combine
import os.log

@MainActor
class OpenCodeViewModel: ObservableObject {
    private let apiClient: OpenCodeAPIClient
    private let screenshotCapture: ScreenshotCapture
    let logStore: RuntimeLogStore
    private var cancellables = Set<AnyCancellable>()
    private let logger = OSLog(subsystem: "com.opencodemenu.app", category: "ViewModel")
    
    @Published var currentSession: OpenCodeSession?
    @Published var messages: [OpenCodeMessage] = []
    @Published var inputMessage: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    init(apiClient: OpenCodeAPIClient, screenshotCapture: ScreenshotCapture, logStore: RuntimeLogStore) {
        self.apiClient = apiClient
        self.screenshotCapture = screenshotCapture
        self.logStore = logStore
    }
    
    func createSession() async {
        isLoading = true
        errorMessage = nil
        os_log("セッション作成を開始", log: logger, type: .info)
        logStore.log("セッション作成を開始", category: "ViewModel")
        
        do {
            let session = try await apiClient.createSession()
            currentSession = session
            messages = []
            os_log("セッション作成成功: %@", log: logger, type: .info, session.id)
            logStore.log("セッション作成成功: \(session.id)", category: "ViewModel")
        } catch {
            os_log("セッション作成失敗: %@", log: logger, type: .error, error.localizedDescription)
            errorMessage = error.localizedDescription
            logStore.log("セッション作成失敗: \(error.localizedDescription)", level: .error, category: "ViewModel")
        }
        
        isLoading = false
    }
    
    func sendMessage() async {
        guard let session = currentSession else {
            errorMessage = "セッションが作成されていません"
            return
        }
        
        let trimmedMessage = inputMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        let messageToSend = trimmedMessage
        inputMessage = ""
        logStore.log("メッセージ送信: \(messageToSend)", category: "ViewModel")
        
        do {
            let request = SendMessageRequest(
                sessionId: session.id,
                parts: [OpenCodeMessagePart.text(messageToSend)],
                model: nil
            )
            let response = try await apiClient.sendMessage(request)
            
            let userMessage = OpenCodeMessage(sessionId: session.id, content: messageToSend, role: "user")
            messages.append(userMessage)
            
            if !response.content.isEmpty {
                let assistantMessage = OpenCodeMessage(id: response.id, sessionId: session.id, content: response.content, role: response.role, timestamp: response.timestamp)
                messages.append(assistantMessage)
                logStore.log("アシスタント応答受信: \(response.content)", category: "ViewModel")
            } else {
                errorMessage = "アシスタントのテキスト応答が取得できませんでした"
                logStore.log("アシスタント応答が空", level: .warning, category: "ViewModel")
            }
            
            var updatedSession = session
            updatedSession.update()
            currentSession = updatedSession
            
        } catch {
            errorMessage = error.localizedDescription
            logStore.log("メッセージ送信失敗: \(error.localizedDescription)", level: .error, category: "ViewModel")
        }
        
        isLoading = false
    }
    
    func captureAndSendScreenshot() async {
        guard let session = currentSession else {
            errorMessage = "セッションが作成されていません"
            return
        }
        
        isLoading = true
        errorMessage = nil
        logStore.log("スクリーンショット送信を開始", category: "ViewModel")
        
        do {
            let imageData = try screenshotCapture.captureScreenAsData()
            logStore.log("スクリーンショット取得成功: \(imageData.count) bytes", category: "ViewModel")
            let messageText = "スクリーンショットを取得しました（テキストのみのメッセージとして送信中）"
            
            let request = SendMessageRequest(
                sessionId: session.id,
                parts: [
                    OpenCodeMessagePart.text(messageText)
                ],
                model: nil
            )
            let response = try await apiClient.sendMessage(request)
            
            let userMessage = OpenCodeMessage(sessionId: session.id, content: messageText, role: "user")
            messages.append(userMessage)
            
            if !response.content.isEmpty {
                let assistantMessage = OpenCodeMessage(id: response.id, sessionId: session.id, content: response.content, role: response.role, timestamp: response.timestamp)
                messages.append(assistantMessage)
                logStore.log("アシスタント応答受信: \(response.content)", category: "ViewModel")
            } else {
                errorMessage = "アシスタントのテキスト応答が取得できませんでした"
                logStore.log("アシスタント応答が空", level: .warning, category: "ViewModel")
            }
            
            var updatedSession = session
            updatedSession.update()
            currentSession = updatedSession
        } catch {
            errorMessage = error.localizedDescription
            logStore.log("スクリーンショット送信失敗: \(error.localizedDescription)", level: .error, category: "ViewModel")
        }
        
        isLoading = false
    }
    
    func clearSession() {
        currentSession = nil
        messages = []
        errorMessage = nil
        logStore.log("セッションをクリアしました", category: "ViewModel")
    }
}
