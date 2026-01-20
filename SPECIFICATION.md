# 仕様書

OpenCodeMenuAppの技術仕様について説明します。

## バージョン

- バージョン: 1.0
- 更新日: 2026-01-20

## 概要

OpenCodeMenuAppはmacOSメニューバーで動作するOpenCode API連携アプリケーションです。スクリーンショットの自動取得、AIとの対話、Mac操作の自動化をサポートします。

## システム要件

- macOS 14.0 以降
- Swift 5.9 以降
- Xcode 15.0 以降（またはSwift Toolchain）
- アクセシビリティ権限（スクリーンショット機能に必要）

## アプリケーション構成

### アクティベーションポリシー

- **設定**: `.accessory`
- **説明**: メニューバーのみで動作、Dockアイコンは表示されない
- **影響**: ウィンドウ表示時に`NSApp.activate()`を呼び出してフォーカスを取得する必要がある

### メニューバー

- **アイコン**: macOSウィンドウアイコン（SF Symbol: "macwindow"）
- **位置**: システム時計の近く
- **動作**: クリックでコンテキストメニューを表示

### コンテキストメニュー

メニューバーアイコンをクリックすると以下のメニューが表示されます：

1. **チャットウィンドウを表示** (Cmd+O)
   - フローティングチャットウィンドウを表示
   - 既に表示されている場合は前面に表示

2. **入力ランチャーを表示** (Cmd+I)
   - 入力ランチャーウィンドウを表示

3. **再起動**
   - アプリケーションを再起動
   - `NSWorkspace.shared.openApplication(at:configuration:)`を使用

4. **終了** (Cmd+Q)
   - アプリケーションを終了

## ウィンドウ仕様

### フローティングチャットウィンドウ

- **ファイル名**: `FloatingChatWindow.swift`
- **サイズ**: 初期値 340x600ピクセル
- **リサイズ**: 可能（`.resizable`スタイル）
- **位置**: 画面左側（x: 20, y: 中央）
- **ウィンドウレベル**: `.floating`（最前面表示）
- **スタイル**: `.borderless`（タイトルバーなし）
- **背景色**: 透明（不透明度15%）
- **動作**:
  - 表示時に`NSApp.activate()`でアプリをアクティブ化
  - `.canJoinAllSpaces`で全スペースで表示
  - `.fullScreenAuxiliary`でフルスクリーン時に表示

**初期化**:
```swift
super.init(
    contentRect: NSRect(x: 20, y: 0, width: 340, height: 600),
    styleMask: [.borderless, .resizable],
    backing: .buffered,
    defer: false
)
```

**表示フロー**:
1. `WindowStateManager.showChatWindow()`が呼ばれる
2. `NSApp.activate(ignoringOtherApps: true)`でアプリをアクティブ化
3. `orderFrontRegardless()`でウィンドウを表示
4. `makeKey()`でキーボードフォーカスを取得

### 入力ランチャーウィンドウ

- **ファイル名**: `InputLauncherWindow.swift`
- **サイズ**: 560x240ピクセル
- **リサイズ**: 不可
- **位置**: 画面中央
- **ウィンドウレベル**: `.floating`（最前面表示）
- **スタイル**: `.borderless`（タイトルバーなし）
- **背景色**: 透明
- **動作**:
  - 表示時に`NSApp.activate()`でアプリをアクティブ化
  - 送信成功時に自動クローズ
  - キャンセルまたはESCでクローズ
  - テキストフィールドに自動フォーカス（`@FocusState`）

**初期化**:
```swift
super.init(
    contentRect: NSRect(x: 0, y: 0, width: 560, height: 240),
    styleMask: [.borderless],
    backing: .buffered,
    defer: false
)
```

**表示フロー**:
1. `WindowStateManager.showInputLauncher()`が呼ばれる
2. チャットウィンドウが表示中の場合は非表示にする
3. `NSApp.activate(ignoringOtherApps: true)`でアプリをアクティブ化
4. `orderFrontRegardless()`でウィンドウを表示
5. `makeKey()`でキーボードフォーカスを取得
6. SwiftUIの`@FocusState`でテキストフィールドにフォーカス

## グローバルショートカット

### ショートカット一覧

| ショートカット | 機能 |
|--------------|------|
| Cmd+Shift+O | チャットウィンドウの表示/非表示切り替え |
| Cmd+Shift+I | 入力ランチャーの表示 |
| Shift+マウスドラッグ | 矩形選択スクリーンショット開始 |
| ESC | 矩形選択キャンセル |

### 実装

- **ライブラリ**: HotKey (https://github.com/soffes/HotKey)
- **監視**: `GlobalShortcutMonitor`クラス

**チャットウィンドウショートカット**:
```swift
let chatKeyCombo = KeyCombo(key: .o, modifiers: [.command, .shift])
chatWindowHotKey = HotKey(keyCombo: chatKeyCombo)
chatWindowHotKey?.keyDownHandler = { [weak self] in
    self?.logStore.log("Cmd+Shift+O検出: チャットウィンドウ切り替え", category: "GlobalShortcut")
    DispatchQueue.main.async {
        self?.delegate?.didToggleChatWindow()
    }
}
```

**入力ランチャーショートカット**:
```swift
let inputKeyCombo = KeyCombo(key: .i, modifiers: [.command, .shift])
inputLauncherHotKey = HotKey(keyCombo: inputKeyCombo)
inputLauncherHotKey?.keyDownHandler = { [weak self] in
    self?.logStore.log("Cmd+Shift+I検出: 入力ランチャー表示", category: "GlobalShortcut")
    DispatchQueue.main.async {
        self?.delegate?.didShowInputLauncher()
    }
}
```

### アクセシビリティ権限

スクリーンショット（Shift+マウスドラッグ）機能を使用するには、アクセシビリティ権限が必要です。

**権限確認**:
```swift
let options: [String: Any] = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
```

**権限なしの場合の処理**:
- 起動時にアラートを表示
- システム環境設定へのパスを案内

## ウィンドウ状態管理

### WindowStateManager

- **ファイル名**: `WindowStateManager.swift`
- **パターン**: Singleton（`WindowStateManager.shared`）
- **アクター**: `@MainActor`

**責任**:
- フローティングチャットウィンドウの表示/非表示管理
- 入力ランチャーの表示/非表示管理
- ウィンドウ間の排他制御

**状態**:
```swift
@Published private(set) var isChatWindowVisible = false
```

**主要メソッド**:

1. `setup(viewModel:)` - ViewModelのセットアップ
2. `showChatWindow()` - チャットウィンドウを表示
3. `hideChatWindow()` - チャットウィンドウを非表示
4. `toggleChatWindow()` - チャットウィンドウの切り替え
5. `showInputLauncher()` - 入力ランチャーを表示
6. `hideInputLauncher()` - 入力ランチャーを非表示
7. `restartApp()` - アプリケーションを再起動

**排他制御**:
- 入力ランチャーを表示する際、チャットウィンドウが表示中の場合は非表示にする
- チャットウィンドウと入力ランチャーを同時に表示しない

## スクリーンショット機能

### 全体スクリーンショット

- **ファイル名**: `ScreenshotCapture.swift`
- **API**: `CGWindowListCreateImage`（非推奨、将来ScreenCaptureKitに移行予定）

**フロー**:
1. メインスクリーンのサイズを取得
2. `CGWindowListCreateImage`でキャプチャ
3. CGImageからNSImageへ変換
4. PNG形式でエンコード
5. Base64エンコード
6. OpenCode APIに送信

### 矩形選択スクリーンショット

- **ファイル名**: `ScreenshotRectCapture.swift`
- **オーバーレイ**: `ScreenSelectionOverlay.swift`

**フロー**:
1. Shiftキーが押されていることを確認
2. マウスダウンでオーバーレイを表示
3. マウスドラッグで矩形選択
4. マウスアップで選択範囲をキャプチャ
5. OpenCode APIに送信

**最小サイズ**: 50x50ピクセル

**キャンセル**:
- ESCキー
- 選択範囲が最小サイズ未満

## ログ機能

### RuntimeLogStore

- **ファイル名**: `RuntimeLogStore.swift`
- **ログファイル**: `~/github/chrome-to-opencode/opencode_app.log`
- **最大エントリ数**: 500

**ログレベル**:
- `info` - 通常の情報
- `warning` - 警告
- `error` - エラー

**ログフォーマット**:
```
2026-01-20 20:44:28.142 [INFO] [WindowManager] WindowStateManager初期化完了
```

**カテゴリ**:
- `App` - アプリケーション全般
- `Config` - 設定管理
- `WindowManager` - ウィンドウ管理
- `MenuBar` - メニューバー
- `GlobalShortcut` - グローバルショートカット
- `Capture` - スクリーンショット取得
- `Shortcut` - ショートカットコールバック
- `InputLauncherWindow` - 入力ランチャー
- `FloatingChatWindow` - フローティングチャットウィンドウ

## 再起動機能

### 実装方法

- **API**: `NSWorkspace.shared.openApplication(at:configuration:)`
- **完了ハンドラ**: 新しいインスタンス起動後に既存のプロセスを終了

**フロー**:
1. バンドルパスを取得
2. `NSWorkspace.shared.openApplication()`で新しいインスタンスを起動
3. 成功したら0.5秒待機
4. `NSApplication.shared.terminate()`で既存のプロセスを終了

**コード**:
```swift
let appUrl = URL(fileURLWithPath: appBundlePath)
let config = NSWorkspace.OpenConfiguration()
config.activates = true

NSWorkspace.shared.openApplication(at: appUrl, configuration: config) { app, error in
    if let error = error {
        RuntimeLogStore.shared.log("アプリ再起動エラー: \(error.localizedDescription)", level: .error, category: "WindowManager")
    } else {
        RuntimeLogStore.shared.log("アプリ起動成功", category: "WindowManager")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            RuntimeLogStore.shared.log("既存プロセスを終了します", category: "WindowManager")
            NSApplication.shared.terminate(nil)
        }
    }
}
```

## 既知の問題

1. **CGWindowListCreateImageの非推奨**
   - ステータス: 非推奨（macOS 14.0以降）
   - 影響: 現在は動作しているが、将来のバージョンで動作しなくなる可能性がある
   - 対策: ScreenCaptureKitへの移行が必要

2. **複数ディスプレイの部分的な対応**
   - ステータス: メインディスプレイのみ完全対応
   - 影響: 複数ディスプレイ環境でのスクリーンショットはメインディスプレイのみ
   - 対策: 将来的に全ディスプレイ対応を検討

3. **ショートカットがトリガーされない場合がある**
   - ステータス: 報告あり
   - 影響: Cmd+Shift+O/Iが反応しない場合がある
   - 対策: 原因調査中

## 将来の改善

### バージョン 1.1
- [ ] ScreenCaptureKitへの移行
- [ ] ユニットテストの追加
- [ ] ショートカット問題の修正

### バージョン 1.2
- [ ] 複数ディスプレイの完全対応
- [ ] 複数セッションの管理
- [ ] セッション履歴の保存

### バージョン 2.0
- [ ] 自動更新機能
- [ ] プラグインシステム
- [ ] テーマのカスタマイズ

## 参考ドキュメント

- [アーキテクチャ](ARCHITECTURE.md)
- [使用方法](USAGE.md)
- [設定方法](CONFIGURATION.md)
- [インストール手順](INSTALLATION.md)
- [開発ガイド](DEVELOPMENT.md)
