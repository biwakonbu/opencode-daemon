import Foundation
import os.log

class MCPImageAnalyzer {
    private let apiClient: OpenCodeAPIClient
    private let viewModel: OpenCodeViewModel
    private let notificationCenter: NotificationCenterService
    private let logStore: RuntimeLogStore
    private let logger = OSLog(subsystem: "com.opencodemenu.app", category: "MCPImageAnalyzer")

    init(
        apiClient: OpenCodeAPIClient, viewModel: OpenCodeViewModel, notificationCenter: NotificationCenterService, logStore: RuntimeLogStore
    ) {
        self.apiClient = apiClient
        self.viewModel = viewModel
        self.notificationCenter = notificationCenter
        self.logStore = logStore
    }

    func sendImageWithAutoSession(imageData: Data) async {
        logStore.log("MCP画像分析を開始", category: "MCP")
        os_log("MCP画像分析を開始: %d bytes", log: logger, type: .info, imageData.count)

        await viewModel.sendImageWithAutoSession(imageData: imageData)

        await notificationCenter.sendSuccessNotification(title: "完了", message: "スクリーンショット分析が完了しました")
        logStore.log("MCP画像分析完了", category: "MCP")
    }
}
