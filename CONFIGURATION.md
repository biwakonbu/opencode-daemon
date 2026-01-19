# Configuration

OpenCodeAppの設定方法について説明します。

## 設定ファイルの概要

OpenCodeAppは`.config.json`ファイルで設定を管理します。このファイルにはAPIキー、エンドポイント、セッション設定などが含まれます。

### 設定ファイルの場所

設定ファイルはプロジェクトのルートディレクトリに配置されます：

```
chrome-to-opencode/
└── .config.json
```

**重要**: `.config.json`は`.gitignore`に含まれており、Gitリポジトリにはコミットされません。これはAPIキー等の機密情報を保護するためです。

## 設定ファイルの構造

### テンプレート

`.config.json`の基本的な構造：

```json
{
  "apiKey": "your-opencode-api-key",
  "apiEndpoint": "https://api.opencode.ai",
  "sessionTimeout": 3600
}
```

### 各設定項目の説明

#### apiKey

**必須**: はい  
**型**: String  
**説明**: OpenCode APIの認証キー

**例**:
```json
{
  "apiKey": "sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
}
```

**取得方法**:
1. OpenCodeアカウントにログイン
2. APIキー管理ページにアクセス
3. 新しいAPIキーを生成
4. キーをコピーして`.config.json`に貼り付け

**セキュリティのヒント**:
- APIキーは機密情報として扱ってください
- キーを共有しないでください
- 定期的にキーを更新することを推奨

#### apiEndpoint

**必須**: はい  
**型**: String  
**説明**: OpenCode APIのエンドポイントURL

**デフォルト値**: `https://api.opencode.ai`

**例**:
```json
{
  "apiEndpoint": "https://api.opencode.ai"
}
```

**カスタムエンドポイント**:
独自のOpenCodeインスタンスを使用する場合、カスタムエンドポイントを設定できます：

```json
{
  "apiEndpoint": "https://your-custom-opencode.com/api"
}
```

#### sessionTimeout

**必須**: いいえ  
**型**: Int  
**単位**: 秒  
**デフォルト値**: `3600` (1時間)  
**説明**: セッションのタイムアウト時間

**例**:
```json
{
  "sessionTimeout": 7200
}
```

**推奨値**:
- `1800` (30分) - 短いセッション
- `3600` (1時間) - 標準
- `7200` (2時間) - 長いセッション
- `86400` (24時間) - 1日間有効

## APIキーの設定方法

### ステップ1: APIキーの取得

1. OpenCodeのウェブサイトにアクセス
2. アカウントにログイン
3. 設定 → APIキー管理に移動
4. 「新しいAPIキーを作成」をクリック
5. キー名を入力（例: "Mac Desktop App"）
6. キーをコピー

### ステップ2: 設定ファイルの作成

プロジェクトのルートディレクトリに`.config.json`を作成：

```bash
touch .config.json
```

### ステップ3: APIキーの入力

`.config.json`を編集してAPIキーを入力：

```json
{
  "apiKey": "sk-your-actual-api-key-here",
  "apiEndpoint": "https://api.opencode.ai",
  "sessionTimeout": 3600
}
```

### ステップ4: 設定の検証

設定ファイルが正しいか検証：

```bash
# jqを使用してJSONバリデーション
cat .config.json | jq
```

または、Pythonを使用：

```bash
cat .config.json | python3 -m json.tool
```

## 環境変数の使用

現在のバージョンでは`.config.json`ファイルを使用していますが、将来のバージョンでは環境変数をサポートする予定です。

### 将来的な環境変数対応（計画中）

```bash
export OPENCODE_API_KEY="sk-your-api-key"
export OPENCODE_API_ENDPOINT="https://api.opencode.ai"
export OPENCODE_SESSION_TIMEOUT=3600
```

## セキュリティのベストプラクティス

### APIキーの保護

1. **`.gitignore`に含める**
   - `.config.json`は`.gitignore`に含まれています
   - 絶対にGitリポジトリにコミットしないでください

2. **ファイル権限の設定**
   ```bash
   chmod 600 .config.json
   ```

3. **キーの共有を避ける**
   - APIキーをチャットやメールで共有しないでください
   - 公開リポジトリにコミットしないでください

### APIキーのローテーション

定期的にAPIキーを更新することを推奨します：

1. 古いキーを無効化
2. 新しいキーを生成
3. `.config.json`を更新
4. アプリケーションを再起動

### 設定ファイルのバックアップ

設定ファイルのバックアップを作成する場合：

```bash
# 暗号化されたバックアップ
gpg -c .config.json
# => .config.json.gpg

# 復元
gpg -d .config.json.gpg > .config.json
```

## 設定のバリデーション

### JSON構造のチェック

```bash
# jqがインストールされている場合
jq empty .config.json && echo "Valid JSON" || echo "Invalid JSON"
```

### 必須フィールドのチェック

```bash
# APIキーが含まれているか確認
jq -e '.apiKey' .config.json >/dev/null 2>&1 && echo "API key found" || echo "API key missing"

# APIエンドポイントが含まれているか確認
jq -e '.apiEndpoint' .config.json >/dev/null 2>&1 && echo "API endpoint found" || echo "API endpoint missing"
```

### アプリケーションでのバリデーション

アプリケーション起動時に設定が検証されます：

```
✓ APIキー: 有効
✓ APIエンドポイント: 有効
✓ セッションタイムアウト: 有効
```

設定に問題がある場合、アラートが表示されます。

## 設定の更新方法

### APIキーの更新

1. `.config.json`を開く
2. `apiKey`フィールドの値を更新
3. 保存
4. アプリケーションを再起動

### APIエンドポイントの更新

1. `.config.json`を開く
2. `apiEndpoint`フィールドの値を更新
3. 保存
4. アプリケーションを再起動

### セッションタイムアウトの更新

1. `.config.json`を開く
2. `sessionTimeout`フィールドの値を更新（秒単位）
3. 保存
4. アプリケーションを再起動

## 設定ファイルの例

### 開発環境

```json
{
  "apiKey": "sk-dev-xxxxxxxxxxxxxxxxxxxxxxxx",
  "apiEndpoint": "https://dev-api.opencode.ai",
  "sessionTimeout": 1800
}
```

### 本番環境

```json
{
  "apiKey": "sk-prod-xxxxxxxxxxxxxxxxxxxxxxxx",
  "apiEndpoint": "https://api.opencode.ai",
  "sessionTimeout": 3600
}
```

### カスタムインスタンス

```json
{
  "apiKey": "sk-custom-xxxxxxxxxxxxxxxxxxxxxxxx",
  "apiEndpoint": "https://custom-opencode.example.com/api",
  "sessionTimeout": 7200
}
```

## 設定のトラブルシューティング

### 設定ファイルが見つからない

**エラーメッセージ**: "設定が見つかりません"

**解決策**:
1. `.config.json`がプロジェクトルートにあるか確認
2. ファイル名が正しいか確認（先頭のドットを忘れない）
3. ファイルのパーミッションを確認

```bash
ls -la .config.json
```

### JSON構造エラー

**エラーメッセージ**: "設定ファイルの読み込みに失敗しました"

**解決策**:
1. JSON構造を検証
2. 不要なカンマや引用符がないか確認
3. UTF-8エンコーディングであるか確認

```bash
file .config.json
# => .config.json: UTF-8 Unicode text
```

### APIキーの検証エラー

**エラーメッセージ**: "認証に失敗しました"

**解決策**:
1. APIキーが正しいか確認
2. APIキーの有効期限を確認
3. OpenCodeのアカウント状態を確認

## 高度な設定

### 設定ファイルの複数使用

異なる環境で異なる設定を使用する場合：

```bash
# 開発用
cp .config.dev.json .config.json

# 本番用
cp .config.prod.json .config.json
```

### 設定ファイルのスクリプト化

設定の切り替えを自動化：

```bash
#!/bin/bash
# switch-config.sh

if [ "$1" == "dev" ]; then
    cp .config.dev.json .config.json
    echo "Development environment activated"
elif [ "$1" == "prod" ]; then
    cp .config.prod.json .config.json
    echo "Production environment activated"
else
    echo "Usage: ./switch-config.sh [dev|prod]"
fi
```

使用方法：

```bash
chmod +x switch-config.sh
./switch-config.sh dev
```

## 次のステップ

設定が完了したら：

1. [インストール手順](INSTALLATION.md)を確認してビルド方法を学ぶ
2. [使用方法](USAGE.md)を参照してアプリケーションの使い方を学ぶ
3. [アーキテクチャ](ARCHITECTURE.md)で内部設計を理解する
