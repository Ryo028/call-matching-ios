import SwiftUI

/// カスタムテキストフィールド
struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var icon: String?
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // アイコン
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(isFocused ? Theme.primaryColor : Theme.Text.secondary)
                    .font(.system(size: 18))
                    .frame(width: 20)
            }
            
            // テキストフィールド
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                }
            }
            .focused($isFocused)
            .foregroundColor(Theme.Text.primary)
            .font(.system(size: 16))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(
                            isFocused ? Theme.primaryColor : Color.clear,
                            lineWidth: 2
                        )
                )
        )
        .shadow(color: Theme.cardShadow, radius: 8, x: 0, y: 4)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

#Preview("通常のテキストフィールド") {
    VStack(spacing: 20) {
        CustomTextField(
            placeholder: "メールアドレス",
            text: .constant(""),
            icon: "envelope.fill"
        )
        
        CustomTextField(
            placeholder: "ニックネーム",
            text: .constant("田中太郎"),
            icon: "person.fill"
        )
    }
    .padding()
    .background(Theme.backgroundGradient)
}

#Preview("セキュアフィールド") {
    VStack(spacing: 20) {
        CustomTextField(
            placeholder: "パスワード",
            text: .constant(""),
            isSecure: true,
            icon: "lock.fill"
        )
        
        CustomTextField(
            placeholder: "パスワード（確認）",
            text: .constant("password123"),
            isSecure: true,
            icon: "lock.fill"
        )
    }
    .padding()
    .background(Theme.backgroundGradient)
}

#Preview("数値入力フィールド") {
    CustomTextField(
        placeholder: "年齢",
        text: .constant("25"),
        keyboardType: .numberPad,
        icon: "calendar"
    )
    .padding()
    .background(Theme.backgroundGradient)
}