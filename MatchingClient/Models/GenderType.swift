import Foundation

/// 性別タイプ
enum GenderType: String, CaseIterable {
    case all = "all"
    case male = "male"
    case female = "female"
    
    /// 表示ラベル
    var label: String {
        switch self {
        case .all:
            return "誰でも"
        case .male:
            return "男性"
        case .female:
            return "女性"
        }
    }
    
    /// アイコン名（Asset Catalogの画像名）
    var icon: String {
        switch self {
        case .all:
            return "icon_all"
        case .male:
            return "icon_male"
        case .female:
            return "icon_female"
        }
    }
    
    /// システムアイコン（SF Symbols）
    var systemIcon: String {
        switch self {
        case .all:
            return "person.2.fill"
        case .male:
            return "person.fill"
        case .female:
            return "person.fill"
        }
    }
}