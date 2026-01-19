# Development Guide

OpenCodeAppの開発環境のセットアップ、コーディング規約、テスト方法について説明します。

## 開発環境のセットアップ

### 事前要件

- macOS 14.0 以降
- Swift 5.9 以降
- Xcode 15.0 以降
- Git

### 推奨ツール

#### エディター

- **Xcode**: 推奨（完全なサポート）
- **VSCode**: Swift Language Extensionで対応
- **Vim/Neovim**: coc-swiftなどのプラグインが必要

#### その他のツール

- **swift-format**: コードフォーマット
- **swiftlint**: コード静的解析
- **jq**: JSON処理（設定ファイルの検証）

### Xcodeプロジェクトの生成

```bash
swift package generate-xcodeproj
```

生成されたプロジェクトを開く：

```bash
open OpenCodeApp.xcodeproj
```

または、Xcodeから直接パッケージを開く：

```bash
xed .
```

### VSCodeの設定

#### 拡張機能のインストール

- Swift Language Extension
- CodeLLDB (デバッガー)
- SwiftLint (コード解析)

#### settings.json

```json
{
  "swift.path": "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift",
  "swift.diagnostics": true,
  "swift.buildPath": "${workspaceFolder}/.build/debug",
  "files.exclude": {
    "**/.build": true,
    "**/.swiftpm": true
  }
}
```

### ツールのインストール

```bash
# SwiftLint (Homebrew)
brew install swiftlint

# SwiftFormat (Mint)
mint install nicklockwood/SwiftFormat

# jq (JSON処理)
brew install jq
```

## プロジェクト構成

### ディレクトリ構造

```
chrome-to-opencode/
├── Sources/
│   ├── App/
│   │   ├── AppDelegate.swift
│   │   └── MenuBarManager.swift
│   ├── Models/
│   │   ├── Config.swift
│   │   ├── OpenCodeMessage.swift
│   │   └── OpenCodeSession.swift
│   ├── Services/
│   │   ├── ConfigManager.swift
│   │   ├── OpenCodeAPIClient.swift
│   │   └── ScreenshotCapture.swift
│   ├── ViewModels/
│   │   └── OpenCodeViewModel.swift
│   ├── Views/
│   │   └── ContentView.swift
│   └── OpenCodeApp.swift
├── Package.swift
├── .config.json
├── .gitignore
├── README.md
├── ARCHITECTURE.md
├── INSTALLATION.md
├── CONFIGURATION.md
├── USAGE.md
└── DEVELOPMENT.md
```

### 各ディレクトリの役割

- **App/**: アプリケーション全体の初期化とライフサイクル管理
- **Models/**: データモデルと構造体
- **Services/**: 外部API連携とデータ処理
- **ViewModels/**: ビジネスロジックと状態管理
- **Views/**: ユーザーインターフェース

## コーディング規約

### Swiftの規約

#### 命名規則

- **クラス/構造体**: PascalCase (例: `OpenCodeViewModel`)
- **プロパティ/メソッド**: camelCase (例: `sendMessage()`)
- **定数**: lowerCamelCase (例: `let apiKey`)
- **列挙型**: PascalCase (例: `APIError`)

```swift
class OpenCodeViewModel {
    private var apiClient: OpenCodeAPIClient
    let maxRetries = 3
    
    enum APIError {
        case unauthorized
        case serverError
    }
}
```

#### プロトコル準拠

適切なプロトコルに準拠します：

```swift
// データモデル
struct OpenCodeSession: Codable, Identifiable {
    let id: String
    var isActive: Bool
}

// ビューモデル
@MainActor
class OpenCodeViewModel: ObservableObject {
    @Published var messages: [OpenCodeMessage] = []
}

// サービス
class OpenCodeAPIClient {
    // 特定のプロトコル準拠は不要だが、必要に応じて追加
}
```

#### アクセス修飾子

```swift
// public: 外部からアクセス可能
public class AppDelegate {
    
    // internal (デフォルト): 同じモジュール内からアクセス可能
    class StatusBar {
        
        // private: 同じファイル内からのみアクセス可能
        private var statusItem: NSStatusItem?
        
        // fileprivate: 同じファイル内からのみアクセス可能
        fileprivate var popover: NSPopover?
    }
}
```

### SwiftUIの規約

#### Viewの定義

```swift
struct ContentView: View {
    @ObservedObject var viewModel: OpenCodeViewModel
    
    var body: some View {
        VStack {
            // UIコンポーネント
        }
        .frame(width: 400, height: 500)
    }
}
```

#### Modifierの順序

1. レイアウト（`.frame()`, `.padding()`）
2. スタイル（`.background()`, `.foregroundColor()`）
3. イベント（`.onTapGesture()`, `.onSubmit()`）
4. 修飾子（`.disabled()`, `.animation()`）

```swift
Text("Hello")
    .padding(10)
    .background(Color.blue)
    .foregroundColor(.white)
    .cornerRadius(10)
    .onTapGesture {
        // タップアクション
    }
    .disabled(isLoading)
```

### 非同期処理

#### async/awaitの使用

```swift
func sendMessage() async throws {
    isLoading = true
    errorMessage = nil
    
    do {
        let response = try await apiClient.sendMessage(request)
        // レスポンス処理
    } catch {
        errorMessage = error.localizedDescription
    }
    
    isLoading = false
}
```

#### Taskの使用

```swift
Button(action: {
    Task {
        await viewModel.sendMessage()
    }
}) {
    Text("送信")
}
```

### エラーハンドリング

#### カスタムエラーの定義

```swift
enum APIError: LocalizedError {
    case missingConfig
    case unauthorized
    case serverError(statusCode: Int)
    
    var errorDescription: String? {
        switch self {
        case .missingConfig:
            return "設定が見つかりません"
        case .unauthorized:
            return "認証に失敗しました"
        case .serverError(let code):
            return "サーバーエラー (ステータスコード: \(code))"
        }
    }
}
```

## テスト方法

### ユニットテスト

現在のバージョンでは、ユニットテストは実装されていません。

### 手動テスト

#### ビルドテスト

```bash
# デバッグビルド
swift build

# リリースビルド
swift build -c release
```

#### 実行テスト

```bash
# アプリケーションを実行
swift run

# スクリーンショットのキャプチャ
screencapture -x screenshot.png
```

#### 統合テスト

1. アプリケーションを起動
2. セッションを作成
3. メッセージを送信
4. スクリーンショットを送信
5. レスポンスを確認

## デバッグ方法

### Xcodeでのデバッグ

1. Xcodeでプロジェクトを開く
2. ブレイクポイントを設定
3. 実行ボタン（▶）をクリック
4. 変数の値を確認

### コンソールログの使用

```swift
print("Debug: \(message)")

// より詳細な情報
debugPrint("Object: \(object)")
```

### エラーログの確認

```bash
# 標準出力をログファイルに保存
swift run 2>&1 | tee app.log

# ログを監視
tail -f app.log
```

### LLDBの使用

```bash
# デバッガーを起動
lldb ./OpenCodeApp

# ブレイクポイントを設定
(lldb) breakpoint set --name sendMessage

# 実行
(lldb) run

# 変数を表示
(lldb) print message
```

## コードの品質管理

### SwiftLint

```bash
# SwiftLintの実行
swiftlint

# 自動修正
swiftlint --fix

# 特定のファイルのチェック
swiftlint lint --path Sources/Models/Config.swift
```

### SwiftFormat

```bash
# コードのフォーマット
swift format Sources/

# 特定のファイル
swift format Sources/App/AppDelegate.swift
```

### ビルド時の警告を修正

```bash
# 警告を確認して修正
swift build 2>&1 | grep warning
```

## パフォーマンスの最適化

### ビルドの最適化

```bash
# リリースビルド（最適化あり）
swift build -c release

# ビルド時間の短縮
swift build --verbose
```

### メモリ使用量の確認

```bash
# Instrumentsでプロファイル
instruments -t "Allocations" ./OpenCodeApp

# コマンドラインでの確認
ps aux | grep OpenCodeApp
```

### 起動時間の測定

```bash
# 起動時間の測定
time swift run
```

## 貢献方法

### ブランチ戦略

- `main`: 安定版
- `develop`: 開発版
- `feature/*`: 新機能
- `bugfix/*`: バグ修正
- `hotfix/*`: 緊急修正

### プルリクエストの手順

1. フォークする
2. フィーチャーブランチを作成
3. 変更をコミット
4. ブランチをプッシュ
5. プルリクエストを作成

#### コミットメッセージの規約

```
<type>(<scope>): <subject>

<body>

<footer>
```

**type**:
- `feat`: 新機能
- `fix`: バグ修正
- `docs`: ドキュメント
- `style`: コードスタイル
- `refactor`: リファクタリング
- `test`: テスト
- `chore`: その他

**例**:
```
feat(api): スクリーンショット送信機能を追加

- ScreenshotCaptureサービスを実装
- Base64エンコードロジックを追加

Closes #123
```

### コードレビュー

- コードレビューは必須
- 少なくとも1人の承認が必要
- CI/CDパスが必須

## リリースプロセス

### バージョン管理

- セマンティックバージョニング（SemVer）を使用
- `MAJOR.MINOR.PATCH`
- 例: `1.0.0`

### リリース手順

1. バージョンを更新
2. CHANGELOGを更新
3. タグを作成
4. リリースノートを作成
5. GitHub Releaseを作成

```bash
# タグの作成
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

## トラブルシューティング

### 開発環境の問題

#### Xcodeが見つからない

```bash
# Xcodeのツールチェーンを設定
sudo xcode-select --switch /Applications/Xcode.app
```

#### Swiftのバージョン不一致

```bash
# Swiftのバージョンを確認
swift --version

# 必要に応じてXcodeを更新
```

### ビルドの問題

#### 依存関係のエラー

```bash
# ビルド成果物を削除して再ビルド
swift package clean
swift build
```

#### リンクエラー

```bash
# クリーンビルド
rm -rf .build
swift build
```

## 次のステップ

開発環境がセットアップできたら：

1. [アーキテクチャ](ARCHITECTURE.md)で内部設計を理解する
2. [使用方法](USAGE.md)でアプリケーションの動作を確認
3. 既存の問題を確認して貢献を開始
