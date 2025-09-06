import SwiftUI

/// SuperEllipse（超楕円）Shape
/// |x/a|^n + |y/b|^n = 1 の数式を三次ベジェ曲線で近似して描画する
struct SuperEllipseShape: Shape {
    /// SuperEllipseの形状を決定するパラメータn（n > 0）
    /// n=2: 楕円
    /// nが大きくなるほど四角形に近づく
    /// iOSのアイコンは約n=5とされている
    var n: CGFloat

    init(n: CGFloat = 5.0) {
        self.n = n
    }

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let a = w / 2.0  // x方向の半径
        let b = h / 2.0  // y方向の半径
        let cx = w / 2.0 // 中心x座標
        let cy = h / 2.0 // 中心y座標
        
        // 正確なSuperEllipse係数計算: k(n) = (8 * 2^(-1/n) - 4) / 3
        let u = pow(2.0, -1.0 / n)
        var k = (8.0 * u - 4.0) / 3.0
        
        // 高いn値での視覚的改善のため、必要に応じて制御点をクランプ
        // n > 6 の場合、制御点が外接矩形を大きく超えるため調整
        if n > 6.0 {
            k = min(k, 1.0)
        }
        
        var path = Path()
        
        // 第1象限: (a,0) -> (0,b)
        path.move(to: CGPoint(x: cx + a, y: cy))
        path.addCurve(
            to: CGPoint(x: cx, y: cy - b),
            control1: CGPoint(x: cx + a, y: cy - k * b),
            control2: CGPoint(x: cx + k * a, y: cy - b)
        )
        
        // 第2象限: (0,b) -> (-a,0)
        path.addCurve(
            to: CGPoint(x: cx - a, y: cy),
            control1: CGPoint(x: cx - k * a, y: cy - b),
            control2: CGPoint(x: cx - a, y: cy - k * b)
        )
        
        // 第3象限: (-a,0) -> (0,-b)
        path.addCurve(
            to: CGPoint(x: cx, y: cy + b),
            control1: CGPoint(x: cx - a, y: cy + k * b),
            control2: CGPoint(x: cx - k * a, y: cy + b)
        )
        
        // 第4象限: (0,-b) -> (a,0)
        path.addCurve(
            to: CGPoint(x: cx + a, y: cy),
            control1: CGPoint(x: cx + k * a, y: cy + b),
            control2: CGPoint(x: cx + a, y: cy + k * b)
        )
        
        path.closeSubpath()
        return path
    }
}


/// SuperEllipseのView Modifier
struct SuperEllipseModifier: ViewModifier {
    let n: CGFloat
    
    func body(content: Content) -> some View {
        content
            .clipShape(SuperEllipseShape(n: n))
    }
}

/// View拡張でSuperEllipseを簡単に適用できるようにする
extension View {
    /// SuperEllipse（超楕円）でクリップする
    /// - Parameter n: SuperEllipseの形状を決定するパラメータn（デフォルト: 5.0）
    func superEllipse(n: CGFloat = 5.0) -> some View {
        self.modifier(SuperEllipseModifier(n: n))
    }
}

/// SuperEllipse画像表示コンポーネント
struct SuperEllipseImageView: View {
    let image: Image
    let size: CGFloat
    let n: CGFloat
    let background: AnyShapeStyle?
    
    init(
        image: Image,
        size: CGFloat,
        n: CGFloat = 5.0,
        background: (any ShapeStyle)? = nil
    ) {
        self.image = image
        self.size = size
        self.n = n
        if let background = background {
            self.background = AnyShapeStyle(background)
        } else {
            self.background = nil
        }
    }
    
    var body: some View {
        ZStack {
            // 背景
            if let background = background {
                Rectangle()
                    .fill(background)
            }
            
            // 画像
            image
                .resizable()
                .scaledToFill()
        }
        .frame(width: size, height: size)
        .superEllipse(n: n)
    }
}

/// SuperEllipseアイコン表示コンポーネント
struct SuperEllipseIconView: View {
    let iconName: String
    let size: CGFloat
    let iconSize: CGFloat?
    let iconColor: Color
    let backgroundColor: Color
    let n: CGFloat
    
    init(
        iconName: String,
        size: CGFloat,
        iconSize: CGFloat? = nil,
        iconColor: Color = .white,
        backgroundColor: Color = .blue,
        n: CGFloat = 5.0
    ) {
        self.iconName = iconName
        self.size = size
        self.iconSize = iconSize ?? size * 0.5
        self.iconColor = iconColor
        self.backgroundColor = backgroundColor
        self.n = n
    }
    
    var body: some View {
        ZStack {
            // 背景
            Rectangle()
                .fill(backgroundColor)
            
            // アイコン
            Image(systemName: iconName)
                .font(.system(size: iconSize ?? size * 0.5))
                .foregroundColor(iconColor)
        }
        .frame(width: size, height: size)
        .superEllipse(n: n)
    }
}

/// SuperEllipse Asset画像表示コンポーネント（iOS 17+）
@available(iOS 17.0, *)
struct SuperEllipseAssetImageView: View {
    let imageResource: ImageResource
    let size: CGFloat
    let n: CGFloat
    let background: AnyShapeStyle?
    
    init(
        imageResource: ImageResource,
        size: CGFloat,
        n: CGFloat = 5.0,
        background: (any ShapeStyle)? = nil
    ) {
        self.imageResource = imageResource
        self.size = size
        self.n = n
        if let background = background {
            self.background = AnyShapeStyle(background)
        } else {
            self.background = nil
        }
    }
    
    var body: some View {
        ZStack {
            // 背景
            if let background = background {
                Rectangle()
                    .fill(background)
            }
            
            // 画像
            Image(imageResource)
                .resizable()
                .scaledToFill()
        }
        .frame(width: size, height: size)
        .superEllipse(n: n)
    }
}

/// SuperEllipseのプレビュー用サンプルビュー
struct SuperEllipseSample: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("SuperEllipse Samples")
                    .font(.title2)
                    .bold()
                
                // 基本的なShape（正方形）
                VStack(spacing: 10) {
                    Text("正方形")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 15) {
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 60, height: 60)
                            .superEllipse(n: 2.5) // Squircle
                        
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [.green, .teal],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 60, height: 60)
                            .superEllipse(n: 3.5) // Balanced
                        
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 60, height: 60)
                            .superEllipse(n: 5.0) // iOS-like
                    }
                    
                    Text("n: 2.5 (Squircle), 3.5 (Balanced), 5.0 (iOS-like)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // 縦長
                VStack(spacing: 10) {
                    Text("縦長（Portrait）")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 15) {
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                            .frame(width: 50, height: 80)
                            .superEllipse(n: 2.5)
                        
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [.green, .teal],
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                            .frame(width: 50, height: 80)
                            .superEllipse(n: 3.5)
                        
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                            .frame(width: 50, height: 80)
                            .superEllipse(n: 5.0)
                    }
                    
                    Text("カード風レイアウト")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // 横長
                VStack(spacing: 10) {
                    Text("横長（Landscape）")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 10) {
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: 120, height: 40)
                            .superEllipse(n: 2.5)
                        
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [.green, .teal],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: 120, height: 40)
                            .superEllipse(n: 3.5)
                        
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: 120, height: 40)
                            .superEllipse(n: 5.0)
                        
                    }
                    
                    Text("ボタン風レイアウト")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // アイコンを使った例
                VStack(spacing: 10) {
                    Text("アイコン付きコンポーネント")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 15) {
                        SuperEllipseIconView(
                            iconName: "phone.fill",
                            size: 60,
                            backgroundColor: .green,
                            n: 2.5
                        )
                        
                        SuperEllipseIconView(
                            iconName: "heart.fill",
                            size: 60,
                            backgroundColor: .red,
                            n: 3.5
                        )
                        
                        SuperEllipseIconView(
                            iconName: "star.fill",
                            size: 60,
                            backgroundColor: .orange,
                            n: 5.0
                        )
                    }
                }
                
                Divider()
                
                // 縦長アイコン
                VStack(spacing: 10) {
                    Text("縦長アイコンビュー")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 15) {
                        VStack(spacing: 8) {
                            SuperEllipseIconView(
                                iconName: "phone.fill",
                                size: 50,
                                backgroundColor: .green,
                                n: 5.0
                            )
                            Text("通話")
                                .font(.caption)
                        }
                        
                        VStack(spacing: 8) {
                            SuperEllipseIconView(
                                iconName: "message.fill",
                                size: 50,
                                backgroundColor: .blue,
                                n: 5.0
                            )
                            Text("メッセージ")
                                .font(.caption)
                        }
                        
                        VStack(spacing: 8) {
                            SuperEllipseIconView(
                                iconName: "person.fill",
                                size: 50,
                                backgroundColor: .purple,
                                n: 5.0
                            )
                            Text("プロフィール")
                                .font(.caption)
                        }
                    }
                }
                
                // Asset画像を使った例（iOS 17+）
                if #available(iOS 17.0, *) {
                    Divider()
                    
                    VStack(spacing: 10) {
                        Text("Asset画像の活用")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 15) {
                            // 正方形
                            SuperEllipseAssetImageView(
                                imageResource: .telephoneReceiver,
                                size: 60,
                                n: 5.0,
                                background: LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            
                            // 縦長での応用例
                            VStack(spacing: 5) {
                                Rectangle()
                                    .fill(LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ))
                                    .frame(width: 50, height: 30)
                                    .superEllipse(n: 5.0)
                                    .overlay(
                                        Image(.telephoneReceiver)
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 20, height: 20)
                                            .foregroundColor(.white)
                                    )
                                
                                Text("通話開始")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

#Preview("SuperEllipse") {
    SuperEllipseSample()
}
