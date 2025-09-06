import Foundation

/// アプリケーションの設定を管理
enum AppConfig {
    /// 現在の環境
    enum Environment {
        case development
        case staging
        case production
        
        /// 現在の環境を取得
        ///
        /// - Note: デバッグビルドでは開発環境、リリースビルドでは本番環境を使用
        /// - Returns: 現在の環境
        static var current: Environment {
            #if DEBUG
            return .development
            #else
            return .production
            #endif
        }
    }
    
    /// API設定
    enum API {
        /// APIのベースURLを取得
        ///
        /// - Returns: 現在の環境に応じたベースURL
        static var baseURL: String {
            switch Environment.current {
            case .development:
                // WiFi環境内でアクセス可能なIPアドレスを使用
                // LaravelサーバーのIPアドレスとポートを指定
                // 実機テスト時は、MacのIPアドレスを使用
                return "http://192.168.0.63/api"
            case .staging:
                return "https://staging-api.example.com/api"
            case .production:
                return "https://api.example.com/api"
            }
        }
        
        /// APIタイムアウト（秒）
        static let timeoutInterval: TimeInterval = 30
        
        /// リトライ回数
        static let maxRetryCount = 3
    }
    
    /// Pusher設定
    enum Pusher {
        /// PusherのApp Key
        static var appKey: String {
            switch Environment.current {
            case .development:
                return "b0fe9b13ef0777c40743"  // 実際のPusher App Key
            case .staging:
                return "b0fe9b13ef0777c40743"
            case .production:
                return "b0fe9b13ef0777c40743"
            }
        }
        
        /// Pusherのクラスター
        static var cluster: String {
            return "ap3"  // 東京リージョン
        }
    }
    
    /// SkyWay設定
    enum SkyWay {
        /// SkyWayのApp ID
        static var appId: String {
            switch Environment.current {
            case .development:
                return "development_skyway_app_id"
            case .staging:
                return "staging_skyway_app_id"
            case .production:
                return "production_skyway_app_id"
            }
        }
        
        /// SkyWayのSecret Key
        ///
        /// - Warning: 本番環境ではサーバー側で認証トークンを生成することを推奨
        /// - Returns: Secret Keyまたはnil
        static var secretKey: String? {
            switch Environment.current {
            case .development:
                return "development_skyway_secret"
            case .staging, .production:
                return nil  // サーバー側で生成
            }
        }
        
        /// SkyWayのログレベル設定
        enum LogLevel: String {
            case error = "error"
            case warn = "warn"
            case info = "info"
            case debug = "debug"
            case trace = "trace"
        }
        
        /// 現在のログレベル
        ///
        /// - Note: 開発環境ではdebug、本番環境ではerrorレベルを使用
        /// - Returns: ログレベル
        static var logLevel: LogLevel {
            switch Environment.current {
            case .development:
                return .error  // 開発環境では詳細なログを出力
            case .staging:
                return .info   // ステージング環境では情報レベル
            case .production:
                return .error  // 本番環境ではエラーのみ
            }
        }
        
        /// ログ出力を有効にするか
        static var isLoggingEnabled: Bool {
            switch Environment.current {
            case .development:
                return true
            case .staging:
                return true
            case .production:
                return false  // 本番環境ではログ出力を無効化
            }
        }
    }
    
    /// アプリケーション設定
    enum App {
        /// アプリのバージョン
        static var version: String {
            Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        }
        
        /// ビルド番号
        static var buildNumber: String {
            Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        }
        
        /// バンドルID
        static var bundleId: String {
            Bundle.main.bundleIdentifier ?? "com.example.matchingclient"
        }
    }
}
