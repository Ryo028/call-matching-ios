import SwiftUI
import SkyWayRoom
import Combine

struct CallInProgressView: View {
    let roomName: String
    let displayName: String
    let userId: Int?  // 自分のユーザーID
    let otherUserId: Int?  // 相手のユーザーID
    let otherUser: User?  // 相手のユーザー情報
    @Binding var showCallView: Bool
    @Binding var showMatchingSearch: Bool  // マッチング検索画面の表示状態を追加
    
    @StateObject private var viewModel = CallInProgressViewModel()
    @StateObject private var timerManager = TimerManager()
    @Environment(\.dismiss) private var dismiss
    private let pusherManager = PusherManager.shared
    
    @State private var profileImage: UIImage? = nil  // 相手のプロフィール画像
    
    // ローカルビデオのドラッグ用
    @State private var localVideoPosition = CGPoint(x: UIScreen.main.bounds.width - 70, y: 150)  // ノッチを確実に避ける位置
    @State private var isDragging = false
    @State private var dragOffset = CGSize.zero
    @State private var safeAreaInsets = EdgeInsets()
    
    // 通話終了画面への遷移
    @State private var showCallEndView = false
    @State private var finalCallDuration = "00:00"  // 通話終了時の時間を保存
    
    // HalfModal関連の状態
    @State private var isShowContinueDialog = false
    @State private var isContinueMode = false
    @State private var isContinueOfCall = false
    @State private var isRemoteContinueOfCall = false  // 相手が継続希望か
    @State private var hasAnsweredContinue = false  // 継続確認に回答済みか
    private let firstTimeLimit: Double = 15  // 最初の制限時間（秒）
    
    var body: some View {
        ZStack {
            if showCallEndView {
                // 通話終了画面を表示
                CallEndView(
                    callDuration: finalCallDuration,
                    otherUserName: displayName,
                    showCallView: $showCallView,
                    showCallEndView: $showCallEndView,
                    showMatchingSearch: $showMatchingSearch
                )
                .onAppear {
                    // 通話終了画面が表示されたら、リソースをクリーンアップ
                    timerManager.stop()
                }
            } else {
                // 通話中の画面を表示
                callInProgressContent
            }
        }
    }
    
    @ViewBuilder
    private var callInProgressContent: some View {
        ZStack {
            // 背景色
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 通話時間表示（カウントダウンまたはカウントアップ）
                Text(isContinueMode ? timerManager.countText : "残り時間 \(timerManager.countText)")
                    .foregroundColor(.white)
                    .font(.monospaced(.title2)())
                    .fontWeight(.bold)
                    .padding(.top, 60)
                    .padding(.bottom, 30)
                
                // プロフィール表示エリア
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        ZStack {
                            // グラデーション背景の角丸
                            Rectangle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.purple.opacity(0.9), Color.pink.opacity(0.9)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: geometry.size.width - 100, height: geometry.size.width - 100)
                                .cornerRadius(geometry.size.width * 0.2)
                                .rotationEffect(.degrees(-10))
                            
                            // ビデオまたはプレースホルダー
                            if let remoteStream = viewModel.remoteVideoStreams.first {
                                VideoStreamView(stream: remoteStream)
                                    .frame(width: geometry.size.width - 110, height: geometry.size.width - 110)
                                    .cornerRadius(geometry.size.width * 0.2)
                                    .rotationEffect(.degrees(5))
                            } else {
                                // プロフィール画像またはプレースホルダーを表示
                                if let profileImage = profileImage {
                                    Image(uiImage: profileImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: geometry.size.width - 110, height: geometry.size.width - 110)
                                        .clipShape(RoundedRectangle(cornerRadius: geometry.size.width * 0.2))
                                        .rotationEffect(.degrees(5))
                                } else {
                                    RoundedRectangle(cornerRadius: geometry.size.width * 0.2)
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: geometry.size.width - 110, height: geometry.size.width - 110)
                                    .overlay(
                                        VStack {
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 60))
                                                .foregroundColor(.white.opacity(0.8))
                                            Text("接続中...")
                                                .foregroundColor(.white.opacity(0.8))
                                                .font(.headline)
                                        }
                                    )
                                    .rotationEffect(.degrees(5))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        // ユーザー名
                        Text(displayName)
                            .foregroundColor(.white)
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.top, 30)
                        
                        // 参加者数
                        Text("参加者: \(viewModel.participantCount)")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.callout)
                            .padding(.top, 5)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // ボタンコントロール
                HStack {
                    Spacer()
                    
                    // ミュートボタン
                    Button(action: {
                        viewModel.toggleMute()
                    }) {
                        Image(systemName: viewModel.isMuted ? "mic.slash.fill" : "mic.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white)
                    }
                    .frame(width: 70, height: 70)
                    .background(
                        Circle()
                            .fill(viewModel.isMuted ? Color.red.opacity(0.7) : Color.black.opacity(0.5))
                    )
                    
                    Spacer(minLength: 10)
                    
                    // スピーカーボタン
                    Button(action: {
                        viewModel.toggleSpeaker()
                    }) {
                        Image(systemName: viewModel.isSpeakerEnabled ? "speaker.wave.3.fill" : "speaker.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white)
                    }
                    .frame(width: 70, height: 70)
                    .background(viewModel.isSpeakerEnabled ? Color.blue.opacity(0.6) : Color.white.opacity(0.3))
                    .clipShape(Circle())
                    
                    Spacer(minLength: 10)
                    
                    // 通話終了ボタン
                    Button(action: {
                        Task {
                            finalCallDuration = viewModel.callDuration
                            await viewModel.endCall()
                            showCallEndView = true
                        }
                    }) {
                        Rectangle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [Color.red, Color.red.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .overlay {
                                Image(systemName: "phone.down.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 35, height: 35)
                                    .foregroundColor(.white)
                            }
                    }
                    .frame(width: 70, height: 70)
                    .clipShape(Circle())
                    
                    Spacer(minLength: 10)
                    
                    // カメラボタン
                    Button(action: {
                        viewModel.toggleCamera()
                    }) {
                        Image(systemName: viewModel.isVideoEnabled ? "video.fill" : "video.slash.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white)
                    }
                    .frame(width: 70, height: 70)
                    .background(viewModel.isVideoEnabled ? Color.green.opacity(0.6) : Color.white.opacity(0.3))
                    .clipShape(Circle())
                    
                    Spacer(minLength: 10)
                    
                    // カメラ切り替えボタン
                    Button(action: {
                        viewModel.switchCamera()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "camera.rotate")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                            Text(viewModel.isUsingFrontCamera ? "前" : "後")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 70, height: 70)
                    .background(Color.white.opacity(0.3))
                    .clipShape(Circle())
                    .disabled(!viewModel.isVideoEnabled)
                    .opacity(viewModel.isVideoEnabled ? 1.0 : 0.5)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0), Color.black.opacity(0.6)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 200)
                    .offset(y: 50)
                )
            }
            
            // ローカルビデオ（ドラッグ可能）
            if let localStream = viewModel.localVideoStream {
                VideoStreamView(stream: localStream)
                    .frame(width: 120, height: 160)
                    .background(Color.black)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isDragging ? Color.blue : Color.white, lineWidth: isDragging ? 2 : 1)
                    )
                    .scaleEffect(isDragging ? 1.05 : 1.0)
                    .position(
                        x: localVideoPosition.x + dragOffset.width,
                        y: localVideoPosition.y + dragOffset.height
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !isDragging {
                                    isDragging = true
                                }
                                dragOffset = value.translation
                            }
                            .onEnded { value in
                                // 最終位置を計算
                                let newX = localVideoPosition.x + value.translation.width
                                let newY = localVideoPosition.y + value.translation.height
                                
                                // 画面内に収まるように制限
                                let minX: CGFloat = 60
                                let maxX = UIScreen.main.bounds.width - 60
                                let minY: CGFloat = 120
                                let maxY = UIScreen.main.bounds.height - 120
                                
                                // 位置を更新（制限内で）
                                localVideoPosition.x = min(max(newX, minX), maxX)
                                localVideoPosition.y = min(max(newY, minY), maxY)
                                
                                // リセット
                                dragOffset = .zero
                                isDragging = false
                            }
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dragOffset)
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .statusBar(hidden: true)
        .background(
            GeometryReader { geometry in
                Color.clear.onAppear {
                    safeAreaInsets = geometry.safeAreaInsets
                    // 初期位置を画面右上に設定（ノッチを確実に避ける）
                    let safeTop = max(geometry.safeAreaInsets.top, 50)
                    let topOffset = safeTop + 80  // ノッチ/Dynamic Island + 80ptの余白
                    localVideoPosition = CGPoint(x: UIScreen.main.bounds.width - 70, y: topOffset)
                }
            }
        )
        .sheet(isPresented: $isShowContinueDialog) {
            HalfModal(
                onYes: {
                    // 通話を継続したい
                    hasAnsweredContinue = true
                    isContinueOfCall = true
                    Log.info("User selected YES to continue call - isContinueOfCall: \(isContinueOfCall)", category: .general)
                    Log.info("Current userId: \(userId ?? -1), otherUserId: \(otherUserId ?? -1)", category: .general)
                    continueCall()
                    
                    // 現在は相手の選択を確認できないため、
                    // タイマーのタイムアウトを待つ
                },
                onNo: {
                    hasAnsweredContinue = true
                    isContinueOfCall = false
                    print("User selected NO to continue call")
                    
                    // NOを選択した場合はAPIを呼ばない
                    // サーバーはタイムアウトまたは無応答として処理
                    Log.info("User selected NO - not sending API request", category: .ui)
                    
                    // NOを選択してもすぐには通話を終了しない
                    // タイマーのタイムアウトを待つ
                },
                timeManager: timerManager
            )
            .presentationDetents([.fraction(0.4)])
            .presentationBackground(.clear)
        }
        .onAppear {
            // プロフィール画像を読み込む
            if let imagePath = otherUser?.imagePath {
                loadProfileImage(from: imagePath)
            }
            
            Task {
                do {
                    // SkyWayを初期化
                    try await SkyWayManager.shared.initialize()
                    // ルームに参加（ユーザーIDを使用）
                    let memberName = userId != nil ? "user_\(userId!)" : "user_\(UUID().uuidString.prefix(8))"
                    Log.info("Joining room: \(roomName) as \(memberName)", category: .network)
                    try await SkyWayManager.shared.joinRoom(roomName: roomName, memberName: memberName)
                    // ビデオストリームを公開
                    try await SkyWayManager.shared.publishVideoStream()
                    // ViewModelのセットアップ
                    viewModel.setupCall()
                } catch {
                    Log.error("Failed to setup call: \(error)", category: .network)
                    
                    // Publishing timeoutエラーの場合は、通話を継続
                    if let skyWayError = error as? SkyWayError, skyWayError == .publishTimeout {
                        Log.warning("オーディオ公開に失敗しましたが、通話を継続します", category: .network)
                        // 通話は継続するので、dismissしない
                        // ViewModelのセットアップは継続
                        viewModel.setupCall()
                    } else {
                        // その他のエラーの場合は通話を終了
                        await viewModel.endCall()
                        dismiss()
                    }
                }
            }
            // タイマー開始（最初は15秒、残り10秒で通知）
            timerManager.start(seconds: firstTimeLimit, reservationTime: 10)
            
            // Pusherイベントを購読
            setupPusherSubscriptions()
        }
        .onReceive(timerManager.$isTimeout) { isTimeout in
            Log.debug("onReceive isTimeout: \(isTimeout), isContinueMode: \(isContinueMode)", category: .general)
            if isTimeout {
                // タイムアウトした場合
                Log.info("Timer timeout detected - Continue mode: \(isContinueMode)", category: .general)
                Log.info("Self wants to continue: \(isContinueOfCall), Remote wants to continue: \(isRemoteContinueOfCall)", category: .general)
                Log.info("Has answered: \(hasAnsweredContinue)", category: .general)
                
                // ダイアログが表示中の場合は強制的に閉じる
                if isShowContinueDialog {
                    isShowContinueDialog = false
                }
                
                // 継続モードでないときのタイムアウト（最初の15秒後）
                if !isContinueMode {
                    // 相手の応答を待つ（ネットワーク遅延を考慮して3秒待つ）
                    Task {
                        // 3秒間、0.5秒ごとに相手の応答をチェック
                        for i in 0..<6 {
                            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒待つ
                            
                            // 相手の応答が来たら即座に判定
                            if isRemoteContinueOfCall {
                                Log.info("Remote user responded YES at check \(i+1)", category: .general)
                                if isContinueOfCall && isRemoteContinueOfCall {
                                    // 両者が継続を希望した場合
                                    await MainActor.run {
                                        Log.info("Both users want to continue - entering continue mode", category: .general)
                                        isContinueMode = true
                                        Log.info("Restarting timer in count-up mode", category: .general)
                                        timerManager.start(minutes: 0, seconds: 0, isCountDown: false)  // カウントアップモードで0:00から再開
                                    }
                                } else {
                                    // 自分がNOの場合
                                    Log.info("Call ending - Self: \(isContinueOfCall), Remote: \(isRemoteContinueOfCall)", category: .general)
                                    // 音声/映像を即座に停止して画面遷移
                                    await viewModel.stopStreaming()
                                    await MainActor.run {
                                        finalCallDuration = viewModel.callDuration
                                        showCallEndView = true
                                    }
                                    // バックグラウンドで残りのクリーンアップ
                                    Task.detached(priority: .background) {
                                        await viewModel.cleanupResources()
                                    }
                                }
                                return // 判定完了
                            } else if hasAnsweredContinue && !isRemoteContinueOfCall && i >= 2 {
                                // 相手がNOと回答済みか、2秒経過後は終了
                                break
                            }
                        }
                        
                        // 最終判定（3秒後）
                        Log.info("Final check after 3 seconds - Self: \(isContinueOfCall), Remote: \(isRemoteContinueOfCall)", category: .general)
                        
                        // 両者が継続を希望した場合のみ継続
                        if isContinueOfCall && isRemoteContinueOfCall {
                            // 両者が継続を希望した場合
                            await MainActor.run {
                                Log.info("Both users want to continue - entering continue mode", category: .general)
                                isContinueMode = true
                                Log.info("Restarting timer in count-up mode", category: .general)
                                timerManager.start(minutes: 0, seconds: 0, isCountDown: false)  // カウントアップモードで0:00から再開
                            }
                        } else {
                            // どちらかが継続を希望しなかった、または回答しなかった場合は通話終了
                            Log.info("Call ending - Self: \(isContinueOfCall), Remote: \(isRemoteContinueOfCall)", category: .general)
                            // 音声/映像を即座に停止して画面遷移
                            await viewModel.stopStreaming()
                            await MainActor.run {
                                finalCallDuration = viewModel.callDuration
                                showCallEndView = true
                            }
                            // バックグラウンドで残りのクリーンアップ
                            Task.detached(priority: .background) {
                                await viewModel.cleanupResources()
                            }
                        }
                    }
                } else {
                    // 継続モード中のタイムアウトは発生しないはず（カウントアップモードだから）
                    Log.warning("Unexpected timeout in continue mode", category: .general)
                }
            }
        }
        .onReceive(timerManager.$isReservationTime) { isReservationTime in
            if isReservationTime && !isContinueMode {
                // 指定の残り時間になった場合（継続モードでない場合のみ）
                isShowContinueDialog = true
            }
        }
        .onDisappear {
            // 通話終了画面に遷移する場合は何もしない
            // 完全に画面を閉じる場合のみクリーンアップ
            if !showCallEndView {
                timerManager.stop()  // タイマー停止
                Task {
                    // ビューが消える時は確実にリソースを解放
                    await viewModel.endCall()
                }
            }
        }
        .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
        .onChange(of: viewModel.otherParticipantLeft) { _, left in
            if left {
                Task {
                    // 音声/映像を即座に停止して画面遷移
                    await viewModel.stopStreaming()
                    await MainActor.run {
                        finalCallDuration = viewModel.callDuration
                        showCallEndView = true
                    }
                    // バックグラウンドで残りのクリーンアップ
                    Task.detached(priority: .background) {
                        await viewModel.cleanupResources()
                    }
                }
            }
        }
    }
    
    /// 通話継続のリクエスト
    private func continueCall() {
        // Pusherで通話継続の選択を送信
        if let userId = userId, let otherUserId = otherUserId {
            Log.info("Sending continue call response - userId: \(userId), otherUserId: \(otherUserId), roomId: \(roomName), wantsToContinue: true", category: .general)
            pusherManager.sendCallContinueResponse(roomId: roomName, userId: userId, otherUserId: otherUserId, wantsToContinue: true)
        } else {
            Log.error("Cannot send continue call response - userId or otherUserId is nil", category: .general)
        }
    }
    
    /// Pusherイベントの購読設定
    private func setupPusherSubscriptions() {
        // マッチングチャンネルに購読（通話継続イベントを受信するため）
        pusherManager.subscribeToMatchingChannel(roomId: roomName)
        
        // 通話継続イベントを購読
        pusherManager.callContinueEventPublisher
            .sink { event in
                Log.info("=== CALL CONTINUE EVENT RECEIVED ===", category: .general)
                Log.info("Event userId: \(event.userId), Current userId: \(userId ?? -1), Other userId: \(otherUserId ?? -1)", category: .general)
                Log.info("Wants to continue: \(event.wantsToContinue)", category: .general)
                Log.info("Room ID: \(event.roomId)", category: .general)
                Log.info("Event received at: \(Date())", category: .general)
                
                // 相手からの通話継続選択を受信（otherUserIdと比較）
                if let currentOtherUserId = otherUserId, event.userId == currentOtherUserId {
                    Log.info(">>> Remote user \(event.userId) response: \(event.wantsToContinue ? "YES" : "NO")", category: .general)
                    isRemoteContinueOfCall = event.wantsToContinue
                    Log.info("Updated isRemoteContinueOfCall to: \(isRemoteContinueOfCall)", category: .general)
                    Log.info("Current state - Self: \(isContinueOfCall), Remote: \(isRemoteContinueOfCall)", category: .general)
                    
                    // 相手がNOを選択しても、すぐには反応しない
                    // タイムアウト時に両者の選択を確認して処理する
                } else if let currentUserId = userId, event.userId == currentUserId {
                    Log.info("<<< Ignoring own event from userId: \(event.userId)", category: .general)
                } else {
                    Log.warning("Unexpected userId in event. Event userId: \(event.userId), Current: \(userId ?? -1), Other: \(otherUserId ?? -1)", category: .general)
                }
            }
            .store(in: &viewModel.cancellables)
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

/// HalfModal - 通話継続確認ダイアログ
struct HalfModal: View {
    
    var onYes: (() -> Void)?
    var onNo: (() -> Void)?
    
    @ObservedObject var timeManager: TimerManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Theme.accentColor, Theme.accentColor.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .cornerRadius(15)
                .padding(20)
            VStack {
                Text("残り時間が１分を切りました。\n続けてトークしたいですか？")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 5)
                Text("\(Int(timeManager.count))秒")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 30)
                HStack {
                    Spacer()
                    // NOボタン
                    DialogButton(name: "NO", onClick: {
                        onNo?()
                        dismiss()
                    })
                    Spacer(minLength: 20)
                    // YESボタン
                    DialogButton(name: "YES", onClick: {
                        onYes?()
                        dismiss()
                    })
                    Spacer()
                }
            }
        }
        // 閉じさせない
        .interactiveDismissDisabled()
    }
    
    struct DialogButton: View {
        var name: String
        var onClick: (() -> Void)?
        var body: some View {
            Button(name) {
                onClick?()
            }
            .frame(maxWidth: 90)
            .padding(.vertical, 12)
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(Theme.primaryColor)
            .background(.white)
            .cornerRadius(10)
        }
    }
}

// ビデオストリームを表示するためのUIViewRepresentable
struct VideoStreamView: UIViewRepresentable {
    typealias UIViewType = VideoView
    typealias Context = UIViewRepresentableContext<Self>
    
    class Cordinator: NSObject {
        let view: VideoStreamView
        init(view: VideoStreamView) {
            self.view = view
        }
    }
    
    var stream: VideoStreamProtocol
    
    func makeUIView(context: Context) -> VideoView {
        let view = VideoView()
        view.videoContentMode = .scaleAspectFill
        return view
    }
    
    func updateUIView(_ uiView: VideoView, context: Context) {
        stream.attach(uiView)
    }
    
    func makeCoordinator() -> Cordinator {
        return Cordinator(view: self)
    }
    
    static func dismantleUIView(_ uiView: VideoView, coordinator: Cordinator) {
        coordinator.view.stream.detach(uiView)
    }
}

// MARK: - Preview
// Preview用のモックView
struct CallInProgressPreviewView: View {
    let roomName: String
    let displayName: String
    
    @State private var isMuted = false
    @State private var isVideoEnabled = true
    @State private var isSpeakerEnabled = false
    @State private var isUsingFrontCamera = true
    @State private var participantCount = 2
    @State private var callDuration = "03:45"
    @State private var showEndCallAlert = false
    
    var body: some View {
        ZStack {
            // 背景色
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 通話時間表示
                Text(callDuration)
                    .foregroundColor(.white)
                    .font(.monospaced(.title2)())
                    .fontWeight(.bold)
                    .padding(.top, 60)
                    .padding(.bottom, 30)
                
                // プロフィール表示エリア
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        ZStack {
                            // グラデーション背景の角丸
                            Rectangle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.purple.opacity(0.9), Color.pink.opacity(0.9)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: geometry.size.width - 100, height: geometry.size.width - 100)
                                .cornerRadius(geometry.size.width * 0.2)
                                .rotationEffect(.degrees(-10))
                            
                            // プレースホルダー
                            RoundedRectangle(cornerRadius: geometry.size.width * 0.2)
                                .fill(Color.white.opacity(0.2))
                                .frame(width: geometry.size.width - 110, height: geometry.size.width - 110)
                                .overlay(
                                    VStack {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 60))
                                            .foregroundColor(.white.opacity(0.8))
                                        Text("相手の映像")
                                            .foregroundColor(.white.opacity(0.8))
                                            .font(.headline)
                                    }
                                )
                                .rotationEffect(.degrees(5))
                        }
                        .frame(maxWidth: .infinity)
                        
                        // ユーザー名
                        Text(displayName)
                            .foregroundColor(.white)
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.top, 30)
                        
                        // 参加者数
                        Text("参加者: \(participantCount)")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.callout)
                            .padding(.top, 5)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // ボタンコントロール
                HStack {
                    Spacer()
                    
                    // ミュートボタン
                    Button(action: {
                        isMuted.toggle()
                    }) {
                        Image(systemName: isMuted ? "mic.slash.fill" : "mic.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white)
                    }
                    .frame(width: 70, height: 70)
                    .background(Color.white.opacity(0.3))
                    .clipShape(Circle())
                    
                    Spacer(minLength: 10)
                    
                    // スピーカーボタン
                    Button(action: {
                        isSpeakerEnabled.toggle()
                    }) {
                        Image(systemName: isSpeakerEnabled ? "speaker.wave.3.fill" : "speaker.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white)
                    }
                    .frame(width: 70, height: 70)
                    .background(isSpeakerEnabled ? Color.blue.opacity(0.6) : Color.white.opacity(0.3))
                    .clipShape(Circle())
                    
                    Spacer(minLength: 10)
                    
                    // 通話終了ボタン
                    Button(action: {
                        showEndCallAlert = true
                    }) {
                        Rectangle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [Color.red, Color.red.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .overlay {
                                Image(systemName: "phone.down.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 35, height: 35)
                                    .foregroundColor(.white)
                            }
                    }
                    .frame(width: 70, height: 70)
                    .clipShape(Circle())
                    
                    Spacer(minLength: 10)
                    
                    // カメラボタン
                    Button(action: {
                        isVideoEnabled.toggle()
                    }) {
                        Image(systemName: isVideoEnabled ? "video.fill" : "video.slash.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white)
                    }
                    .frame(width: 70, height: 70)
                    .background(isVideoEnabled ? Color.green.opacity(0.6) : Color.white.opacity(0.3))
                    .clipShape(Circle())
                    
                    Spacer(minLength: 10)
                    
                    // カメラ切り替えボタン
                    Button(action: {
                        isUsingFrontCamera.toggle()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "camera.rotate")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                            Text(isUsingFrontCamera ? "前" : "後")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 70, height: 70)
                    .background(Color.white.opacity(0.3))
                    .clipShape(Circle())
                    .disabled(!isVideoEnabled)
                    .opacity(isVideoEnabled ? 1.0 : 0.5)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            
            // ローカルビデオ（プレビュー用）
            if isVideoEnabled {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 120, height: 160)
                    .overlay(
                        VStack {
                            Image(systemName: "person.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white.opacity(0.8))
                            Text("自分")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white, lineWidth: 1)
                    )
                    .position(x: UIScreen.main.bounds.width - 70, y: 180)
            }
        }
        .navigationBarHidden(true)
        .alert("通話を終了しますか？", isPresented: $showEndCallAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("終了", role: .destructive) {
                // Preview用のアクション
            }
        }
    }
}

struct CallInProgressView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // 通話中の状態
            CallInProgressPreviewView(
                roomName: "会議室 A",
                displayName: "山田太郎"
            )
            .previewDisplayName("通話中")
            
            // ダークモード
            CallInProgressPreviewView(
                roomName: "プロジェクトX",
                displayName: "鈴木花子"
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("ダークモード")
            
            // iPadサイズ
            CallInProgressPreviewView(
                roomName: "営業ミーティング",
                displayName: "佐藤次郎"
            )
            .previewDevice(PreviewDevice(rawValue: "iPad Pro (11-inch) (4th generation)"))
            .previewDisplayName("iPad")
        }
    }
}
