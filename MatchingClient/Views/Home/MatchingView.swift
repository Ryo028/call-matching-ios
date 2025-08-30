import SwiftUI

/// マッチング画面
struct MatchingView: View {
    @EnvironmentObject var matchingViewModel: MatchingViewModel
    @State private var isSearching = false
    @State private var selectedGender: Gender? = nil
    @State private var ageRange = 18.0...35.0
    @State private var distanceRange: Double = 10.0
    @State private var callType: CallType = .both
    @State private var showingSettings = false
    @State private var showingSearchView = false
    
    /// 通話タイプ
    enum CallType: String, CaseIterable {
        case voice = "音声のみ"
        case video = "ビデオ"
        case both = "どちらでも"
        
        var icon: String {
            switch self {
            case .voice: return "mic.fill"
            case .video: return "video.fill"
            case .both: return "phone.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景グラデーション
                Theme.backgroundGradient
                    .ignoresSafeArea()
                
                VStack {
                    // カスタムナビゲーションバー
                    HStack {
                        Spacer()
                        
                        // 設定アイコン
                        Button(action: {
                            withAnimation(.spring()) {
                                showingSettings = true
                            }
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Theme.primaryColor)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color.white)
                                        .shadow(color: Theme.cardShadow, radius: 8, x: 0, y: 4)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    ScrollView {
                        VStack(spacing: 30) {
                            // ヘッダー
                            MatchingHeaderView()
                                .padding(.top, 10)
                            
                            // 性別選択カード（メイン画面）
                            GenderSelectionCard(
                                selectedGender: $selectedGender
                            )
                            
                            // マッチング開始ボタン
                            StartMatchingButton(
                                action: startMatching,
                                isDisabled: false
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSettings) {
                MatchingSettingsView(
                    ageRange: $ageRange,
                    distanceRange: $distanceRange,
                    callType: $callType,
                    isPresented: $showingSettings
                )
            }
            .fullScreenCover(isPresented: $showingSearchView) {
                MatchingSearchView(
                    isPresented: $showingSearchView,
                    matchingViewModel: matchingViewModel,
                    selectedGender: selectedGender,
                    ageRange: ageRange,
                    distance: distanceRange
                )
            }
        }
    }
    
    /// マッチング開始
    private func startMatching() {
        // マッチング開始前に前の状態をリセット
        Task { @MainActor in
            await matchingViewModel.resetMatching()
            
            withAnimation(.spring()) {
                showingSearchView = true
            }
        }
    }
    
    /// マッチングキャンセル
    private func cancelMatching() {
        withAnimation(.spring()) {
            showingSearchView = false
        }
        
        // TODO: マッチングキャンセルAPIを呼び出す
    }
}

/// マッチング画面ヘッダー
struct MatchingHeaderView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("今すぐ通話")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Theme.Text.primary)
            
            Text("気の合う相手と楽しく話そう！")
                .font(.system(size: 14))
                .foregroundColor(Theme.Text.secondary)
        }
    }
}

/// 性別選択カード（メイン画面用）
struct GenderSelectionCard: View {
    @Binding var selectedGender: Gender?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("相手の性別を選択")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Theme.Text.primary)
            
            VStack(spacing: 12) {
                // 指定なしボタン
                GenderSelectionMainButton(
                    title: "誰でもOK",
                    subtitle: "性別を問わず通話",
                    icon: "person.2.fill",
                    isSelected: selectedGender == nil,
                    gradient: LinearGradient(
                        colors: [Color.purple, Color.blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    action: { selectedGender = nil }
                )
                
                HStack(spacing: 12) {
                    // 男性ボタン
                    GenderSelectionMainButton(
                        title: "男性",
                        subtitle: "男性と通話",
                        icon: "person.fill",
                        isSelected: selectedGender == .male,
                        gradient: LinearGradient(
                            colors: [Color.blue, Color.cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        action: { selectedGender = .male }
                    )
                    
                    // 女性ボタン
                    GenderSelectionMainButton(
                        title: "女性",
                        subtitle: "女性と通話",
                        icon: "person.fill",
                        isSelected: selectedGender == .female,
                        gradient: Theme.buttonGradient,
                        action: { selectedGender = .female }
                    )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Theme.cardShadow, radius: 15, x: 0, y: 8)
        )
    }
}

/// 性別選択メインボタン
struct GenderSelectionMainButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let gradient: LinearGradient
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? .white : Color.gray.opacity(0.6))
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? .white : Theme.Text.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(isSelected ? Color.white.opacity(0.9) : Theme.Text.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(gradient)
                    } else {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.gray.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
    }
}

/// 通話設定カード（設定画面用）
struct CallSettingsCard: View {
    @Binding var selectedGender: Gender?
    @Binding var ageRange: ClosedRange<Double>
    @Binding var distanceRange: Double
    @Binding var callType: MatchingView.CallType
    
    var body: some View {
        VStack(spacing: 24) {
            Text("通話設定")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.Text.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 性別選択
            VStack(alignment: .leading, spacing: 12) {
                Text("相手の性別")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Text.secondary)
                
                HStack(spacing: 10) {
                    GenderSelectionButton(
                        title: "指定なし",
                        isSelected: selectedGender == nil,
                        action: { selectedGender = nil }
                    )
                    
                    ForEach(Gender.allCases, id: \.self) { gender in
                        GenderSelectionButton(
                            title: gender.displayName,
                            isSelected: selectedGender == gender,
                            action: { selectedGender = gender }
                        )
                    }
                }
            }
            
            // 年齢範囲
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("年齢範囲")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Text.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(ageRange.lowerBound))歳 〜 \(Int(ageRange.upperBound))歳")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.primaryColor)
                }
                
                // カスタムスライダー（iOS 14互換）
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // 背景トラック
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        // 選択範囲
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.buttonGradient)
                            .frame(
                                width: CGFloat((ageRange.upperBound - ageRange.lowerBound) / 50.0) * geometry.size.width,
                                height: 8
                            )
                            .offset(x: CGFloat((ageRange.lowerBound - 18.0) / 50.0) * geometry.size.width)
                    }
                    .frame(height: 8)
                }
                .frame(height: 8)
                .padding(.vertical, 10)
            }
            
            // 距離範囲
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("距離")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Text.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(distanceRange))km以内")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.primaryColor)
                }
                
                Slider(value: $distanceRange, in: 1...50, step: 1)
                    .accentColor(Theme.primaryColor)
            }
            
            // 通話タイプ
            VStack(alignment: .leading, spacing: 12) {
                Text("通話タイプ")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Text.secondary)
                
                HStack(spacing: 10) {
                    ForEach(MatchingView.CallType.allCases, id: \.self) { type in
                        CallTypeButton(
                            type: type,
                            isSelected: callType == type,
                            action: { callType = type }
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Theme.cardShadow, radius: 15, x: 0, y: 8)
        )
    }
}

/// 性別選択ボタン
struct GenderSelectionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : Theme.Text.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Theme.buttonGradient)
                        } else {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.gray.opacity(0.1))
                        }
                    }
                )
        }
    }
}

/// 通話タイプボタン
struct CallTypeButton: View {
    let type: MatchingView.CallType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : Theme.Text.secondary)
                
                Text(type.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? .white : Theme.Text.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Theme.buttonGradient)
                    } else {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.gray.opacity(0.1))
                    }
                }
            )
        }
    }
}

/// マッチング開始ボタン
struct StartMatchingButton: View {
    let action: () -> Void
    let isDisabled: Bool
    
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 20))
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                
                Text("マッチング開始")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(Theme.buttonGradient)
                    .opacity(isDisabled ? 0.5 : 1)
            )
            .shadow(color: Theme.buttonShadow, radius: 15, x: 0, y: 8)
        }
        .disabled(isDisabled)
        .scaleEffect(isDisabled ? 0.95 : 1)
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}


#Preview("マッチング画面") {
    MatchingView()
}