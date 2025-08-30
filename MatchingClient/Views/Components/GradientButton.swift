import SwiftUI

/// グラデーションボタン
struct GradientButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // 背景グラデーション
                RoundedRectangle(cornerRadius: 25)
                    .fill(Theme.buttonGradient)
                    .opacity(isDisabled ? 0.5 : 1)
                
                // コンテンツ
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(height: 56)
        }
        .disabled(isDisabled || isLoading)
        .shadow(color: Theme.buttonShadow, radius: 12, x: 0, y: 6)
        .scaleEffect(isDisabled ? 0.95 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDisabled)
    }
}

/// アウトラインボタン
struct OutlineButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.primaryColor)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Theme.primaryColor, lineWidth: 2)
                        .background(Color.white.cornerRadius(24))
                )
        }
    }
}

#Preview("グラデーションボタン") {
    VStack(spacing: 20) {
        GradientButton(
            title: "ログイン",
            action: {}
        )
        
        GradientButton(
            title: "処理中...",
            action: {},
            isLoading: true
        )
        
        GradientButton(
            title: "無効なボタン",
            action: {},
            isDisabled: true
        )
    }
    .padding()
    .background(Theme.backgroundGradient)
}

#Preview("アウトラインボタン") {
    VStack(spacing: 20) {
        OutlineButton(
            title: "新規登録はこちら",
            action: {}
        )
        
        OutlineButton(
            title: "戻る",
            action: {}
        )
    }
    .padding()
    .background(Theme.backgroundGradient)
}