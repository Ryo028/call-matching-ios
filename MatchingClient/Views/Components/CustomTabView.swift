import SwiftUI

/// タブの種類
enum TabType: Int, CaseIterable {
    case call = 0
    case profile = 1
    
    var title: String {
        switch self {
        case .call:
            return "通話"
        case .profile:
            return "プロフィール"
        }
    }
    
    var icon: String {
        switch self {
        case .call:
            return "phone.fill"
        case .profile:
            return "person.fill"
        }
    }
    
    var emoji: String {
        switch self {
        case .call:
            return "☎️"
        case .profile:
            return "👤"
        }
    }
}

/// カスタムタブビュー
struct CustomTabView: View {
    @Binding var selectedTab: TabType
    
    private let height: CGFloat = 70
    
    var body: some View {
        ZStack {
            // ブラー背景
            Capsule()
                .fill(
                    .ultraThinMaterial  // ガラスエフェクト
                )
                .frame(height: height)
                .overlay(
                    // グレーのオーバーレイ
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.gray.opacity(0.15),
                                    Color.gray.opacity(0.05)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .overlay(
                    // 枠線
                    Capsule()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.3),
                                    Color.gray.opacity(0.2)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                )
                .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 8)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            
            // タブアイテム
            HStack(spacing: 0) {
                ForEach(TabType.allCases, id: \.self) { tab in
                    TabItemView(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = tab
                            }
                        }
                    )
                }
            }
            .frame(height: height)
        }
        .padding(.horizontal, 40)
    }
}

/// タブアイテムビュー
struct TabItemView: View {
    let tab: TabType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // 選択インジケーター
                if isSelected {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.1),
                                    Color.black.opacity(0.05)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(
                                    Color.black.opacity(0.15),
                                    lineWidth: 0.5
                                )
                        )
                        .blur(radius: 0.5)
                }
                
                // アイコン（絵文字）
                Text(tab.emoji)
                    .font(.system(size: isSelected ? 26 : 22))
                    .scaleEffect(isSelected ? 1.05 : 1.0)
                    .opacity(isSelected ? 1.0 : 0.6)
                    .shadow(
                        color: isSelected ? Color.black.opacity(0.2) : Color.clear,
                        radius: 2,
                        x: 0,
                        y: 1
                    )
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
        }
    }
}

#Preview("カスタムタブビュー") {
    VStack {
        Spacer()
        
        CustomTabView(selectedTab: .constant(.call))
            .padding(.bottom, 20)
    }
    .background(Theme.backgroundGradient)
}