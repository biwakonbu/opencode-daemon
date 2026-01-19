# OpenCodeApp

OpenCode APIと連携するmacOSメニューバーアプリケーション

## 特徴

- 📸 スクリーンショットの自動取得
- 💬 OpenCode APIとのメッセージ送受信
- 🔄 セッション管理
- 🍎 Swift 5.9+ / macOS 14+
- 🎯 メニューバーアプリとして動作

## 必要条件

- macOS 14.0 以降
- Swift 5.9 以降
- Xcode 15.0 以降（またはSwift Toolchain）

## クイックスタート

### 1. ビルド

```bash
swift build
```

### 2. 設定

`.config.json`にAPIキーを設定します：

```json
{
  "apiKey": "your-opencode-api-key",
  "apiEndpoint": "https://api.opencode.ai",
  "sessionTimeout": 3600
}
```

### 3. 実行

```bash
./.build/arm64-apple-macosx/debug/OpenCodeApp
```

またはデバッグビルド：

```bash
swift run
```

## 使用方法

### メニューバーアプリの操作

1. メニューバーのアイコンをクリック
2. ポップアップが開きます

### 主要機能

#### セッションの作成
- 「セッション作成」ボタンをクリック
- 新しいセッションが作成され、チャットが開始されます

#### メッセージの送信
- テキストフィールドにメッセージを入力
- Enterキーまたは「送信」ボタンをクリック
- OpenCode APIにメッセージが送信されます

#### スクリーンショットの取得と送信
- カメラアイコン（📷）をクリック
- 現在の画面がキャプチャされます
- 自動的にOpenCode APIに送信されます

## ディレクトリ構成

```
Sources/
├── App/
│   ├── AppDelegate.swift          # アプリデリゲート
│   └── MenuBarManager.swift       # メニューバー管理
├── Models/
│   ├── Config.swift              # 設定モデル
│   ├── OpenCodeMessage.swift     # メッセージモデル
│   └── OpenCodeSession.swift     # セッションモデル
├── Services/
│   ├── ConfigManager.swift       # 設定ファイル管理
│   ├── OpenCodeAPIClient.swift   # APIクライアント
│   └── ScreenshotCapture.swift   # スクリーンショット取得
├── ViewModels/
│   └── OpenCodeViewModel.swift   # ビューモデル
├── Views/
│   └── ContentView.swift         # メインビュー
└── OpenCodeApp.swift             # エントリーポイント
```

## 既知の問題

- CGWindowListCreateImageは非推奨（将来バージョンでScreenCaptureKitに移行予定）
- `.config.json`は.gitignoreに含まれているため、手動で設定が必要

## セキュリティ

- APIキーは`.config.json`に保存されます（Gitにはコミットされません）
- APIキーは機密情報のため、共有しないでください
- `.config.json`は`.gitignore`に含まれています

## 詳細ドキュメント

- [アーキテクチャ](ARCHITECTURE.md)
- [インストール手順](INSTALLATION.md)
- [設定方法](CONFIGURATION.md)
- [使用方法](USAGE.md)
- [開発ガイド](DEVELOPMENT.md)

## ライセンス

MIT License

## 貢献

プルリクエストを歓迎します。詳細は[開発ガイド](DEVELOPMENT.md)を参照してください。
