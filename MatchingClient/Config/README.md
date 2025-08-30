# 環境設定について

## 概要
このアプリケーションは開発・ステージング・本番の3つの環境をサポートしています。

## 環境の切り替え方法

### 方法1: Xcodeのスキーム設定（推奨）
1. Xcode上部のスキーム選択から「Edit Scheme...」を選択
2. Run > Info > Build Configuration を変更
   - Debug: 開発環境
   - Release: 本番環境

### 方法2: AppConfig.swift の編集
`AppConfig.swift`の`Environment.current`を直接編集することも可能ですが、推奨しません。

## 環境ごとの設定値

### 開発環境 (Development)
- API URL: `http://localhost/api`
- デバッグログ: 有効
- モックデータ: 使用可能

### 本番環境 (Production)
- API URL: `https://api.example.com/api`
- デバッグログ: 無効
- モックデータ: 使用不可

## xcconfig ファイルの使用

プロジェクトにxcconfigファイルを適用する手順：

1. Xcodeでプロジェクトファイルを選択
2. PROJECT > Info > Configurations
3. Debug設定に`Development.xcconfig`を適用
4. Release設定に`Production.xcconfig`を適用

## 本番環境へのデプロイ前チェックリスト

- [ ] API URLが本番環境を指している
- [ ] Pusher/SkyWayのキーが本番用になっている
- [ ] デバッグログが無効になっている
- [ ] クラッシュレポートツールが有効になっている