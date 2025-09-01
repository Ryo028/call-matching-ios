import SwiftUI

/// アプリのテーマカラーを管理
enum Theme {
    /// プライマリカラー（ピンク系）
    static let primaryColor = Color("PrimaryColor")
    
    /// セカンダリカラー（パープル系）
    static let secondaryColor = Color("SecondaryColor")
    
    /// アクセントカラー（オレンジ系）
    static let accentColor = Color("AccentColor")
    
    /// 背景グラデーション
    static let backgroundGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color("BackgroundColor"),
            Color("BackgroundColor").opacity(0.9)
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
        static let primary = Color("TextPrimary")
        static let secondary = Color("TextSecondary")
        static let white = Color.white
    }
    
    /// 影のスタイル
    static let cardShadow = Color("CardShadow")
    static let buttonShadow = Color("ButtonShadow")
}