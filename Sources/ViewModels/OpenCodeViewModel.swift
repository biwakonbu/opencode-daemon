import Foundation
import Combine
import os.log

@MainActor
class OpenCodeViewModel: ObservableObject {
    private let apiClient: OpenCodeAPIClientProtocol
    private let screenshotCapture: ScreenshotCapturing
    let logStore: RuntimeLogStore
    private var cancellables = Set<AnyCancellable>()
    private let logger = OSLog(subsystem: "com.opencodemenu.app", category: "ViewModel")
    
    @Published var currentSession: OpenCodeSession?
    @Published var messages: [OpenCodeMessage] = []
    @Published var inputMessage: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var pendingImageData: Data?
    
    init(apiClient: OpenCodeAPIClientProtocol, screenshotCapture: ScreenshotCapturing, logStore: RuntimeLogStore) {
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

    func sendMessageWithAutoSession() async {
        guard await ensureSessionExists() else { return }
        await sendMessage()
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

    func captureAndSendScreenshotWithAutoSession() async {
        guard await ensureSessionExists() else { return }
        await captureAndSendScreenshot()
    }

    func attachScreenshotForPrompt() async {
        isLoading = true
        errorMessage = nil
        do {
            let imageData = try screenshotCapture.captureScreenAsData()
            pendingImageData = imageData
        } catch {
            errorMessage = error.localizedDescription
            logStore.log("スクリーンショット添付失敗: \(error.localizedDescription)", level: .error, category: "ViewModel")
        }
        isLoading = false
    }
    
    func clearSession() {
        currentSession = nil
        messages = []
        errorMessage = nil
        logStore.log("セッションをクリアしました", category: "ViewModel")
    }

    func setPendingImageData(_ imageData: Data) {
        pendingImageData = imageData
        errorMessage = nil
    }

    func clearPendingImage() {
        pendingImageData = nil
    }
    
    func ensureSessionExists(imageData: Data? = nil) async -> Bool {
        if currentSession != nil {
            return true
        }
        await createSession()
        return currentSession != nil
    }
    
    func addMessage(_ message: OpenCodeMessage) {
        messages.append(message)
    }
    
    func sendImageWithAutoSession(imageData: Data, userPrompt: String? = nil) async {
        isLoading = true
        errorMessage = nil
        
        guard await ensureSessionExists(imageData: imageData) else {
            errorMessage = "セッションの作成に失敗しました"
            isLoading = false
            return
        }
        
        guard let session = currentSession else {
            errorMessage = "セッションが作成されていません"
            isLoading = false
            return
        }
        
        do {
            let dataURL = encodeImageData(imageData)
            let filePart = OpenCodeMessagePart.file(
                url: dataURL,
                mime: "image/png",
                filename: "screenshot.png"
            )
            
            let trimmedPrompt = (userPrompt ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let userRequestHeader: String
            if trimmedPrompt.isEmpty {
                userRequestHeader = "次のスクリーンショットを分析してください。"
            } else {
                userRequestHeader = """
                次のスクリーンショットについて、ユーザーの依頼に従ってください。
                
                ユーザーの依頼:
                \(trimmedPrompt)
                """
            }
            
            let userText = """
            \(userRequestHeader)
            
            必要に応じて以下のMCPツールを自動で選択して使用してください：
            - zai-mcp-server_analyze_image: 一般的な画像分析
            - zai-mcp-server_extract_text_from_screenshot: テキスト抽出
            - zai-mcp-server_ui_to_artifact: UI画面をコード変換
            - zai-mcp-server_diagnose_error_screenshot: エラー診断
            - zai-mcp-server_understand_technical_diagram: 技術図解
            - zai-mcp-server_analyze_data_visualization: データ可視化
            
            画像の内容に応じて最適なツールを選び、結果が不十分な場合は別のツールも試してください。
            """
            
            let request = SendMessageRequest(
                sessionId: session.id,
                parts: [filePart, .text(userText)],
                model: nil
            )
            
            let response = try await apiClient.sendMessage(request)
            
            let userMessageContent: String
            if trimmedPrompt.isEmpty {
                userMessageContent = "スクリーンショットを送信しました"
            } else {
                userMessageContent = "スクリーンショット: \(trimmedPrompt)"
            }
            let userMessage = OpenCodeMessage(
                id: UUID().uuidString,
                sessionId: session.id,
                content: userMessageContent,
                role: "user"
            )
            messages.append(userMessage)
            
            if !response.content.isEmpty {
                let assistantMessage = OpenCodeMessage(
                    id: response.id,
                    sessionId: session.id,
                    content: response.content,
                    role: response.role,
                    timestamp: response.timestamp
                )
                messages.append(assistantMessage)
                logStore.log("MCP分析結果受信", category: "ViewModel")
            }
            
            var updatedSession = session
            updatedSession.update()
            currentSession = updatedSession
            
        } catch {
            errorMessage = error.localizedDescription
            logStore.log("画像送信失敗: \(error.localizedDescription)", level: .error, category: "ViewModel")
        }
        
        isLoading = false
    }

    func sendLauncherPrompt() async {
        let trimmedPrompt = inputMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard pendingImageData != nil || !trimmedPrompt.isEmpty else { return }
        
        if let imageData = pendingImageData {
            inputMessage = ""
            let promptToSend = trimmedPrompt.isEmpty ? nil : trimmedPrompt
            await sendImageWithAutoSession(imageData: imageData, userPrompt: promptToSend)
            if errorMessage == nil {
                pendingImageData = nil
            }
        } else {
            await sendMessageWithAutoSession()
        }
    }
    
    private func encodeImageData(_ data: Data) -> String {
        let base64 = data.base64EncodedString()
        return "data:image/png;base64,\(base64)"
    }
}

// test2
