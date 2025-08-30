import SwiftUI

/// マッチ成功ビュー
struct MatchFoundView: View {
    let matchedUser: User?
    let onAccept: () -> Void
    let onDecline: () -> Void
    let isWaitingForOtherUser: Bool  // 相手の承認待ちか
    let otherUserAccepted: Bool  // 相手が承認済みか
    
    @State private var showAnimation = false
    @State private var hasStartedTimer = false
    @StateObject private var timerManager = TimerManager()
    @State private var waitingTimer: Timer? = nil  // 承認待ち用タイマー
    @State private var waitingTimeRemaining = 30  // 承認待ちの残り時間（秒）
    @State private var profileImage: UIImage? = nil  // プロフィール画像
    
    var body: some View {
        VStack(spacing: 40) {
            // 成功アニメーション＆タイマー
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 200, height: 200)
                    .scaleEffect(showAnimation ? 1.5 : 0.8)
                    .opacity(showAnimation ? 0 : 1)
                    .animation(
                        Animation.easeOut(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: showAnimation
                    )
                
                // タイマーの円形プログレスバー（承認待ち中は非表示）
                if !isWaitingForOtherUser {
                    ZStack {
                        // 背景の円
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 6)
                            .frame(width: 160, height: 160)
                        
                        // プログレスを表示する円
                        Circle()
                            .trim(from: 0, to: timerManager.timerProgress)
                            .stroke(
                                LinearGradient(
                                    colors: [Theme.primaryColor, Theme.accentColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: 160, height: 160)
                            .rotationEffect(.degrees(-90))  // 上から開始
                            .animation(.linear(duration: 0.1), value: timerManager.timerProgress)
                    }
                }
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 140, height: 140)
                    .overlay(
                        ZStack {
                            // プロフィール画像があれば表示、なければデフォルトアイコン
                            if let profileImage = profileImage {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 140, height: 140)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(Theme.buttonGradient)
                            }
                            
                            // タイマーの数字表示（承認待ち中は非表示）
                            if !isWaitingForOtherUser {
                                VStack {
                                    Spacer()
                                    Text("\(timerManager.remainingTime)")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(Theme.primaryColor)
                                        .padding(.bottom, 15)
                                }
                                .frame(width: 140, height: 140)
                            }
                        }
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            }
            
            // マッチ情報
            VStack(spacing: 12) {
                Text("マッチしました！")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                if let user = matchedUser {
                    HStack(spacing: 16) {
                        Text(user.name)
                            .font(.system(size: 20, weight: .semibold))
                        
                        if let age = user.age {
                            Text("\(age)歳")
                                .font(.system(size: 18))
                        }
                    }
                    .foregroundColor(.white.opacity(0.95))
                }
                
                Text("通話を開始しますか？")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top, 8)
            }
            
            // アクションボタン
            VStack(spacing: 16) {
                // 承認ボタン
                Button(action: {
                    if !isWaitingForOtherUser {
                        timerManager.stopTimer()  // タイマーをキャンセル
                        onAccept()  // 承認処理を実行
                    }
                }) {
                    HStack(spacing: 12) {
                        if isWaitingForOtherUser {
                            if otherUserAccepted {
                                // 相手が承認済み
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                Text("相手が承認しました")
                                    .font(.system(size: 18, weight: .bold))
                            } else {
                                // 相手の承認待ち
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                VStack(spacing: 4) {
                                    Text("相手の承認待ち...")
                                        .font(.system(size: 18, weight: .bold))
                                    Text("\(waitingTimeRemaining)秒")
                                        .font(.system(size: 14))
                                        .opacity(0.9)
                                }
                            }
                        } else {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 20))
                            Text("通話を開始")
                                .font(.system(size: 18, weight: .bold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(isWaitingForOtherUser ? 
                                LinearGradient(colors: [Color.gray], startPoint: .leading, endPoint: .trailing) : 
                                Theme.buttonGradient
                            )
                    )
                }
                .disabled(isWaitingForOtherUser)
                
                // 拒否ボタン
                Button(action: {
                    if !isWaitingForOtherUser {
                        timerManager.stopTimer()  // タイマーをキャンセル
                        onDecline()
                    }
                }) {
                    HStack(spacing: 8) {
                        if isWaitingForOtherUser {
                            // 承認待ち中はキャンセルボタンを表示
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 18))
                            Text("キャンセル")
                                .font(.system(size: 16, weight: .semibold))
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 18))
                            Text("別の人を探す")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundColor(isWaitingForOtherUser ? Color.red : Theme.primaryColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color.white.opacity(0.95))
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                    )
                }
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            showAnimation = true
            
            // プロフィール画像を読み込む
            if let imagePath = matchedUser?.imagePath {
                loadProfileImage(from: imagePath)
            }
            
            // タイマーをまだ開始していない場合のみ開始
            if !hasStartedTimer {
                hasStartedTimer = true
                timerManager.startTimer {
                    // タイマー完了時の処理
                    onDecline()
                }
            }
        }
        .onDisappear {
            // タイマーを停止
            timerManager.stopTimer()
        }
        .onChange(of: isWaitingForOtherUser) { _, waiting in
            if waiting {
                // 通常のタイマーを停止
                timerManager.stopTimer()
                
                // 承認待ち用のタイマーを開始（30秒後にタイムアウト）
                waitingTimer?.invalidate()
                waitingTimeRemaining = 30
                waitingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                    waitingTimeRemaining -= 1
                    if waitingTimeRemaining <= 0 {
                        timer.invalidate()
                        // タイムアウト時の処理
                        onDecline()
                    }
                }
            } else {
                // 承認待ち用タイマーを停止
                waitingTimer?.invalidate()
                waitingTimer = nil
            }
        }
        .onChange(of: otherUserAccepted) { _, accepted in
            // 相手が承認したら全てのタイマーを停止（通話画面に遷移するため）
            if accepted && isWaitingForOtherUser {
                // すべてのタイマーを停止
                timerManager.stopTimer()
                waitingTimer?.invalidate()
                waitingTimer = nil
            }
        }
        .onDisappear {
            // すべてのタイマーを停止
            timerManager.stopTimer()
            waitingTimer?.invalidate()
            waitingTimer = nil
        }
    }
    
    /// プロフィール画像を読み込む
    /// - Parameter path: 画像のパス
    private func loadProfileImage(from path: String) {
        Task {
            if let image = await ImageLoader.loadProfileImage(from: path) {
                await MainActor.run {
                    self.profileImage = image
                }
            }
        }
    }
}

#Preview("マッチ成功") {
    ZStack {
        LinearGradient(
            colors: [
                Theme.primaryColor.opacity(0.3),
                Theme.accentColor.opacity(0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        MatchFoundView(
            matchedUser: User(
                id: 99,
                name: "さくら",
                email: "sakura@example.com",
                genderType: 1,
                age: 25,
                imagePath: nil,
                profile: nil,
                appleUserId: nil,
                deviceId: nil,
                pushToken: nil,
                lastLoginedAt: nil,
                createdAt: Date(),
                updatedAt: Date(),
                deletedAt: nil
            ),
            onAccept: {},
            onDecline: {},
            isWaitingForOtherUser: false,
            otherUserAccepted: false
        )
    }
}