import Foundation
import SwiftUI

/// UI関連の定数
enum UIConstants {
    /// 余白・スペーシング
    enum Spacing {
        static let xxSmall: CGFloat = 4
        static let xSmall: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
        static let xxLarge: CGFloat = 48
    }
    
    /// コーナー半径
    enum CornerRadius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let xLarge: CGFloat = 16
        static let circular: CGFloat = 9999
    }
    
    /// アニメーション
    enum Animation {
        static let duration: Double = 0.3
        static let shortDuration: Double = 0.2
        static let longDuration: Double = 0.5
        static let springResponse: Double = 0.5
        static let springDamping: Double = 0.8
    }
    
    /// ボタンサイズ
    enum ButtonSize {
        static let minHeight: CGFloat = 44
        static let defaultHeight: CGFloat = 50
        static let largeHeight: CGFloat = 56
    }
    
    /// アイコンサイズ
    enum IconSize {
        static let small: CGFloat = 16
        static let medium: CGFloat = 24
        static let large: CGFloat = 32
        static let xLarge: CGFloat = 48
    }
    
    /// プロフィール画像サイズ
    enum ProfileImageSize {
        static let small: CGFloat = 40
        static let medium: CGFloat = 60
        static let large: CGFloat = 80
        static let xLarge: CGFloat = 120
    }
    
    /// フォントサイズ
    enum FontSize {
        static let caption: CGFloat = 12
        static let body: CGFloat = 16
        static let title: CGFloat = 20
        static let largeTitle: CGFloat = 28
    }
}