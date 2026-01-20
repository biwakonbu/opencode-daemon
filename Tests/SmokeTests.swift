import XCTest
@testable import OpenCodeMenuAppCore

class SmokeTests: XCTestCase {
    func testAppComponentsCreation() {
        let logStore = RuntimeLogStore.shared
        
        XCTAssertNotNil(logStore)
        
        let windowManager = WindowStateManager.shared
        XCTAssertNotNil(windowManager)
        
        let configManager = ConfigManager()
        XCTAssertNotNil(configManager)
    }
}
