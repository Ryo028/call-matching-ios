import Foundation

extension DateFormatter {
    
    /// Laravel APIからの日付文字列をパースするための共通DateFormatter
    static let laravelDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    /// ISO8601形式の日付文字列をパース（マイクロ秒付き）
    /// 例: "2025-08-24T13:59:35.000000Z"
    static func dateFromLaravelISO8601(_ string: String) -> Date? {
        laravelDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        return laravelDateFormatter.date(from: string)
    }
    
    /// シンプルな日付時刻形式の文字列をパース
    /// 例: "2025-08-24 13:59:35"
    static func dateFromLaravelDateTime(_ string: String) -> Date? {
        laravelDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return laravelDateFormatter.date(from: string)
    }
    
    /// Laravel APIからの日付文字列を自動判定してパース
    /// 複数のフォーマットを試して、最初に成功したものを返す
    static func dateFromLaravelString(_ string: String) -> Date? {
        // まずシンプルな形式を試す
        if let date = dateFromLaravelDateTime(string) {
            return date
        }
        
        // 次にISO8601形式を試す
        if let date = dateFromLaravelISO8601(string) {
            return date
        }
        
        // ISO8601標準デコーダーも試す
        if let date = ISO8601DateFormatter().date(from: string) {
            return date
        }
        
        return nil
    }
}

/// JSONDecoderの拡張（Laravel API用の設定）
extension JSONDecoder {
    
    /// Laravel API用に設定されたJSONDecoder
    static let laravelDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        
        // カスタム日付デコード戦略
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            
            // まず文字列として取得を試みる
            if let dateString = try? container.decode(String.self) {
                if let date = DateFormatter.dateFromLaravelString(dateString) {
                    return date
                }
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Cannot decode date string: \(dateString)"
                )
            }
            
            // TimeInterval（Unix timestamp）として取得を試みる
            if let timestamp = try? container.decode(Double.self) {
                return Date(timeIntervalSince1970: timestamp)
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date"
            )
        }
        
        return decoder
    }()
}