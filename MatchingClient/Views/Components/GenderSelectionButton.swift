import SwiftUI

/// 性別選択ボタン（設定画面用）
struct GenderTypeSelectionButton: View {
    let gender: GenderType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: gender.systemIcon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : Theme.Text.secondary)
                
                Text(gender.label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : Theme.Text.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Theme.buttonGradient)
                            .shadow(color: Theme.buttonShadow, radius: 8, x: 0, y: 4)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.9))
                            .shadow(color: Theme.cardShadow, radius: 8, x: 0, y: 4)
                    }
                }
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
    }
}

