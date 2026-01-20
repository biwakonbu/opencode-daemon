import Foundation
import os.log

class OpenCodeAPIClient: OpenCodeAPIClientProtocol {
    private var config: Config?
    private let session: URLSession
    private let logger = OSLog(subsystem: "com.opencodemenu.app", category: "APIClient")
    private let logStore: RuntimeLogStore
    
    private var defaultModel: OpenCodeModel? {
        guard let providerID = config?.defaultModelProvider,
              let modelID = config?.defaultModelID else {
            return nil
        }
        return OpenCodeModel(providerID: providerID, modelID: modelID)
    }
    
    init(logStore: RuntimeLogStore = .shared) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        self.session = URLSession(configuration: config)
        self.logStore = logStore
    }
    
    func setConfig(_ config: Config) {
        self.config = config
    }
    
    func createSession() async throws -> OpenCodeSession {
        let endpoint = resolvedEndpoint()
        os_log("セッション作成リクエスト: %@", log: logger, type: .info, "\(endpoint)/session")
        logStore.log("POST /session", category: "API")
        
        let url = URL(string: "\(endpoint)/session")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyHeaders(&request)
        
        let requestBody: [String: Any] = [
            "title": "OpenCodeApp Session"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        if let bodyString = String(data: request.httpBody!, encoding: .utf8) {
            os_log("リクエストボディ: %@", log: logger, type: .info, bodyString)
            logStore.log("リクエストボディ: \(bodyString)", category: "API")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            os_log("無効なレスポンス", log: logger, type: .error)
            throw APIError.invalidResponse
        }
        
        os_log("ステータスコード: %d", log: logger, type: .info, httpResponse.statusCode)
        logStore.log("ステータスコード: \(httpResponse.statusCode)", category: "API")
        
        if let responseString = String(data: data, encoding: .utf8) {
            os_log("レスポンスボディ: %@", log: logger, type: .info, responseString)
            logStore.log("レスポンスボディ: \(responseString)", category: "API")
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try JSONDecoder().decode(OpenCodeSession.self, from: data)
            } catch {
                os_log("JSONデコードエラー: %@", log: logger, type: .error, error.localizedDescription)
                logStore.log("JSONデコードエラー: \(error.localizedDescription)", level: .error, category: "API")
                if let responseString = String(data: data, encoding: .utf8) {
                    throw APIError.jsonDecodeError(details: responseString, underlyingError: error)
                } else {
                    throw APIError.jsonDecodeError(details: "レスポンスデータなし", underlyingError: error)
                }
            }
        case 401:
            throw APIError.unauthorized
        default:
            if let responseString = String(data: data, encoding: .utf8) {
                os_log("サーバーエラー: %@", log: logger, type: .error, responseString)
                throw APIError.serverError(statusCode: httpResponse.statusCode)
            } else {
                throw APIError.serverError(statusCode: httpResponse.statusCode)
            }
        }
    }
    
    func sendMessage(_ request: SendMessageRequest) async throws -> SendMessageResponse {
        let endpoint = resolvedEndpoint()
        
        let url = URL(string: "\(endpoint)/session/\(request.sessionId)/message")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        applyHeaders(&urlRequest)
        
        let body = MessageBody(
            parts: request.parts,
            model: request.model ?? defaultModel
        )
        urlRequest.httpBody = try JSONEncoder().encode(body)
        
        logStore.log("POST /session/\(request.sessionId)/message", category: "API")
        logStore.log("送信パーツ: \(summarizeParts(request.parts))", category: "API")
        
        os_log("リクエストURL: %@", log: logger, type: .info, url.absoluteString)
        if let requestHeaders = urlRequest.allHTTPHeaderFields {
            os_log("リクエストヘッダー: %@", log: logger, type: .info, requestHeaders.description)
        }
        if let bodyString = String(data: urlRequest.httpBody!, encoding: .utf8) {
            os_log("リクエストボディ: %@", log: logger, type: .info, bodyString)
            logStore.log("リクエストボディ: \(bodyString)", category: "API")
        }
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        os_log("ステータスコード: %d", log: logger, type: .info, httpResponse.statusCode)
        logStore.log("ステータスコード: \(httpResponse.statusCode)", category: "API")
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                if data.isEmpty {
                    os_log("空のレスポンスボディを受信", log: logger, type: .error)
                    logStore.log("空のレスポンスボディを受信", level: .error, category: "API")
                    throw APIError.serverError(statusCode: httpResponse.statusCode)
                }
                if let responseString = String(data: data, encoding: .utf8) {
                    logStore.log("レスポンスボディ: \(responseString)", category: "API")
                    os_log("レスポンスボディ: %@", log: logger, type: .info, responseString)
                }
                let result = try JSONDecoder().decode(SendMessageResponse.self, from: data)
                os_log("デコード成功: id=%@, role=%@, content=%@ chars", log: logger, type: .info, result.id, result.role, "\(result.content.count)")
                return result
            } catch {
                os_log("JSONデコードエラー: %@", log: logger, type: .error, error.localizedDescription)
                logStore.log("JSONデコードエラー: \(error.localizedDescription)", level: .error, category: "API")
                if let responseString = String(data: data, encoding: .utf8) {
                    throw APIError.jsonDecodeError(details: responseString, underlyingError: error)
                } else {
                    throw APIError.jsonDecodeError(details: "レスポンスデータなし", underlyingError: error)
                }
            }
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        default:
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
    }
    
    private func resolvedEndpoint() -> String {
        let endpoint = config?.apiEndpoint.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return endpoint.isEmpty ? "http://127.0.0.1:4096" : endpoint
    }
    
    private func applyHeaders(_ request: inout URLRequest) {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey = config?.apiKey, !apiKey.isEmpty, apiKey != "your-api-key-here" {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
    }
    
    private struct MessageBody: Encodable {
        let parts: [OpenCodeMessagePart]
        let model: OpenCodeModel?
        
        private enum CodingKeys: String, CodingKey {
            case parts
            case model
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(parts, forKey: .parts)
            if let model = model {
                try container.encode(model, forKey: .model)
            }
        }
    }
    
    private func summarizeParts(_ parts: [OpenCodeMessagePart]) -> String {
        let summaries = parts.map { part -> String in
            switch part.type {
            case "text":
                let text = part.text ?? ""
                return "text(\(text.count) chars)"
            case "file":
                let mime = part.mime ?? "unknown"
                let filename = part.filename ?? "-"
                let url = summarizeUrl(part.url)
                return "file(mime=\(mime), name=\(filename), url=\(url))"
            default:
                return "type=\(part.type)"
            }
        }
        return summaries.joined(separator: " | ")
    }
    
    private func summarizeUrl(_ url: String?) -> String {
        guard let url else { return "-" }
        if url.hasPrefix("data:") {
            return "data-url(\(url.count) chars)"
        }
        return url
    }
}

enum APIError: LocalizedError {
    case missingConfig
    case invalidResponse
    case unauthorized
    case notFound
    case serverError(statusCode: Int)
    case jsonDecodeError(details: String, underlyingError: Error)
    
    var errorDescription: String? {
        switch self {
        case .missingConfig:
            return "設定が見つかりません"
        case .invalidResponse:
            return "無効なレスポンス"
        case .unauthorized:
            return "認証に失敗しました"
        case .notFound:
            return "リソースが見つかりません"
        case .serverError(let code):
            return "サーバーエラー (ステータスコード: \(code))"
        case .jsonDecodeError(let details, let error):
            return "JSONデコードエラー: \(details)\n基礎エラー: \(error.localizedDescription)"
        }
    }
}
