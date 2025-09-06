import SwiftUI

/// マッチング設定画面
struct MatchingSettingsView: View {
    @Binding var ageRange: ClosedRange<Double>
    @Binding var distanceRange: Double
    @Binding var isPresented: Bool
    
    // MultipleSliderView用の変数
    @State private var lowerAge: Int = 18
    @State private var upperAge: Int = 61  // 61は制限なしを意味する
    // CustomSliderView用の変数
    @State private var distanceValue: Int = 301  // 301は制限なしを意味する
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundView
                
                ScrollView {
                    VStack(spacing: 25) {
                        headerView
                        ageRangeView
                        distanceSettingView
                        
                        // 完了ボタンをコンテンツの最後に配置
                        Button(action: {
                            withAnimation(.spring()) {
                                isPresented = false
                            }
                        }) {
                            Text("完了")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 28)
                                        .fill(Theme.buttonGradient)
                                )
                                .shadow(color: Theme.buttonShadow, radius: 12, x: 0, y: 6)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                // 初期値を同期
                lowerAge = Int(ageRange.lowerBound)
                upperAge = Int(ageRange.upperBound)
                distanceValue = Int(distanceRange)
            }
            .overlay(
                // 左上の閉じるボタンのみ
                VStack {
                    HStack {
                        Button(action: {
                            withAnimation(.spring()) {
                                isPresented = false
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Theme.Text.primary)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.9))
                                        .shadow(color: Theme.cardShadow, radius: 8, x: 0, y: 2)
                                )
                        }
                        .padding(.leading, 20)
                        .padding(.top, 50)
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
            )
        }
    }
    
    // 背景ビュー
    private var backgroundView: some View {
        Theme.backgroundGradient
            .ignoresSafeArea()
    }
    
    // ヘッダービュー
    private var headerView: some View {
        Text("マッチング設定")
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(Theme.Text.primary)
            .padding(.top, 20)
            .padding(.bottom, 10)
    }
    
    // 年齢範囲ビュー
    private var ageRangeView: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.secondaryColor)
                
                Text("年齢")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.Text.primary)
                
                Spacer()
            }
            
            // MultipleSliderViewを使用
            MultipleSliderView(
                initLowerValue: Int(ageRange.lowerBound),
                initUpperValue: Int(ageRange.upperBound),
                lowerValue: $lowerAge,
                upperValue: $upperAge
            )
            .onChange(of: lowerAge) { _, newValue in
                ageRange = Double(newValue)...ageRange.upperBound
            }
            .onChange(of: upperAge) { _, newValue in
                ageRange = ageRange.lowerBound...Double(newValue)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Theme.cardShadow, radius: 12, x: 0, y: 6)
        )
        .padding(.horizontal, 20)
    }
    
    // 距離設定ビュー
    private var distanceSettingView: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "location.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.secondaryColor)
                
                Text("距離")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.Text.primary)
                
                Spacer()
            }
            
            // CustomSliderViewを使用
            CustomSliderView(
                initValue: Int(distanceRange),
                value: $distanceValue
            )
            .onChange(of: distanceValue) { _, newValue in
                distanceRange = Double(newValue)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Theme.cardShadow, radius: 12, x: 0, y: 6)
        )
        .padding(.horizontal, 20)
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
        isPresented: .constant(true)
    )
}
