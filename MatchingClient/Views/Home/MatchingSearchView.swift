import SwiftUI

/// マッチング検索画面（フルスクリーン）
struct MatchingSearchView: View {
    @Binding var isPresented: Bool
    @ObservedObject var matchingViewModel: MatchingViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    let selectedGender: Gender?
    let ageRange: ClosedRange<Double>
    let distance: Double
    
    @State private var rotationAngle = 0.0
    @State private var pulseScale = 1.0
    @State private var matchFound = false
    @State private var matchingTask: Task<Void, Never>?
    @State private var showCallView = false
    @State private var isInitialLoad = true  // 初回ロードフラグ
    
    var body: some View {
        ZStack {
            // 通話画面表示時は通話画面のみを表示
            if showCallView,
               let roomId = matchingViewModel.roomId,
               let user = matchingViewModel.matchedUser {
                CallInProgressView(
                    roomName: roomId,
                    displayName: user.name,
                    userId: authViewModel.currentUser?.id,  // 自分のユーザーID
                    otherUserId: user.id,  // 相手のユーザーID
                    otherUser: user,  // 相手のユーザー情報
                    showCallView: $showCallView,
                    showMatchingSearch: $isPresented
                )
                .onAppear {
                    // SkyWayトークンを設定
                    if let token = matchingViewModel.skywayToken {
                        SkyWayManager.shared.setAuthToken(token)
                    }
                }
                .onDisappear {
                    // 通話画面から戻った時の処理
                    // showCallViewがfalseかつisPresentedもfalseの場合のみ、通話が終了したと判断
                    // （ユーザーが明示的に終了ボタンを押した場合）
                    if !showCallView && !isPresented {
                        Task {
                            // マッチング状態をリセット
                            await matchingViewModel.resetMatching()
                        }
                    }
                }
                .transition(.opacity)
            } else {
                // マッチング画面の表示
                matchingContent
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showCallView)
    }
    
    @ViewBuilder
    private var matchingContent: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                colors: [
                    Theme.primaryColor.opacity(0.3),
                    Theme.accentColor.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if matchingViewModel.matchedUser == nil {
                // マッチング中の表示
                VStack(spacing: 50) {
                    // キャンセルボタン（右上）
                    HStack {
                        Spacer()
                        Button(action: {
                            cancelMatching()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    // アニメーションアイコン
                    SearchingAnimationView(
                        rotationAngle: $rotationAngle,
                        pulseScale: $pulseScale
                    )
                    
                    // テキスト
                    VStack(spacing: 16) {
                        Text("マッチング中...")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("素敵な相手を探しています")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    // キャンセルボタン（下部）
                    Button(action: {
                        cancelMatching()
                    }) {
                        Text("キャンセル")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Theme.primaryColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(Color.white)
                            )
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                }
            } else if matchingViewModel.matchedUser != nil && !showCallView {
                // マッチ成功時の表示（通話画面に遷移していない場合のみ）
                MatchFoundView(
                    matchedUser: matchingViewModel.matchedUser,
                    onAccept: acceptMatch,
                    onDecline: declineMatch,
                    isWaitingForOtherUser: matchingViewModel.matchingState.isSelfAccepted,
                    otherUserAccepted: matchingViewModel.matchingState.isOtherAccepted
                )
                .id(matchingViewModel.matchedUser?.id)  // ユーザーIDでビューを識別
            }
        }
        .onAppear {
            // 画面表示時に前の状態を完全にリセット
            Task { @MainActor in
                // 通話画面から戻ってきた場合を除き、状態をリセット
                if !showCallView {
                    // 前のマッチング状態をクリア
                    await matchingViewModel.resetMatching()
                    // フラグをリセット
                    matchFound = false
                    showCallView = false
                    // アニメーション値もリセット
                    rotationAngle = 0
                    pulseScale = 1.0
                }
            }
            
            // アニメーションを開始
            startSearchAnimation()
            
            // 初回ロード時のみ遅延してマッチング開始
            if isInitialLoad {
                isInitialLoad = false
                startDelayedMatching(delaySeconds: 2)  // 3秒から2秒に短縮
            }
        }
        .onChange(of: matchingViewModel.matchingState) { _, newState in
            // マッチング状態が変わったときのアニメーション確認
            if case .searching = newState, !showCallView {
                // マッチング中の表示に戻った場合、アニメーションを再開
                startSearchAnimation()
            }
        }
        .onDisappear {
            // 画面を離れる時にタスクをキャンセル
            matchingTask?.cancel()
            matchingTask = nil
            // アニメーションも停止
            withAnimation(.default) {
                rotationAngle = 0
                pulseScale = 1.0
            }
        }
        .alert("エラー", isPresented: .constant(matchingViewModel.errorMessage != nil)) {
            Button("OK") {
                matchingViewModel.errorMessage = nil
            }
        } message: {
            Text(matchingViewModel.errorMessage ?? "")
        }
        .onReceive(matchingViewModel.$shouldRestartMatching) { shouldRestart in
            // 拒否された側の自動再マッチング
            if shouldRestart {
                // すでに実行中のタスクがあればキャンセル
                matchingTask?.cancel()
                
                // フラグをリセット（次回の変更を防ぐ）
                DispatchQueue.main.async {
                    matchingViewModel.shouldRestartMatching = false
                }
                
                // マッチ成功画面から検索画面に戻す
                withAnimation(.spring()) {
                    matchFound = false
                }
                
                // アニメーションを開始
                startSearchAnimation()
                
                // 2秒後に再マッチング開始
                startDelayedMatching(delaySeconds: 2)
            }
        }
        .onChange(of: matchingViewModel.matchingState) { _, newState in
            // 両者が承認した場合のみ通話画面へ遷移
            if case .bothAccepted = newState {
                print("Both users accepted - transitioning to call view")
                // アニメーションを停止
                stopSearchAnimation()
                // マッチングタスクをキャンセル
                matchingTask?.cancel()
                matchingTask = nil
                // 通話画面へ遷移（アニメーション付き）
                withAnimation(.easeInOut(duration: 0.5)) {
                    showCallView = true
                }
            }
        }
    }
    
    /// マッチングキャンセル
    private func cancelMatching() {
        // 実行中のマッチングタスクをキャンセル
        matchingTask?.cancel()
        
        Task {
            // すでにマッチング開始していた場合はキャンセルAPIを呼ぶ
            if matchingViewModel.isMatching || matchingViewModel.roomId != nil {
                await matchingViewModel.cancelMatching()
            }
            
            withAnimation(.easeInOut(duration: 0.3)) {
                isPresented = false
            }
        }
    }
    
    /// アニメーション開始
    private func startSearchAnimation() {
        // 現在のアニメーション値をリセット
        rotationAngle = 0
        pulseScale = 1.0
        
        // パルスアニメーションのみ（回転なし）
        withAnimation(
            Animation.easeInOut(duration: 2)
                .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.3
        }
    }
    
    private func stopSearchAnimation() {
        // アニメーションを停止
        withAnimation(.easeOut(duration: 0.3)) {
            rotationAngle = 0
            pulseScale = 1.0
        }
    }
    
    /// マッチ承認
    private func acceptMatch() {
        guard let user = matchingViewModel.matchedUser,
              let roomId = matchingViewModel.roomId else { return }
        
        Task {
            await matchingViewModel.acceptMatching(userId: user.id, roomId: roomId)
            // エラーメッセージがある場合はアラートで表示される
        }
    }
    
    /// 遅延後にマッチングを開始
    /// - Parameter delaySeconds: 遅延時間（秒）
    private func startDelayedMatching(delaySeconds: Int) {
        // 既存のタスクがあればキャンセル
        matchingTask?.cancel()
        
        matchingTask = Task {
            do {
                // 指定された秒数待機
                try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
                
                // タスクがキャンセルされていない場合のみ実行
                if !Task.isCancelled {
                    // APIを呼び出してマッチング開始
                    await matchingViewModel.startMatching(
                        genderType: selectedGender,
                        ageRange: ageRange,
                        distance: distance
                    )
                    
                    // マッチング相手が見つかった場合はmatchFoundをtrueに
                    if matchingViewModel.matchedUser != nil {
                        withAnimation(.spring()) {
                            matchFound = true
                        }
                    }
                }
            } catch {
                // タスクがキャンセルされた場合は何もしない
                print("Matching task was cancelled")
            }
        }
    }
    
    /// マッチ拒否
    private func declineMatch() {
        guard let user = matchingViewModel.matchedUser,
              let roomId = matchingViewModel.roomId else { return }
        
        Task {
            await matchingViewModel.rejectMatching(userId: user.id, roomId: roomId)
            
            // 画面をマッチング検索中に戻す
            withAnimation(.spring()) {
                matchFound = false
            }
            
            // 画面遷移後にアニメーションを開始
            startSearchAnimation()
            
            // 画面遷移後に2秒待機してから再度マッチング開始
            startDelayedMatching(delaySeconds: 2)
        }
    }
}

/// マッチング中のアニメーションビュー
struct SearchingAnimationView: View {
    @Binding var rotationAngle: Double
    @Binding var pulseScale: Double
    
    var body: some View {
        ZStack {
            // パルスエフェクト
            ForEach(0..<3) { index in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.5 - Double(index) * 0.15),
                                Color.white.opacity(0.2 - Double(index) * 0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(
                        width: 150 + CGFloat(index) * 40,
                        height: 150 + CGFloat(index) * 40
                    )
                    .scaleEffect(pulseScale)
                    .opacity(1.0 - Double(index) * 0.3)
            }
            
            // 中心のアイコン
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(Theme.buttonGradient)
            }
        }
    }
}

#Preview("マッチング検索中") {
    MatchingSearchView(
        isPresented: .constant(true),
        matchingViewModel: MatchingViewModel(),
        selectedGender: nil,
        ageRange: 18.0...35.0,
        distance: 10.0
    )
    .environmentObject(AuthViewModel())
}
