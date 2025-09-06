import SwiftUI

/// SuperEllipse形状を使用した性別選択コンポーネント
struct SuperEllipseGenderSelectionView: View {
    @Binding var selectedGender: GenderType
    
    var body: some View {
        VStack(spacing: 20) {
            Text("どんな人とトークする？")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Theme.Text.primary)
            
            HStack(spacing: 15) {
                ForEach(GenderType.allCases, id: \.self) { gender in
                    SuperEllipseGenderCard(
                        gender: gender,
                        isSelected: selectedGender == gender,
                        onTap: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                selectedGender = gender
                            }
                        }
                    )
                }
            }
        }
        .padding()
    }
}

/// SuperEllipse形状の性別選択カード
struct SuperEllipseGenderCard: View {
    let gender: GenderType
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var shimmerOffset: CGFloat = -200
    
    private var cardSize: CGFloat { 100 }
    private var iconSize: CGFloat { 40 }
    
    // 性別に応じた色設定
    private var cardGradient: LinearGradient {
        switch gender {
        case .all:
            return LinearGradient(
                colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .male:
            return LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.cyan.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .female:
            return LinearGradient(
                colors: [Color.pink.opacity(0.8), Color.red.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var selectedGradient: LinearGradient {
        switch gender {
        case .all:
            return LinearGradient(
                colors: [Color.purple, Color.blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .male:
            return LinearGradient(
                colors: [Color.blue, Color.cyan],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .female:
            return LinearGradient(
                colors: [Color.pink, Color.red],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // 背景カード
                SuperEllipseIconView(
                    iconName: gender.systemIcon,
                    size: cardSize,
                    iconSize: iconSize,
                    iconColor: isSelected ? .white : Color.black.opacity(0.7),
                    backgroundColor: .clear,
                    n: 3.5
                )
                .background(
                    ZStack {
                        // メインの背景
                        Rectangle()
                            .fill(isSelected ? selectedGradient : cardGradient)
                            .superEllipse(n: 3.5)
                        
                        // 選択時のシマーエフェクト
                        if isSelected {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        stops: [
                                            .init(color: .clear, location: 0.0),
                                            .init(color: .white.opacity(0.6), location: 0.5),
                                            .init(color: .clear, location: 1.0)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .superEllipse(n: 3.5)
                                .offset(x: shimmerOffset)
                                .mask(
                                    Rectangle()
                                        .superEllipse(n: 3.5)
                                )
                                .onAppear {
                                    withAnimation(
                                        .linear(duration: 1.5)
                                        .repeatForever(autoreverses: false)
                                    ) {
                                        shimmerOffset = 200
                                    }
                                }
                        }
                        
                        // パルスエフェクト（選択時）
                        if isSelected {
                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .superEllipse(n: 3.5)
                                .scaleEffect(pulseScale)
                                .onAppear {
                                    withAnimation(
                                        .easeInOut(duration: 1.0)
                                        .repeatForever(autoreverses: true)
                                    ) {
                                        pulseScale = 1.1
                                    }
                                }
                                .onDisappear {
                                    pulseScale = 1.0
                                }
                        }
                        
                        // ボーダー
                        Rectangle()
                            .stroke(
                                isSelected ? 
                                Color.white.opacity(0.8) : 
                                Color.black.opacity(0.1),
                                lineWidth: isSelected ? 2 : 1
                            )
                            .superEllipse(n: 3.5)
                    }
                )
                
                // ラベル（下部に表示）
                VStack {
                    Spacer()
                    Text(gender.label)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isSelected ? .white : Color.black.opacity(0.8))
                        .padding(.bottom, 8)
                }
            }
        }
        .scaleEffect(isPressed ? 0.95 : (isSelected ? 1.1 : 1.0))
        .shadow(
            color: isSelected ? Color.black.opacity(0.3) : Color.black.opacity(0.1),
            radius: isSelected ? 12 : 6,
            x: 0,
            y: isSelected ? 6 : 3
        )
        .onLongPressGesture(minimumDuration: 0, maximumDistance: 50) {
            // Press完了
        } onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isSelected)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}

/// 横並び版のSuperEllipse性別選択ビュー
struct SuperEllipseGenderRowView: View {
    @Binding var selectedGender: GenderType
    
    var body: some View {
        HStack(spacing: 15) {
            ForEach(GenderType.allCases, id: \.self) { gender in
                SuperEllipseGenderCard(
                    gender: gender,
                    isSelected: selectedGender == gender,
                    onTap: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                            selectedGender = gender
                        }
                    }
                )
            }
        }
        .padding(.horizontal)
    }
}

/// コンパクト版のSuperEllipse性別選択カード（小サイズ）
struct SuperEllipseGenderCompactCard: View {
    let gender: GenderType
    let isSelected: Bool
    let onTap: () -> Void
    
    private var cardSize: CGFloat { 60 }
    private var iconSize: CGFloat { 24 }
    
    var body: some View {
        Button(action: onTap) {
            SuperEllipseIconView(
                iconName: gender.systemIcon,
                size: cardSize,
                iconSize: iconSize,
                iconColor: isSelected ? .white : Color.black.opacity(0.6),
                backgroundColor: isSelected ? Color.black : Color.gray.opacity(0.2),
                n: 3.5
            )
            .overlay(
                // 選択時のリング
                Rectangle()
                    .stroke(
                        isSelected ? Color.white : Color.clear,
                        lineWidth: 2
                    )
                    .superEllipse(n: 3.5)
            )
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .shadow(
                color: Color.black.opacity(0.2),
                radius: isSelected ? 8 : 4,
                x: 0,
                y: isSelected ? 4 : 2
            )
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isSelected)
    }
}

/// コンパクト版の性別選択ビュー
struct SuperEllipseGenderCompactView: View {
    @Binding var selectedGender: GenderType
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(GenderType.allCases, id: \.self) { gender in
                SuperEllipseGenderCompactCard(
                    gender: gender,
                    isSelected: selectedGender == gender,
                    onTap: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                            selectedGender = gender
                        }
                    }
                )
            }
        }
    }
}

#Preview("SuperEllipse Gender Selection") {
    VStack(spacing: 40) {
        // 通常版
        SuperEllipseGenderSelectionView(selectedGender: .constant(.all))
        
        Divider()
        
        // 横並び版
        VStack(spacing: 10) {
            Text("横並び版")
                .font(.headline)
            SuperEllipseGenderRowView(selectedGender: .constant(.male))
        }
        
        Divider()
        
        // コンパクト版
        VStack(spacing: 10) {
            Text("コンパクト版")
                .font(.headline)
            SuperEllipseGenderCompactView(selectedGender: .constant(.female))
        }
    }
    .padding()
    .background(Theme.backgroundGradient)
}