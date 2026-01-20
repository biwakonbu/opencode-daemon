import Foundation

protocol OpenCodeAPIClientProtocol {
    func createSession() async throws -> OpenCodeSession
    func sendMessage(_ request: SendMessageRequest) async throws -> SendMessageResponse
}

protocol ScreenshotCapturing {
    func captureScreenAsData() throws -> Data
}
