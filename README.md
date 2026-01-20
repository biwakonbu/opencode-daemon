# OpenCodeApp

OpenCode APIと連携するmacOSメニューバーアプリケーション

## 特徴

- 📸 スクリーンショットの取得と添付
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
- Shift+マウスドラッグで矩形選択
- 入力ランチャーが開き、スクリーンショットが添付された状態になります
- テキストあり/なしのどちらでも送信可能です
- 結果は会話ログに追加されます

#### Shift+ドラッグで矩形選択スクリーンショット

1. Shiftキーを押しながらマウスをドラッグ
2. 選択範囲を矩形で指定（最小50x50px）
3. マウスを離すとスクリーンショットが取得され、入力ランチャーが開きます
4. 必要に応じてテキストを入力して送信します（テキストなしでも送信可）
5. 結果は会話ログに追加されます
6. ESCキーで選択をキャンセル

**重要:** この機能を使用するには、以下の手順でアクセシビリティ権限を許可する必要があります：

1. システム環境設定 > プライバシーとセキュリティ > アクセシビリティ
2. 「OpenCodeMenuApp」または実行中のバイナリを探す
3. スイッチをオンにして許可

#### Mac操作の自動化

OpenCodeのAIにMac操作を依頼すると、AppleScript MCPサーバーを使用して自動化できます。

**例:**
```
「Chromeを開いてGoogleを表示して」
「FinderでDocumentsフォルダを開いて」
「System Eventsを使ってCommand+Sを押して」
```

**使用可能な操作:**
- アプリの起動・終了
- ウィンドウの操作
- メニューバー操作
- キーボード入力
- マウス操作
- テキストの入力

**権限管理:**
- 許可リストで実行するアプリを管理
- ドライランモードでコードを確認
- 実行前確認で安全に実行

詳細は `~/.config/opencode/mcp-servers/applescript-mcp-server/README.md` を参照してください。

#### グローバルキーボードショートカット

**Cmd+Shift+O**: チャットウィンドウの表示/非表示切り替え

**Cmd+Shift+I**: 入力ランチャーを表示

**Shift+マウスドラッグ**: 矩形選択スクリーンショット（入力ランチャーを表示）

**ESC**: 矩形選択キャンセル

#### メニューバーの右クリックメニュー

メニューバーアイコンをクリックすると以下のメニューが表示されます：

- **チャットウィンドウを表示** (Cmd+O): フローティングチャットウィンドウを表示
- **入力ランチャーを表示** (Cmd+I): 簡易入力ウィンドウを表示
- **再起動**: アプリケーションを再起動
- **終了** (Cmd+Q): アプリケーションを終了

#### フローティングチャットウィンドウ

独立したチャットウィンドウとして動作します：
- 340x600サイズ
- リサイズ可能
- フローティングレベルで最前面に表示
- 画面左側に配置

#### 入力ランチャー

クイック入力用の簡易ウィンドウ：
- 560x320サイズ
- 画面中央に表示
- メッセージ送信後自動クローズ
- キャンセルまたはEscでクローズ
- スクリーンショット添付時はテキストなしでも送信可能

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
