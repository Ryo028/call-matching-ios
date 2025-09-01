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
            // 背景
            Capsule()
                .fill(Color.white)
                .frame(height: height)
                .shadow(color: Theme.cardShadow, radius: 20, x: 0, y: 10)
            
            // タブアイテム
            HStack(spacing: 0) {
                ForEach(TabType.allCases, id: \.self) { tab in
                    TabItemView(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        action: {
                            withAnimation(.spring(response: 0.3)) {
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
            // アイコン（絵文字）のみ表示
            Text(tab.emoji)
                .font(.system(size: isSelected ? 28 : 24))
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .frame(maxWidth: .infinity)
                .frame(height: 70)
                .background(
                    ZStack {
                        if isSelected {
                            Circle()
                                .fill(Theme.primaryColor.opacity(0.1))
                                .frame(width: 60, height: 60)
                        }
                    }
                )
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