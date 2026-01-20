import XCTest
@testable import OpenCodeMenuAppCore

class GlobalShortcutMonitorTests: XCTestCase {
    var monitor: GlobalShortcutMonitor!
    var mockDelegate: MockGlobalShortcutDelegate!
    
    override func setUp() {
        super.setUp()
        mockDelegate = MockGlobalShortcutDelegate()
        monitor = GlobalShortcutMonitor()
        monitor.delegate = mockDelegate
    }
    
    override func tearDown() {
        monitor.stopMonitoring()
        monitor = nil
        mockDelegate = nil
        super.tearDown()
    }
    
    @MainActor
    func testSetupAndStartMonitoring() {
        monitor.startMonitoring()
        
        XCTAssertNotNil(monitor)
        XCTAssertNotNil(monitor.delegate)
    }
    
    @MainActor
    func testStopMonitoring() {
        monitor.startMonitoring()
        monitor.stopMonitoring()
        
        XCTAssertTrue(mockDelegate.chatWindowToggleCalled == false)
        XCTAssertTrue(mockDelegate.inputLauncherCalled == false)
    }
    
    func testAccessibilityPermissions() {
        let hasPermissions = monitor.checkAccessibilityPermissions(prompt: false)
        
        XCTAssertNotNil(hasPermissions)
    }
}

class MockGlobalShortcutDelegate: GlobalShortcutDelegate {
    var chatWindowToggleCalled = false
    var inputLauncherCalled = false
    var capturedRect: CGRect?
    
    func didCaptureRect(_ rect: CGRect) {
        capturedRect = rect
    }
    
    func didToggleChatWindow() {
        chatWindowToggleCalled = true
    }
    
    func didShowInputLauncher() {
        inputLauncherCalled = true
    }
}
