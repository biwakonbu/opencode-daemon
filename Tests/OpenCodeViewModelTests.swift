import XCTest
@testable import OpenCodeMenuAppCore

final class OpenCodeViewModelTests: XCTestCase {
    @MainActor
    func testSendMessageWithAutoSessionCreatesSession() async {
        let apiClient = StubAPIClient()
        let screenshot = StubScreenshotCapture(result: .success(Data([0x01])))
        let viewModel = OpenCodeViewModel(
            apiClient: apiClient,
            screenshotCapture: screenshot,
            logStore: RuntimeLogStore.shared
        )
        viewModel.inputMessage = "hello"
        
        await viewModel.sendMessageWithAutoSession()
        
        XCTAssertEqual(apiClient.createSessionCallCount, 1)
        XCTAssertEqual(apiClient.sendMessageRequests.count, 1)
        XCTAssertEqual(viewModel.messages.count, 2)
        XCTAssertEqual(viewModel.messages.first?.role, "user")
        XCTAssertEqual(viewModel.messages.first?.content, "hello")
        XCTAssertEqual(viewModel.inputMessage, "")
        XCTAssertNil(viewModel.errorMessage)
    }
    
    @MainActor
    func testSendMessageWithAutoSessionUsesExistingSession() async {
        let apiClient = StubAPIClient()
        let screenshot = StubScreenshotCapture(result: .success(Data([0x01])))
        let viewModel = OpenCodeViewModel(
            apiClient: apiClient,
            screenshotCapture: screenshot,
            logStore: RuntimeLogStore.shared
        )
        viewModel.currentSession = OpenCodeSession(id: "session-1")
        viewModel.inputMessage = "existing session"
        
        await viewModel.sendMessageWithAutoSession()
        
        XCTAssertEqual(apiClient.createSessionCallCount, 0)
        XCTAssertEqual(apiClient.sendMessageRequests.count, 1)
        XCTAssertEqual(viewModel.messages.count, 2)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    @MainActor
    func testSendMessageWithAutoSessionStopsWhenSessionCreationFails() async {
        let apiClient = StubAPIClient(
            createSessionResult: .failure(TestError(message: "test error"))
        )
        let screenshot = StubScreenshotCapture(result: .success(Data([0x01])))
        let viewModel = OpenCodeViewModel(
            apiClient: apiClient,
            screenshotCapture: screenshot,
            logStore: RuntimeLogStore.shared
        )
        viewModel.inputMessage = "send"
        
        await viewModel.sendMessageWithAutoSession()
        
        XCTAssertEqual(apiClient.createSessionCallCount, 1)
        XCTAssertEqual(apiClient.sendMessageRequests.count, 0)
        XCTAssertEqual(viewModel.messages.count, 0)
        XCTAssertEqual(viewModel.errorMessage, "test error")
    }
    
    @MainActor
    func testSendMessageWithAutoSessionSetsErrorWhenResponseEmpty() async {
        let apiClient = StubAPIClient(
            sendMessageResult: .success(makeResponse(content: ""))
        )
        let screenshot = StubScreenshotCapture(result: .success(Data([0x01])))
        let viewModel = OpenCodeViewModel(
            apiClient: apiClient,
            screenshotCapture: screenshot,
            logStore: RuntimeLogStore.shared
        )
        viewModel.currentSession = OpenCodeSession(id: "session-1")
        viewModel.inputMessage = "empty response"
        
        await viewModel.sendMessageWithAutoSession()
        
        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertTrue(viewModel.errorMessage?.isEmpty == false)
    }
    
    @MainActor
    func testCaptureAndSendScreenshotWithAutoSessionSendsMessage() async {
        let apiClient = StubAPIClient()
        let screenshot = StubScreenshotCapture(result: .success(Data([0x02, 0x03])))
        let viewModel = OpenCodeViewModel(
            apiClient: apiClient,
            screenshotCapture: screenshot,
            logStore: RuntimeLogStore.shared
        )
        
        await viewModel.captureAndSendScreenshotWithAutoSession()
        
        XCTAssertEqual(apiClient.createSessionCallCount, 1)
        XCTAssertEqual(screenshot.captureScreenAsDataCallCount, 1)
        XCTAssertEqual(apiClient.sendMessageRequests.count, 1)
        XCTAssertEqual(viewModel.messages.count, 2)
        XCTAssertNil(viewModel.errorMessage)
        
        let parts = apiClient.sendMessageRequests.first?.parts ?? []
        XCTAssertEqual(parts.first?.type, "text")
        XCTAssertTrue(parts.first?.text?.isEmpty == false)
    }
    
    @MainActor
    func testCaptureAndSendScreenshotWithAutoSessionSetsErrorWhenCaptureFails() async {
        let apiClient = StubAPIClient()
        let screenshot = StubScreenshotCapture(result: .failure(TestError(message: "capture failed")))
        let viewModel = OpenCodeViewModel(
            apiClient: apiClient,
            screenshotCapture: screenshot,
            logStore: RuntimeLogStore.shared
        )
        
        await viewModel.captureAndSendScreenshotWithAutoSession()
        
        XCTAssertEqual(apiClient.sendMessageRequests.count, 0)
        XCTAssertEqual(viewModel.errorMessage, "capture failed")
    }
}

private final class StubAPIClient: OpenCodeAPIClientProtocol {
    var createSessionCallCount = 0
    var sendMessageRequests: [SendMessageRequest] = []
    private let createSessionResult: Result<OpenCodeSession, Error>
    private let sendMessageResult: Result<SendMessageResponse, Error>
    
    init(
        createSessionResult: Result<OpenCodeSession, Error> = .success(OpenCodeSession(id: "session-1")),
        sendMessageResult: Result<SendMessageResponse, Error> = .success(makeResponse(content: "OK"))
    ) {
        self.createSessionResult = createSessionResult
        self.sendMessageResult = sendMessageResult
    }
    
    func createSession() async throws -> OpenCodeSession {
        createSessionCallCount += 1
        return try createSessionResult.get()
    }
    
    func sendMessage(_ request: SendMessageRequest) async throws -> SendMessageResponse {
        sendMessageRequests.append(request)
        return try sendMessageResult.get()
    }
}

private final class StubScreenshotCapture: ScreenshotCapturing {
    var captureScreenAsDataCallCount = 0
    private let result: Result<Data, Error>
    
    init(result: Result<Data, Error>) {
        self.result = result
    }
    
    func captureScreenAsData() throws -> Data {
        captureScreenAsDataCallCount += 1
        return try result.get()
    }
}

private struct TestError: LocalizedError {
    let message: String
    
    var errorDescription: String? {
        message
    }
}

private func makeResponse(content: String) -> SendMessageResponse {
    let json = """
    {"info":{"id":"resp-1","role":"assistant","time":{"created":1700000000}},"parts":[{"type":"text","text":"\(content)"}]}
    """
    let data = json.data(using: .utf8) ?? Data()
    return (try? JSONDecoder().decode(SendMessageResponse.self, from: data)) ?? fallbackResponse()
}

private func fallbackResponse() -> SendMessageResponse {
    let json = """
    {"info":{"id":"resp-2","role":"assistant","time":{"created":1700000000}},"parts":[{"type":"text","text":"OK"}]}
    """
    let data = json.data(using: .utf8) ?? Data()
    return try! JSONDecoder().decode(SendMessageResponse.self, from: data)
}
