import SwiftUI

/// アプリのテーマカラーを管理
enum Theme {
    /// プライマリカラー（ピンク系）
    static let primaryColor = Color(red: 255/255, green: 111/255, blue: 145/255) // #FF6F91
    
    /// セカンダリカラー（パープル系）
    static let secondaryColor = Color(red: 196/255, green: 113/255, blue: 237/255) // #C471ED
    
    /// アクセントカラー（オレンジ系）
    static let accentColor = Color(red: 255/255, green: 175/255, blue: 130/255) // #FFAF82
    
    /// 背景グラデーション
    static let backgroundGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 252/255, green: 244/255, blue: 255/255), // 薄いピンク
            Color(red: 244/255, green: 248/255, blue: 255/255)  // 薄いブルー
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// ボタングラデーション
    static let buttonGradient = LinearGradient(
        gradient: Gradient(colors: [primaryColor, secondaryColor]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// テキストカラー
    enum Text {
        static let primary = Color(red: 50/255, green: 50/255, blue: 60/255)
        static let secondary = Color(red: 120/255, green: 120/255, blue: 140/255)
        static let white = Color.white
    }
    
    /// 影のスタイル
    static let cardShadow = Color.black.opacity(0.08)
    static let buttonShadow = primaryColor.opacity(0.3)
}