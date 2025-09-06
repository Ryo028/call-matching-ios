import SwiftUI

/// SuperEllipse形状を使用した3D回転するジェンダー選択カード
struct SuperEllipseGender3DCardView: View {
    let gender: GenderType
    @Binding var selectedGender: GenderType
    @State private var rotation: Double = 0
    @State private var isFlipped = false
    @State private var scale: CGFloat = 1.0
    @State private var zOffset: CGFloat = 0
    
    private var isSelected: Bool {
        selectedGender == gender
    }
    
    var body: some View {
        ZStack {
            // カードの表面
            SuperEllipseCardFrontView(gender: gender, isSelected: isSelected)
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(
                    .degrees(rotation),
                    axis: (x: 0, y: 1, z: 0)
                )
            
            // カードの裏面
            SuperEllipseCardBackView(gender: gender, isSelected: isSelected)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(rotation + 180),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .frame(width: 100, height: 140)
        .scaleEffect(scale)
        .offset(y: -zOffset)  // Z軸の代わりにY軸で浮き上がりを表現
        .onTapGesture {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                // 選択状態を更新
                selectedGender = gender
                
                // 3D回転アニメーション
                rotation += 360
                
                // スケールアニメーション
                scale = 1.2
                zOffset = 20
                
                // カードを裏返す
                if !isSelected {
                    isFlipped.toggle()
                }
                
                // 0.3秒後に元のサイズに戻す
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        scale = isSelected ? 1.1 : 1.0
                        zOffset = isSelected ? 10 : 0
                    }
                }
            }
        }
        .onAppear {
            // 初期アニメーション
            withAnimation(.easeOut(duration: 0.5).delay(Double.random(in: 0...0.2))) {
                scale = isSelected ? 1.1 : 1.0
                zOffset = isSelected ? 10 : 0
            }
        }
        .onChange(of: selectedGender) { oldValue, newValue in
            // 他のカードが選択された時のアニメーション
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                if newValue != gender && isFlipped {
                    isFlipped = false
                    rotation -= 180
                }
                scale = isSelected ? 1.1 : 1.0
                zOffset = isSelected ? 10 : 0
            }
        }
    }
}

/// SuperEllipse形状のカードの表面ビュー
struct SuperEllipseCardFrontView: View {
    let gender: GenderType
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // アイコン
            Image(systemName: gender.systemIcon)
                .font(.system(size: 40))
                .foregroundColor(isSelected ? Color.white : Color.black)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(isSelected ? Color.white.opacity(0.15) : Color.gray.opacity(0.1))
                )
            
            // ラベル
            Text(gender.label)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isSelected ? Color.white : Color.black)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                Rectangle()
                    .fill(
                        isSelected ? 
                        Color.black : 
                        Color.white
                    )
                    .superEllipse(n: 3.5)
                
                Rectangle()
                    .stroke(
                        LinearGradient(
                            colors: isSelected ? 
                            [Color.white.opacity(0.8), Color.gray.opacity(0.5)] : 
                            [Color.gray.opacity(0.2), Color.gray.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isSelected ? 1.5 : 1
                    )
                    .superEllipse(n: 3.5)
            }
        )
        .shadow(
            color: Color.black.opacity(0.3),
            radius: isSelected ? 15 : 8,
            x: 0,
            y: isSelected ? 8 : 4
        )
    }
}

/// SuperEllipse形状のカードの裏面ビュー
struct SuperEllipseCardBackView: View {
    let gender: GenderType
    let isSelected: Bool
    
    private var description: String {
        switch gender {
        case .all:
            return "すべての\n性別の方と\nマッチング"
        case .male:
            return "男性の方と\nマッチング"
        case .female:
            return "女性の方と\nマッチング"
        }
    }
    
    private var emoji: String {
        switch gender {
        case .all:
            return "🌈"
        case .male:
            return "👨"
        case .female:
            return "👩"
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // 絵文字
            Text(emoji)
                .font(.system(size: 40))
            
            // 説明テキスト
            Text(description)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.white)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black,
                                Color.black.opacity(0.85)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .superEllipse(n: 3.5)
                
                // キラキラエフェクト
                GeometryReader { geometry in
                    ForEach(0..<5, id: \.self) { index in
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: CGFloat.random(in: 4...8), 
                                   height: CGFloat.random(in: 4...8))
                            .position(
                                x: CGFloat.random(in: 0...geometry.size.width),
                                y: CGFloat.random(in: 0...geometry.size.height)
                            )
                            .blur(radius: 1)
                    }
                }
                .mask(
                    Rectangle()
                        .superEllipse(n: 3.5)
                )
            }
        )
        .shadow(
            color: Color.white.opacity(0.1),
            radius: 10,
            x: 0,
            y: 5
        )
    }
}

/// SuperEllipse 3Dカード選択ビュー（3枚のカードを並べる）
struct SuperEllipseGender3DCardSelectionView: View {
    @Binding var selectedGender: GenderType
    
    var body: some View {
        HStack(spacing: 20) {
            ForEach(GenderType.allCases, id: \.self) { gender in
                SuperEllipseGender3DCardView(
                    gender: gender,
                    selectedGender: $selectedGender
                )
            }
        }
        .padding(.horizontal, 20)
    }
}

#Preview("SuperEllipse 3D Gender Cards") {
    VStack {
        SuperEllipseGender3DCardSelectionView(selectedGender: .constant(.all))
            .padding(.vertical, 40)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.backgroundGradient)
}
