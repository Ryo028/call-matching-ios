import SwiftUI

/// マッチング設定画面
struct MatchingSettingsView: View {
    @Binding var ageRange: ClosedRange<Double>
    @Binding var distanceRange: Double
    @Binding var callType: MatchingView.CallType
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景色
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 年齢範囲設定
                        SettingSectionView(title: "年齢範囲") {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("相手の年齢")
                                        .font(.system(size: 15))
                                        .foregroundColor(Theme.Text.primary)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(ageRange.lowerBound))歳 〜 \(Int(ageRange.upperBound))歳")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Theme.primaryColor)
                                }
                                
                                // 年齢範囲スライダー
                                VStack(spacing: 8) {
                                    // カスタム範囲スライダー
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            // 背景トラック
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.gray.opacity(0.2))
                                                .frame(height: 6)
                                            
                                            // 選択範囲
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Theme.buttonGradient)
                                                .frame(
                                                    width: CGFloat((ageRange.upperBound - ageRange.lowerBound) / 50.0) * geometry.size.width,
                                                    height: 6
                                                )
                                                .offset(x: CGFloat((ageRange.lowerBound - 18.0) / 50.0) * geometry.size.width)
                                        }
                                    }
                                    .frame(height: 6)
                                    
                                    HStack {
                                        Text("18歳")
                                            .font(.system(size: 12))
                                            .foregroundColor(Theme.Text.secondary)
                                        
                                        Spacer()
                                        
                                        Text("68歳")
                                            .font(.system(size: 12))
                                            .foregroundColor(Theme.Text.secondary)
                                    }
                                }
                                .padding(.top, 8)
                            }
                        }
                        
                        // 距離設定
                        SettingSectionView(title: "距離") {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("相手との距離")
                                        .font(.system(size: 15))
                                        .foregroundColor(Theme.Text.primary)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(distanceRange))km以内")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Theme.primaryColor)
                                }
                                
                                Slider(value: $distanceRange, in: 1...50, step: 1)
                                    .accentColor(Theme.primaryColor)
                                
                                HStack {
                                    Text("1km")
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.Text.secondary)
                                    
                                    Spacer()
                                    
                                    Text("50km")
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.Text.secondary)
                                }
                            }
                        }
                        
                        // 通話タイプ設定
                        SettingSectionView(title: "通話タイプ") {
                            VStack(spacing: 12) {
                                ForEach(MatchingView.CallType.allCases, id: \.self) { type in
                                    CallTypeSelectionRow(
                                        type: type,
                                        isSelected: callType == type,
                                        action: { callType = type }
                                    )
                                }
                            }
                        }
                        
                        // その他の設定（将来的に追加）
                        SettingSectionView(title: "その他") {
                            VStack(spacing: 12) {
                                SettingRowView(
                                    icon: "bell.fill",
                                    title: "通知設定",
                                    value: "オン",
                                    action: {
                                        // TODO: 通知設定画面を開く
                                    }
                                )
                                
                                Divider()
                                
                                SettingRowView(
                                    icon: "shield.fill",
                                    title: "プライバシー設定",
                                    value: "",
                                    action: {
                                        // TODO: プライバシー設定画面を開く
                                    }
                                )
                            }
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("通話設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        withAnimation(.spring()) {
                            isPresented = false
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.primaryColor)
                }
            }
        }
    }
}

/// 設定セクションビュー
struct SettingSectionView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.Text.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 20)
            
            VStack {
                content
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
            )
            .padding(.horizontal, 20)
        }
    }
}

/// 通話タイプ選択行
struct CallTypeSelectionRow: View {
    let type: MatchingView.CallType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Theme.primaryColor : Theme.Text.secondary)
                    .frame(width: 28)
                
                Text(type.rawValue)
                    .font(.system(size: 15))
                    .foregroundColor(Theme.Text.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.primaryColor)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

/// 設定行ビュー
struct SettingRowView: View {
    let icon: String
    let title: String
    let value: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Theme.primaryColor)
                    .frame(width: 28)
                
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(Theme.Text.primary)
                
                Spacer()
                
                if !value.isEmpty {
                    Text(value)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Text.secondary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(Color.gray.opacity(0.5))
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview("マッチング設定") {
    MatchingSettingsView(
        ageRange: .constant(18.0...35.0),
        distanceRange: .constant(10.0),
        callType: .constant(.both),
        isPresented: .constant(true)
    )
}