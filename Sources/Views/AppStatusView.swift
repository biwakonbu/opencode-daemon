import SwiftUI

struct AppStatusView: View {
    @ObservedObject var viewModel: OpenCodeViewModel
    @ObservedObject var windowManager: WindowStateManager
    @ObservedObject var logStore: RuntimeLogStore
    let configResult: ConfigLoadResult
    let resolvedEndpoint: String
    let launchDate: Date
    let checkAccessibilityPermission: () -> Bool

    @State private var hasAccessibilityPermission = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GroupBox("起動時の設定") {
                    VStack(alignment: .leading, spacing: 8) {
                        statusRow("設定ファイル", configResult.configPath)
                        statusRow("設定ファイル種別", configResult.configSource.displayName)
                        statusRow("API Endpoint (設定)", displayValue(configResult.config.apiEndpoint))
                        statusRow("API Endpoint (実行時)", resolvedEndpoint)
                        statusRow("APIキー", maskedApiKey)
                        statusRow("APIキーソース", configResult.apiKeySource.displayName)
                        statusRow("OpenCode認証ファイル", configResult.openCodeAuthPath)
                        statusRow("デフォルトモデルProvider", displayValue(configResult.config.defaultModelProvider))
                        statusRow("デフォルトモデルID", displayValue(configResult.config.defaultModelID))
                        statusRow("送信時既定モデル", defaultModelLabel)
                        statusRow("セッションタイムアウト", "\(configResult.config.sessionTimeout) 秒")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("アプリ状態") {
                    VStack(alignment: .leading, spacing: 8) {
                        statusRow("起動時刻", formatDate(launchDate))
                        statusRow("処理状態", viewModel.isLoading ? "処理中" : "待機中")
                        statusRow("メッセージ数", "\(viewModel.messages.count)")
                        statusRow("未送信画像", pendingImageStatus)
                        statusRow("最後のエラー", errorMessageText, valueColor: errorMessageColor)
                        if let session = viewModel.currentSession {
                            statusRow("セッションID", session.id)
                            statusRow("セッションタイトル", displayValue(session.title))
                            statusRow("作成日時", formatDate(session.createdAt))
                            statusRow("更新日時", formatDate(session.updatedAt))
                            statusRow("プロジェクトID", displayValue(session.projectID))
                            statusRow("バージョン", displayValue(session.version))
                            statusRow("ディレクトリ", displayValue(session.directory))
                        } else {
                            statusRow("セッション", "未作成")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("ウィンドウ状態") {
                    VStack(alignment: .leading, spacing: 8) {
                        statusRow("チャットウィンドウ", windowManager.isChatWindowVisible ? "表示中" : "非表示")
                        statusRow("入力ランチャー", windowManager.isInputLauncherVisible ? "表示中" : "非表示")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("権限") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 12) {
                            Text("アクセシビリティ")
                                .foregroundColor(.secondary)
                                .frame(width: 160, alignment: .leading)
                            Text(hasAccessibilityPermission ? "許可" : "未許可")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Button("再確認") {
                                hasAccessibilityPermission = checkAccessibilityPermission()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("ログ") {
                    VStack(alignment: .leading, spacing: 8) {
                        statusRow("ログファイル", logStore.logFilePath())
                        statusRow("ログ件数", "\(logStore.entries.count)")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .textSelection(.enabled)
        }
        .frame(minWidth: 560, minHeight: 640)
        .onAppear {
            hasAccessibilityPermission = checkAccessibilityPermission()
        }
    }

    private func statusRow(_ title: String, _ value: String, valueColor: Color = .primary) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .foregroundColor(.secondary)
                .frame(width: 160, alignment: .leading)
            Text(value)
                .foregroundColor(valueColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func displayValue(_ value: String?) -> String {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "未設定" : trimmed
    }

    private var maskedApiKey: String {
        let key = configResult.config.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if key.isEmpty || key == "your-api-key-here" {
            return "未設定"
        }
        if key.count < 8 {
            return "設定済"
        }
        let suffix = key.suffix(4)
        return "設定済 (****\(suffix))"
    }

    private var defaultModelLabel: String {
        let provider = configResult.config.defaultModelProvider?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let model = configResult.config.defaultModelID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if provider.isEmpty || model.isEmpty {
            return "未指定 (サーバー既定)"
        }
        return "\(provider)/\(model)"
    }

    private var pendingImageStatus: String {
        guard let data = viewModel.pendingImageData else {
            return "なし"
        }
        return "あり (\(data.count) bytes)"
    }

    private var errorMessageText: String {
        let message = viewModel.errorMessage?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return message.isEmpty ? "なし" : message
    }

    private var errorMessageColor: Color {
        viewModel.errorMessage == nil ? .primary : .red
    }

    private func formatDate(_ date: Date) -> String {
        Self.dateFormatter.string(from: date)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}

private extension ConfigSource {
    var displayName: String {
        switch self {
        case .configFile:
            return ".config.json"
        case .legacyConfigFile:
            return ".opencodemenu.json"
        case .defaultPath:
            return "既定パス"
        }
    }
}

private extension ApiKeySource {
    var displayName: String {
        switch self {
        case .configFile:
            return "設定ファイル"
        case .openCodeAuth:
            return "OpenCode認証ファイル"
        case .missing:
            return "未設定"
        }
    }
}
