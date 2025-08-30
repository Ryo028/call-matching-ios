import Foundation

/// マッチング開始レスポンス
struct MatchingResponse: Codable {
    let user: User?  // マッチングしたユーザー（見つからない場合はnil）
    let roomId: String  // 通話ルームID（待機中またはマッチング成功時に生成）
    
    enum CodingKeys: String, CodingKey {
        case user
        case roomId = "room_id"
    }
}

/// マッチングステータス
enum MatchingStatus: String, Codable {
    case waiting = "waiting"
    case matched = "matched"
    case accepted = "accepted"
    case rejected = "rejected"
    case timeout = "timeout"
    case cancelled = "cancelled"
}

/// SkyWayトークンレスポンス
struct SkyWayTokenResponse: Codable {
    let skywayToken: String
    
    enum CodingKeys: String, CodingKey {
        case skywayToken = "skyway_token"
    }
}

/// マッチングアクションレスポンス
struct MatchingActionResponse: Codable {
    let isSuccess: Bool
    
    enum CodingKeys: String, CodingKey {
        case isSuccess = "is_success"
    }
}