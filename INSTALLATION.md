# Installation

OpenCodeAppのインストール手順とトラブルシューティング。

## 事前要件

### 必要なソフトウェア

- **macOS**: 14.0 以降
- **Swift**: 5.9 以降
- **Xcode**: 15.0 以降（またはSwift Toolchain）

### インストール確認

ターミナルで以下のコマンドを実行してバージョンを確認します：

```bash
# macOSバージョン
sw_vers

# Swiftバージョン
swift --version

# Xcodeバージョン（インストールされている場合）
xcodebuild -version
```

### Xcodeのインストール

Xcodeがインストールされていない場合：

1. Mac App StoreからXcodeを検索
2. Xcodeをダウンロードしてインストール
3. 初回起動時のライセンス同意が必要

または、Command Line Toolsのみをインストール：

```bash
xcode-select --install
```

## 依存関係のインストール

OpenCodeAppはSwift Package Manager（SPM）を使用しており、依存関係は自動的にインストールされます。

### 手動での依存関係インストール

```bash
# 依存関係のフェッチ
swift package resolve

# ビルド時に依存関係が自動でインストールされます
swift build
```

### インストールされる依存関係

- **KeychainAccess** (4.2.2+): セキュアなキーストレージアクセス

## ビルド手順

### 1. プロジェクトのクローン（まだの場合）

```bash
git clone <repository-url>
cd chrome-to-opencode
```

### 2. 設定ファイルの作成

`.config.json`を作成して、APIキーを設定します：

```bash
cp .config.json.template .config.json
# または手動で作成
```

`.config.json`の内容：

```json
{
  "apiKey": "your-opencode-api-key",
  "apiEndpoint": "https://api.opencode.ai",
  "sessionTimeout": 3600
}
```

### 3. ビルド

```bash
swift build
```

ビルドが成功すると、以下の場所に実行ファイルが生成されます：

```
.build/arm64-apple-macosx/debug/OpenCodeApp
```

### 4. 実行

```bash
./.build/arm64-apple-macosx/debug/OpenCodeApp
```

または、`swift run`コマンドを使用：

```bash
swift run
```

## リリースビルド

リリース用の最適化されたバイナリを作成する場合：

```bash
swift build -c release
```

実行ファイルの場所：

```
.build/arm64-apple-macosx/release/OpenCodeApp
```

## アプリケーションのインストール

### 実行ファイルの移動

ビルドした実行ファイルを任意の場所に移動できます：

```bash
cp .build/arm64-apple-macosx/release/OpenCodeApp ~/Applications/
```

### 自動起動の設定

ログイン時に自動起動させる場合：

1. システム環境設定 → ユーザーとグループ → ログイン項目
2. 「+」ボタンをクリック
3. `OpenCodeApp`を選択

または、コマンドラインで設定：

```bash
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Users/$(whoami)/Applications/OpenCodeApp", hidden:false}'
```

## トラブルシューティング

### ビルドエラー

#### エラー: "Cannot find 'AppDelegate' in scope"

**原因**: `OpenCodeApp.swift`で`AppDelegate`が見つからない

**解決策**:
1. `Package.swift`のターゲット設定を確認
2. `OpenCodeAppCore`ターゲットが正しく設定されているか確認

```bash
swift package dump-package | grep -A 20 targets
```

#### エラー: "Module 'OpenCodeAppCore' not found"

**原因**: `OpenCodeAppCore`モジュールがビルドされていない

**解決策**:
```bash
# クリーンビルド
swift package clean
swift build
```

#### エラー: "No such module 'KeychainAccess'"

**原因**: 依存関係が正しくインストールされていない

**解決策**:
```bash
# 依存関係を再フェッチ
rm -rf .build
swift package resolve
swift build
```

### 実行時エラー

#### エラー: "アプリケーションの初期化に失敗しました"

**原因**: `.config.json`が見つからない、または形式が正しくない

**解決策**:
1. `.config.json`がプロジェクトルートにあるか確認
2. JSON形式が正しいか確認
3. APIキーが正しく設定されているか確認

```bash
# JSONのバリデーション
cat .config.json | python3 -m json.tool
# または
cat .config.json | jq
```

#### エラー: "認証に失敗しました"

**原因**: APIキーが無効または期限切れ

**解決策**:
1. APIキーが正しいか確認
2. OpenCodeで新しいAPIキーを取得
3. `.config.json`の`apiKey`を更新

#### エラー: "メインスクリーンが見つかりません"

**原因**: macOSの画面設定に問題がある

**解決策**:
1. メイン画面が接続されているか確認
2. macOSの設定 → ディスプレイで確認

### パーミッションエラー

#### エラー: "Permission denied"

**原因**: 実行ファイルに実行権限がない

**解決策**:
```bash
chmod +x .build/arm64-apple-macosx/debug/OpenCodeApp
```

### ネットワークエラー

#### エラー: "サーバーエラー (ステータスコード: xxx)"

**原因**: APIサーバーへの接続問題

**解決策**:
1. インターネット接続を確認
2. APIエンドポイントが正しいか確認
3. OpenCode APIのステータスを確認

### スクリーンショットエラー

#### エラー: "スクリーンショットの取得に失敗しました"

**原因**: システム権限またはAPIの問題

**解決策**:
1. macOSのプライバシー設定でスクリーンショット権限を確認
2. CGWindowListCreateImageが非推奨であるため、将来バージョンで修正予定

## 開発環境の設定

### Xcodeプロジェクトの生成

Xcodeで開発したい場合：

```bash
swift package generate-xcodeproj
```

生成されたプロジェクトを開く：

```bash
open OpenCodeApp.xcodeproj
```

### VSCodeの設定

`.vscode/settings.json`を作成：

```json
{
  "swift.path": "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift",
  "swift.diagnostics": true,
  "swift.buildPath": "${workspaceFolder}/.build/debug"
}
```

### 拡張機能のインストール

VSCodeの場合、以下の拡張機能を推奨：

- Swift Language Extension
- CodeLLDB (デバッガー)

## クリーンアップ

### ビルド成果物の削除

```bash
# ビルド成果物のみ削除
swift package clean

# 依存関係も含めてクリーン
rm -rf .build
```

### 依存関係のキャッシュ削除

```bash
# Swift Package Managerのキャッシュを削除
rm -rf ~/Library/Caches/org.swift.swiftpm/
```

## 次のステップ

インストールが完了したら：

1. [設定方法](CONFIGURATION.md)を確認してAPIキーを設定
2. [使用方法](USAGE.md)を参照してアプリケーションの使い方を学ぶ
3. [開発ガイド](DEVELOPMENT.md)で開発環境のセットアップ
