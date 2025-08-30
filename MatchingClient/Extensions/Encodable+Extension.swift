import Foundation

/// Encodableプロトコルの拡張
extension Encodable {
    /// オブジェクトをDictionaryに変換
    ///
    /// - Returns: [String: Any]形式のDictionary
    /// - Throws: エンコードエラー
    func toDictionary() throws -> [String: Any]? {
        let data = try JSONEncoder().encode(self)
        return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    }
}