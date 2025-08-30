import Foundation

/// ユーザー情報を表すモデル
struct User: Codable {
    let id: Int
    let name: String
    let email: String
    let genderType: Int
    let age: Int?
    let imagePath: String?
    let profile: String?
    let appleUserId: String?
    let deviceId: String?  // Optional に変更（新規登録時はサーバー側で設定される場合がある）
    let pushToken: String?
    let lastLoginedAt: Date?
    let createdAt: Date?  // Optional に変更（新規登録レスポンスでは含まれる場合がある）
    let updatedAt: Date?  // Optional に変更（新規登録レスポンスでは含まれる場合がある）
    let deletedAt: Date?
    
    /// メンバーワイズイニシャライザー（テスト用など）
    init(
        id: Int,
        name: String,
        email: String,
        genderType: Int,
        age: Int? = nil,
        imagePath: String? = nil,
        profile: String? = nil,
        appleUserId: String? = nil,
        deviceId: String? = nil,
        pushToken: String? = nil,
        lastLoginedAt: Date? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.genderType = genderType
        self.age = age
        self.imagePath = imagePath
        self.profile = profile
        self.appleUserId = appleUserId
        self.deviceId = deviceId
        self.pushToken = pushToken
        self.lastLoginedAt = lastLoginedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case genderType = "gender_type"
        case age
        case imagePath = "image_path"
        case profile
        case appleUserId = "apple_user_id"
        case deviceId = "device_id"
        case pushToken = "push_token"
        case lastLoginedAt = "last_logined_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
    
    /// カスタムデコーダー（日付フォーマットの処理）
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)
        genderType = try container.decode(Int.self, forKey: .genderType)
        age = try container.decodeIfPresent(Int.self, forKey: .age)
        imagePath = try container.decodeIfPresent(String.self, forKey: .imagePath)
        profile = try container.decodeIfPresent(String.self, forKey: .profile)
        appleUserId = try container.decodeIfPresent(String.self, forKey: .appleUserId)
        deviceId = try container.decodeIfPresent(String.self, forKey: .deviceId)
        pushToken = try container.decodeIfPresent(String.self, forKey: .pushToken)
        
        // 日付フィールドの処理（共通処理を使用）
        // lastLoginedAtの処理
        if let lastLoginedAtString = try? container.decode(String.self, forKey: .lastLoginedAt) {
            lastLoginedAt = DateFormatter.dateFromLaravelString(lastLoginedAtString)
        } else {
            lastLoginedAt = try container.decodeIfPresent(Date.self, forKey: .lastLoginedAt)
        }
        
        // createdAtの処理
        if let createdAtString = try? container.decode(String.self, forKey: .createdAt) {
            createdAt = DateFormatter.dateFromLaravelString(createdAtString)
        } else {
            createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        }
        
        // updatedAtの処理  
        if let updatedAtString = try? container.decode(String.self, forKey: .updatedAt) {
            updatedAt = DateFormatter.dateFromLaravelString(updatedAtString)
        } else {
            updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        }
        
        // deletedAtの処理
        if let deletedAtString = try? container.decode(String.self, forKey: .deletedAt) {
            deletedAt = DateFormatter.dateFromLaravelString(deletedAtString)
        } else {
            deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        }
    }
}

/// 性別を表す列挙型
/// サーバー側の定数と一致させる:
/// 0 = 指定なし (GENDER_TYPE_NONE)
/// 1 = 男性 (GENDER_TYPE_MAN)
/// 2 = 女性 (GENDER_TYPE_WOMAN)
enum Gender: Int, CaseIterable {
    case none = 0    // 指定なし
    case male = 1    // 男性
    case female = 2  // 女性
    
    /// 表示用の名前を取得
    var displayName: String {
        switch self {
        case .none:
            return "指定なし"
        case .male:
            return "男性"
        case .female:
            return "女性"
        }
    }
}