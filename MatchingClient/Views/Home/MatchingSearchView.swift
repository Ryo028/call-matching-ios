import SwiftUI

/// マッチング画面の状態
enum MatchingScreenState {
    case initial                    // 初期状態
    case searching                  // マッチング検索中
    case matchFound                 // マッチ発見（承認待ち）
    case waitingForOtherUser       // 相手の承認待ち
    case inCall                    // 通話中
    case completed                 // 完了（画面を閉じる）
}

/// マッチング検索画面（フルスクリーン）
struct MatchingSearchView: View {
    @Binding var isPresented: Bool
    @ObservedObject var matchingViewModel: MatchingViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    let selectedGender: Gender?
    let ageRange: ClosedRange<Double>
    let distance: Double
    
    @State private var screenState: MatchingScreenState = .initial
    @State private var rotationAngle = 0.0
    @State private var pulseScale = 1.0
    @State private var matchingTask: Task<Void, Never>?
    
    var body: some View {
        ZStack {
            // 状態に応じて画面を切り替え
            switch screenState {
            case .inCall:
                // 通話画面
                if let roomId = matchingViewModel.matchingState.roomId,
                   let user = matchingViewModel.matchingState.matchedUser {
                    CallInProgressView(
                        roomName: roomId,
                        displayName: user.name,
                        userId: authViewModel.currentUser?.id,  // 自分のユーザーID
                        otherUserId: user.id,  // 相手のユーザーID
                        otherUser: user,  // 相手のユーザー情報
                        showCallView: Binding(
                            get: { screenState == .inCall },
                            set: { if !$0 { screenState = .completed } }
                        ),
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
                        if screenState == .completed {
                            Task {
                                // マッチング状態をリセット
                                await matchingViewModel.resetMatching()
                                // 画面を閉じる
                                if !isPresented {
                                    screenState = .initial
                                }
                            }
                        }
                    }
                    .transition(.opacity)
                }
            default:
                // マッチング画面の表示
                matchingContent
            }
        }
        .animation(.easeInOut(duration: 0.5), value: screenState)
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
            
            if matchingViewModel.matchingState.matchedUser == nil {
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
            } else if screenState == .matchFound || screenState == .waitingForOtherUser {
                // マッチ成功時の表示（通話画面に遷移していない場合のみ）
                MatchFoundView(
                    matchedUser: matchingViewModel.matchingState.matchedUser,
                    onAccept: acceptMatch,
                    onDecline: declineMatch,
                    isWaitingForOtherUser: matchingViewModel.matchingState.isSelfAccepted,
                    otherUserAccepted: matchingViewModel.matchingState.isOtherAccepted
                )
                .id(matchingViewModel.matchingState.matchedUser?.id)  // ユーザーIDでビューを識別
            }
        }
        .onAppear {
            // 通話中は何もしない
            if screenState == .inCall {
                return
            }
            
            // 初期状態の場合
            if screenState == .initial {
                // 画面表示時に前の状態を完全にリセット
                Task { @MainActor in
                    // 前のマッチング状態をクリア
                    await matchingViewModel.resetMatching()
                    // アニメーション値もリセット
                    rotationAngle = 0
                    pulseScale = 1.0
                    
                    // 状態を検索中に変更
                    screenState = .searching
                }
                
                // アニメーションを開始
                startSearchAnimation()
                
                // 遅延してマッチング開始
                startDelayedMatching(delaySeconds: 2)
            } else if screenState == .searching {
                // 検索中の場合はアニメーションのみ再開
                startSearchAnimation()
            }
        }
        .onChange(of: matchingViewModel.matchingState) { _, newState in
            // ViewModelの状態に基づいて画面状態を更新
            switch newState {
            case .idle:
                if screenState != .inCall {
                    screenState = .initial
                }
            case .searching:
                if screenState != .inCall {
                    screenState = .searching
                    startSearchAnimation()
                }
            case .matched:
                if screenState != .inCall {
                    screenState = .matchFound
                }
            case .selfAccepted:
                screenState = .waitingForOtherUser
            case .otherAccepted:
                // 相手が先に承認した場合
                if screenState != .inCall {
                    screenState = .matchFound
                }
            case .bothAccepted:
                // 通話画面へ即座に遷移
                screenState = .inCall
            case .rejected:
                // 拒否された場合は検索状態に戻る
                screenState = .searching
                startSearchAnimation()
            case .error:
                // エラーの場合は初期状態に戻る
                screenState = .initial
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
                    // 状態はすでに.searchingに設定済み
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
                
                // 通話開始時にユーザーチャンネルの購読を解除（通話中はルームチャンネルを使用）
                if let userId = authViewModel.currentUser?.id {
                    PusherManager.shared.unsubscribe(from: NotificationConstants.PusherChannel.userChannel(userId: userId))
                    Log.info("Unsubscribed from user channel - will use room channel during call", category: .network)
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
            if matchingViewModel.matchingState.isSearching || matchingViewModel.matchingState.roomId != nil {
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
        guard let user = matchingViewModel.matchingState.matchedUser,
              let roomId = matchingViewModel.matchingState.roomId else { return }
        
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
                    
                    // マッチング相手が見つかった場合は状態を更新
                    if matchingViewModel.matchingState.matchedUser != nil {
                        withAnimation(.spring()) {
                            screenState = .matchFound
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
        guard let user = matchingViewModel.matchingState.matchedUser,
              let roomId = matchingViewModel.matchingState.roomId else { return }
        
        Task {
            await matchingViewModel.rejectMatching(userId: user.id, roomId: roomId)
            
            // 画面をマッチング検索中に戻す
            withAnimation(.spring()) {
                screenState = .searching
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
