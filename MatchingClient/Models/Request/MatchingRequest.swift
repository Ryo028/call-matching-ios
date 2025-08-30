import Foundation

/// マッチング開始リクエスト
struct StartMatchingRequest: Codable {
    let genderType: Int  // 必須: 0=指定なし, 1=男性, 2=女性
    let ageMin: Int
    let ageMax: Int
    let distance: Int
    
    enum CodingKeys: String, CodingKey {
        case genderType = "gender_type"
        case ageMin = "age_min"
        case ageMax = "age_max"
        case distance
    }
}

/// マッチング承認/拒否リクエスト
struct MatchingActionRequest: Codable {
    let roomId: String
    
    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
    }
}