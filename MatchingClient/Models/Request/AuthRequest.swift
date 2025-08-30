import Foundation

/// ログインリクエスト
struct LoginRequest: Codable {
    let email: String
    let password: String
    let deviceId: String?  // オプショナル（サーバー側で必須でない場合）
    
    enum CodingKeys: String, CodingKey {
        case email
        case password
        case deviceId = "device_id"
    }
}

/// アカウント作成リクエスト
struct CreateAccountRequest: Codable {
    let name: String
    let email: String
    let password: String
    let genderType: Int
    let age: Int?
    let deviceId: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case email
        case password
        case genderType = "gender_type"
        case age
        case deviceId = "device_id"
    }
}