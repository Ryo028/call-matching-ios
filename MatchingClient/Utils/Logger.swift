import Foundation

/// ログレベルの定義
///
/// ログの重要度に応じて分類されます。
enum LogLevel: String {
    case verbose = "📝 VERBOSE"
    case debug = "🔍 DEBUG"
    case info = "ℹ️ INFO"
    case warning = "⚠️ WARNING"
    case error = "❌ ERROR"
    
    /// ログレベルの優先度
    ///
    /// 数値が大きいほど重要度が高い
    var priority: Int {
        switch self {
        case .verbose: return 0
        case .debug: return 1
        case .info: return 2
        case .warning: return 3
        case .error: return 4
        }
    }
}

/// ログカテゴリの定義
///
/// ログの種類に応じて分類されます。
enum LogCategory: String {
    case api = "API"
    case auth = "AUTH"
    case ui = "UI"
    case database = "DB"
    case network = "NETWORK"
    case general = "GENERAL"
}

/// アプリケーション全体のログ出力を管理するクラス
///
/// デバッグビルド時のみログを出力し、本番環境では出力を抑制します。
/// ログレベルによるフィルタリングや、カテゴリ別の出力制御が可能です。
final class Logger {
    
    // MARK: - Properties
    
    /// シングルトンインスタンス
    static let shared = Logger()
    
    /// 現在の最小ログレベル
    ///
    /// この値以上の優先度を持つログのみが出力されます
    private var minimumLogLevel: LogLevel = .debug
    
    /// ログ出力の有効/無効
    private var isEnabled: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    /// タイムスタンプフォーマッター
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Configuration
    
    /// 最小ログレベルを設定
    ///
    /// - Parameter level: 出力する最小のログレベル
    func setMinimumLogLevel(_ level: LogLevel) {
        minimumLogLevel = level
    }
    
    // MARK: - Logging Methods
    
    /// 詳細ログを出力
    ///
    /// - Parameters:
    ///   - message: ログメッセージ
    ///   - category: ログカテゴリ
    ///   - file: ソースファイル名
    ///   - function: 関数名
    ///   - line: 行番号
    func verbose(
        _ message: String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .verbose, category: category, file: file, function: function, line: line)
    }
    
    /// デバッグログを出力
    ///
    /// - Parameters:
    ///   - message: ログメッセージ
    ///   - category: ログカテゴリ
    ///   - file: ソースファイル名
    ///   - function: 関数名
    ///   - line: 行番号
    func debug(
        _ message: String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }
    
    /// 情報ログを出力
    ///
    /// - Parameters:
    ///   - message: ログメッセージ
    ///   - category: ログカテゴリ
    ///   - file: ソースファイル名
    ///   - function: 関数名
    ///   - line: 行番号
    func info(
        _ message: String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }
    
    /// 警告ログを出力
    ///
    /// - Parameters:
    ///   - message: ログメッセージ
    ///   - category: ログカテゴリ
    ///   - file: ソースファイル名
    ///   - function: 関数名
    ///   - line: 行番号
    func warning(
        _ message: String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }
    
    /// エラーログを出力
    ///
    /// - Parameters:
    ///   - message: ログメッセージ
    ///   - category: ログカテゴリ
    ///   - file: ソースファイル名
    ///   - function: 関数名
    ///   - line: 行番号
    func error(
        _ message: String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }
    
    // MARK: - API Specific Logging
    
    /// APIリクエストのログを出力
    ///
    /// - Parameters:
    ///   - url: リクエストURL
    ///   - method: HTTPメソッド
    ///   - headers: HTTPヘッダー
    ///   - parameters: リクエストパラメータ
    func logAPIRequest(
        url: String,
        method: String,
        headers: [String: String]? = nil,
        parameters: Any? = nil
    ) {
        guard isEnabled else { return }
        
        var logMessage = "\n┌─── API REQUEST ───\n"
        logMessage += "│ URL: \(url)\n"
        logMessage += "│ Method: \(method)\n"
        
        if let headers = headers {
            logMessage += "│ Headers: \(headers)\n"
        }
        
        if let parameters = parameters {
            logMessage += "│ Parameters: \(parameters)\n"
        }
        
        logMessage += "└───────────────────"
        
        debug(logMessage, category: .api)
    }
    
    /// APIレスポンスのログを出力
    ///
    /// - Parameters:
    ///   - statusCode: HTTPステータスコード
    ///   - data: レスポンスデータ
    ///   - error: エラー情報
    ///   - decodedObject: デコードされたオブジェクト（オプション）
    func logAPIResponse<T: Encodable>(
        statusCode: Int? = nil,
        data: Data? = nil,
        error: Error? = nil,
        decodedObject: T? = nil
    ) {
        guard isEnabled else { return }
        
        var logMessage = "\n┌─── API RESPONSE ───\n"
        
        if let statusCode = statusCode {
            logMessage += "│ Status Code: \(statusCode)\n"
        }
        
        // 生のレスポンスデータを表示
        if let data = data,
           let responseString = String(data: data, encoding: .utf8) {
            // レスポンスが長すぎる場合は切り詰める
            let maxLength = 1000
            let truncatedResponse = responseString.count > maxLength 
                ? String(responseString.prefix(maxLength)) + "... (truncated)"
                : responseString
            logMessage += "│ Raw Response: \(truncatedResponse)\n"
        }
        
        // デコードされたオブジェクトを見やすいJSON形式で表示
        if let decodedObject = decodedObject {
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                encoder.dateEncodingStrategy = .iso8601
                
                let jsonData = try encoder.encode(decodedObject)
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    logMessage += "│\n│ ── Decoded Object ──\n"
                    // 各行にインデントを追加
                    let indentedJson = jsonString
                        .split(separator: "\n")
                        .map { "│   \($0)" }
                        .joined(separator: "\n")
                    logMessage += "\(indentedJson)\n"
                }
            } catch {
                logMessage += "│ Decoded Object: Failed to encode - \(error.localizedDescription)\n"
            }
        }
        
        if let error = error {
            logMessage += "│ Error: \(error.localizedDescription)\n"
        }
        
        logMessage += "└────────────────────"
        
        if error != nil {
            self.error(logMessage, category: .api)
        } else {
            debug(logMessage, category: .api)
        }
    }
    
    /// APIレスポンスのログを出力（非Encodableオブジェクト用）
    ///
    /// - Parameters:
    ///   - statusCode: HTTPステータスコード
    ///   - data: レスポンスデータ
    ///   - error: エラー情報
    func logAPIResponse(
        statusCode: Int? = nil,
        data: Data? = nil,
        error: Error? = nil
    ) {
        logAPIResponse(statusCode: statusCode, data: data, error: error, decodedObject: nil as String?)
    }
    
    /// APIアップロードのログを出力
    ///
    /// - Parameters:
    ///   - url: アップロードURL
    ///   - fileName: ファイル名
    ///   - mimeType: MIMEタイプ
    ///   - parameters: 追加パラメータ
    func logAPIUpload(
        url: String,
        fileName: String,
        mimeType: String,
        parameters: [String: String]? = nil
    ) {
        guard isEnabled else { return }
        
        var logMessage = "\n┌─── API UPLOAD ───\n"
        logMessage += "│ URL: \(url)\n"
        logMessage += "│ File: \(fileName)\n"
        logMessage += "│ MIME Type: \(mimeType)\n"
        
        if let parameters = parameters {
            logMessage += "│ Parameters: \(parameters)\n"
        }
        
        logMessage += "└──────────────────"
        
        debug(logMessage, category: .api)
    }
    
    // MARK: - Private Methods
    
    /// ログを出力する内部メソッド
    ///
    /// - Parameters:
    ///   - message: ログメッセージ
    ///   - level: ログレベル
    ///   - category: ログカテゴリ
    ///   - file: ソースファイル名
    ///   - function: 関数名
    ///   - line: 行番号
    private func log(
        _ message: String,
        level: LogLevel,
        category: LogCategory,
        file: String,
        function: String,
        line: Int
    ) {
        guard isEnabled else { return }
        guard level.priority >= minimumLogLevel.priority else { return }
        
        let timestamp = dateFormatter.string(from: Date())
        let fileName = (file as NSString).lastPathComponent
        
        let logMessage = "\(timestamp) \(level.rawValue) [\(category.rawValue)] \(fileName):\(line) \(function) - \(message)"
        
        print(logMessage)
    }
}

// MARK: - Convenience

/// グローバルログ関数（簡易アクセス用）
///
/// Logger.shared.debug() の代わりに Log.debug() で呼び出せます
struct Log {
    static func verbose(_ message: String, category: LogCategory = .general) {
        Logger.shared.verbose(message, category: category)
    }
    
    static func debug(_ message: String, category: LogCategory = .general) {
        Logger.shared.debug(message, category: category)
    }
    
    static func info(_ message: String, category: LogCategory = .general) {
        Logger.shared.info(message, category: category)
    }
    
    static func warning(_ message: String, category: LogCategory = .general) {
        Logger.shared.warning(message, category: category)
    }
    
    static func error(_ message: String, category: LogCategory = .general) {
        Logger.shared.error(message, category: category)
    }
}