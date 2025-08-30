import Foundation
import SkyWayRoom
import AVFoundation
import AVKit

@MainActor
final class SkyWayManager: NSObject, ObservableObject {
    static let shared = SkyWayManager()
    
    private var authToken: String = ""
    
    private var room: P2PRoom?
    private var localMember: LocalRoomMember?
    
    // Contextの初期化状態を管理
    private var isContextInitialized = false
    
    @Published var isConnected = false
    @Published var localVideoStream: LocalVideoStream?
    @Published var localAudioStream: LocalAudioStream?
    @Published var remoteVideoStreams: [RemoteVideoStream] = []
    @Published var remotePublications: [RoomPublication] = []
    @Published var localSubscriptions: [RoomSubscription] = []
    
    // ミュートとカメラの状態を管理
    @Published var isMuted = false
    @Published var isCameraEnabled = false  // 初期状態はカメラオフ
    @Published var isUsingFrontCamera = false // フロントカメラを使用しているかどうか
    
    // Publicationの参照を保持
    private var audioPublication: RoomPublication?
    private var videoPublication: RoomPublication?
    
    // ビデオ画質設定（1.0が最高画質、数値が大きいほど低画質）
    enum VideoQuality: Double {
        case high = 1.0      // 高画質
        case medium = 2.0    // 中画質
        case low = 4.0       // 低画質
    }

    @Published var currentVideoQuality: VideoQuality = .medium
    
    private var captureDevice: AVCaptureDevice?
    
    // スピーカー設定
    @Published var isSpeakerEnabled = false
    
    // 相手が退出した時のコールバック
    @MainActor var onOtherParticipantLeft: (() -> Void)?
    
    private override init() {
        super.init()
    }
    
    func setAuthToken(_ token: String) {
        self.authToken = token
    }
    
    func initialize() async throws {
        guard !authToken.isEmpty else {
            throw SkyWayError.noAuthToken
        }
        
        // 既に初期化済みの場合はスキップ
        if isContextInitialized {
            Log.info("SkyWay context already initialized, skipping initialization", category: .network)
            
            // カメラの再起動のみ行う
            let cameras = CameraVideoSource.supportedCameras()
            let backCamera = cameras.first(where: { $0.position == .back })
            let frontCamera = cameras.first(where: { $0.position == .front })
            let camera = backCamera ?? frontCamera
            
            if let camera = camera {
                isUsingFrontCamera = (backCamera == nil && frontCamera != nil)
                do {
                    // 既存のキャプチャを停止してから再開
                    CameraVideoSource.shared().stopCapturing()
                    try await CameraVideoSource.shared().startCapturing(with: camera, options: nil)
                    Log.info("Camera capture restarted", category: .network)
                } catch {
                    Log.error("Failed to restart camera capture: \(error)", category: .network)
                }
            }
            return
        }
        
        let options = ContextOptions()
        
        // AppConfigからログレベルを設定
        if AppConfig.SkyWay.isLoggingEnabled {
            switch AppConfig.SkyWay.logLevel {
            case .error:
                options.logLevel = .error
            case .warn:
                options.logLevel = .warn
            case .info:
                options.logLevel = .info
            case .debug:
                options.logLevel = .debug
            case .trace:
                options.logLevel = .trace
            }
        } else {
            // ログを最小限にする場合はerrorレベルを設定
            options.logLevel = .error
        }
        
        Log.info("Starting SkyWay initialization...", category: .network)
        Log.info("SkyWay log level set to: \(AppConfig.SkyWay.isLoggingEnabled ? AppConfig.SkyWay.logLevel.rawValue : "error (minimal)")", category: .network)
        Log.debug("Auth token: \(String(authToken.prefix(50)))...", category: .network)
        
        do {
            try await Context.setup(withToken: authToken, options: options)
            isContextInitialized = true
            Log.info("Context setup completed", category: .network)
            
            // カメラの初期設定
            let cameras = CameraVideoSource.supportedCameras()
            Log.debug("Available cameras: \(cameras.count)", category: .network)
            
            // デフォルトはバックカメラを使用、なければフロントカメラ
            let backCamera = cameras.first(where: { $0.position == .back })
            let frontCamera = cameras.first(where: { $0.position == .front })
            let camera = backCamera ?? frontCamera
            
            if let camera = camera {
                isUsingFrontCamera = (backCamera == nil && frontCamera != nil)
                Log.info("Starting camera capture...", category: .network)
                try await CameraVideoSource.shared().startCapturing(with: camera, options: nil)
                Log.info("Camera capture started", category: .network)
            } else {
                Log.error("No camera found", category: .network)
            }
            
            print("SkyWay initialized successfully")
            Log.info("SkyWay initialization completed successfully", category: .network)
        } catch {
            print("Failed to initialize SkyWay: \(error)")
            Log.error("Failed to initialize SkyWay: \(error)", category: .network)
            
            // エラーの詳細を記録
            if let nsError = error as NSError? {
                Log.error("Error domain: \(nsError.domain)", category: .network)
                Log.error("Error code: \(nsError.code)", category: .network)
                Log.error("Error userInfo: \(nsError.userInfo)", category: .network)
                
                // Error Code 6の場合、Contextのリセットを試みる
                if nsError.code == 6 {
                    Log.warning("Error Code 6 detected - attempting context reset", category: .network)
                    isContextInitialized = false
                    
                    // 既存のContextを破棄してから再試行
                    do {
                        try await Context.dispose()
                        Log.info("Context disposed for reset", category: .network)
                    } catch {
                        Log.error("Failed to dispose context for reset: \(error)", category: .network)
                    }
                }
            }
            
            throw error
        }
    }
    
    func joinRoom(roomName: String, memberName: String) async throws {
        // Contextが初期化されていることを確認
        guard isContextInitialized else {
            throw SkyWayError.contextNotInitialized
        }
        
        // 既に接続済みの場合は、一度退出してから再入室
        if isConnected && localMember != nil {
            Log.warning("Already connected to a room, leaving first...", category: .network)
            try await leaveRoom()
            // 少し待つ
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        }
        
        // メンバー名にタイムスタンプを追加してユニークにする
        let timestamp = Int(Date().timeIntervalSince1970)
        let uniqueMemberName = "\(memberName)_\(timestamp)"
        
        Log.info("Joining room: \(roomName) as \(uniqueMemberName)", category: .network)
        Log.info("TURN server will be used for NAT traversal if needed", category: .network)
        
        let roomOptions = Room.InitOptions()
        roomOptions.name = roomName
        
        // P2P Roomを作成または検索
        Log.debug("Creating/finding P2P room...")
        room = try await P2PRoom.findOrCreate(with: roomOptions)
        
        guard let room = room else {
            Log.error("Room creation failed")
            throw SkyWayError.roomCreationFailed
        }
        
        // 最大2人まで参加可能（自分を含む）
        if room.members.count >= 2 {
            Log.error("Room is full (max 2 participants)")
            throw SkyWayError.roomIsFull
        }
        
        Log.info("Room created/found successfully", category: .network)
        
        // メンバーとして参加
        let memberOptions = Room.MemberInitOptions()
        memberOptions.name = uniqueMemberName  // ユニークな名前を使用
        
        Log.debug("Joining as member with unique name: \(uniqueMemberName)")
        localMember = try await room.join(with: memberOptions)
        
        // デリゲート設定（joinの後に設定することが重要）
        room.delegate = self
        
        // 既存のPublicationを取得して自動的にSubscribe
        let existingPublications = room.publications.filter { $0.publisher != localMember }
        Log.debug("Existing publications from other members: \(existingPublications.count)")
        
        for publication in existingPublications {
            Task {
                do {
                    _ = try await subscribeToPublication(publication)
                    Log.info("Auto-subscribed to existing publication from: \(publication.publisher?.name ?? "Unknown")", category: .network)
                } catch {
                    Log.error("Failed to subscribe to existing publication: \(error)")
                }
            }
        }
        
        isConnected = true
        print("Joined room: \(roomName) as \(memberName)")
        Log.info("Successfully joined room", category: .network)
    }
    
    func publishVideoStream() async throws {
        guard let localMember = localMember else {
            throw SkyWayError.notJoinedRoom
        }
        
        Log.info("Starting to publish streams...", category: .network)
        
        // マイクパーミッションを事前に確認
        let micPermission = await checkMicrophonePermission()
        if !micPermission {
            Log.error("マイクへのアクセスが許可されていません", category: .network)
            throw SkyWayError.microphonePermissionDenied
        }
        
        // オーディオセッションを設定（デフォルトはイヤホン/通常出力）
        configureSpeaker(enabled: false)
        
        // オーディオストリームを作成して公開
        let audioStream = MicrophoneAudioSource().createStream()
        localAudioStream = audioStream
        
        // Publishing timeout対策：タイムアウトを延長し、エラー時はリトライ
        do {
            // タイムアウトを30秒に設定してpublish実行
            let maxRetries = 2
            var lastError: Error?
            
            for attempt in 1...maxRetries {
                do {
                    Log.info("Publishing audio stream (attempt \(attempt)/\(maxRetries))...", category: .network)
                    
                    // withTimeout関数を使わずに直接publish
                    // SkyWay SDKの内部タイムアウトに依存
                    audioPublication = try await localMember.publish(audioStream, options: nil)
                    
                    Log.info("Published audio stream: \(audioPublication!.id)", category: .network)
                    break // 成功したらループを抜ける
                    
                } catch {
                    lastError = error
                    Log.warning("Audio publication failed (attempt \(attempt)): \(error)", category: .network)
                    
                    // 最後の試行でなければ少し待ってリトライ
                    if attempt < maxRetries {
                        // 短い遅延を入れる（ネットワークの一時的な問題を回避）
                        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2秒
                    }
                }
            }
            
            // すべての試行が失敗した場合
            if audioPublication == nil {
                if let error = lastError {
                    // SkyWayのエラーコード11（Publishing timeout）の場合
                    if (error as NSError).code == 11 {
                        throw SkyWayError.publishTimeout
                    }
                    throw error
                } else {
                    throw SkyWayError.publishTimeout
                }
            }
            
        } catch {
            Log.error("Failed to publish audio stream after all retries: \(error)", category: .network)
            // オーディオ公開に失敗しても、通話を継続できるようにエラーを再スローしない
            // UIに警告を表示するだけに留める
            Log.warning("Continuing without audio due to publishing error", category: .network)
        }
        
        // ビデオは初期状態でオフなので公開しない
        Log.info("Camera is initially disabled, skipping video publication")
        
        print("Stream publishing process completed")
    }
    
    func subscribeToPublication(_ publication: RoomPublication) async throws -> RoomSubscription? {
        guard let localMember = localMember else {
            throw SkyWayError.notJoinedRoom
        }
        
        // 自分のPublicationはスキップ
        guard publication.publisher != localMember else {
            return nil
        }
        
        let options = SubscriptionOptions()
        let subscription = try await localMember.subscribe(publicationId: publication.id, options: options)
        
        localSubscriptions.append(subscription)
        
        // ビデオストリームの場合、リストに追加
        if let videoStream = subscription.stream as? RemoteVideoStream {
            remoteVideoStreams.append(videoStream)
        }
        
        print("Subscribed to publication from: \(publication.publisher?.name ?? "Unknown")")
        return subscription
    }
    
    /// 音声/映像ストリームを即座に停止（画面遷移用の高速処理）
    func stopMediaStreams() async {
        Log.info("=== STOPPING MEDIA STREAMS ===", category: .network)
        
        // 1. ローカルストリームを即座に無効化
        localVideoStream = nil
        localAudioStream = nil
        
        // 2. カメラキャプチャを停止
        await MainActor.run {
            CameraVideoSource.shared().stopCapturing()
        }
        
        // 3. オーディオセッションを非アクティブ化
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        
        // 4. フラグをリセット
        isMuted = false
        isCameraEnabled = false
        isSpeakerEnabled = false
        
        Log.info("=== MEDIA STREAMS STOPPED ===", category: .network)
    }
    
    func leaveRoom() async throws {
        Log.info("=== LEAVING ROOM START ===", category: .network)
        
        // すでに退出済みの場合は何もしない
        guard let localMember = localMember else {
            Log.info("No local member - already left room", category: .network)
            isConnected = false
            return
        }
        
        Log.info("Step 1: Unpublishing streams...", category: .network)
        
        // 1. パブリケーションをアンパブリッシュ
        if let videoPublication = videoPublication {
            // メンバーの状態を確認
            if localMember.state == .joined {
                Log.info("Unpublishing video...", category: .network)
                try? await localMember.unpublish(publicationId: videoPublication.id)
                Log.info("Video unpublished", category: .network)
            }
            self.videoPublication = nil
        }
        if let audioPublication = audioPublication {
            // メンバーの状態を確認
            if localMember.state == .joined {
                Log.info("Unpublishing audio...", category: .network)
                try? await localMember.unpublish(publicationId: audioPublication.id)
                Log.info("Audio unpublished", category: .network)
            }
            self.audioPublication = nil
        }
        
        Log.info("Step 2: Unsubscribing from remote streams...", category: .network)
        
        // 2. サブスクリプションをアンサブスクライブ
        for subscription in localSubscriptions {
            if localMember.state == .joined {
                try? await localMember.unsubscribe(subscriptionId: subscription.id)
            }
        }
        localSubscriptions.removeAll()
        Log.info("All subscriptions removed", category: .network)
        
        Log.info("Step 3: Stopping camera capture and audio session...", category: .network)
        
        // 3. カメラキャプチャを停止
        CameraVideoSource.shared().stopCapturing()
        Log.info("Camera capture stopped", category: .network)
        
        // オーディオセッションを非アクティブ化
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        Log.info("Audio session deactivated", category: .network)
        
        // 4. コールバックとデリゲートを解除
        onOtherParticipantLeft = nil
        room?.delegate = nil
        
        Log.info("Step 4: Leaving room...", category: .network)
        
        // 5. ローカルメンバーをルームから退出
        // leave()はピア接続のクリーンアップを内部で行う
        if localMember.state == .joined {
            try await localMember.leave()
            Log.info("Left room successfully", category: .network)
            // leave()が完了すれば、WebRTCのピア接続は適切にクリーンアップされている
        }
        
        Log.info("Step 5: Disposing room...", category: .network)
        
        // 6. ルームを破棄（leave完了後なので安全）
        if let currentRoom = room {
            // Roomの破棄を試みる（エラーは無視）
            do {
                try await currentRoom.dispose()
                Log.info("Room disposed successfully", category: .network)
            } catch {
                Log.warning("Failed to dispose room (may already be disposed): \(error)", category: .network)
            }
        }
        
        // 7. プロパティをクリア
        // localMemberはローカル変数なので、ここではnilにできない
        // room = nil // これも関数終了時に自動的に解放される
        self.localMember = nil  // クラスのプロパティをクリア
        self.room = nil
        isConnected = false
        localVideoStream = nil
        localAudioStream = nil
        isMuted = false
        isCameraEnabled = false
        
        // 8. コレクションをクリア
        remoteVideoStreams.removeAll()
        remotePublications.removeAll()
        
        // 9. Contextの破棄はここでは行わない
        // Contextはアプリケーション全体で再利用されるため、
        // ルームを退出するたびに破棄するとエラーの原因になる
        
        Log.info("=== LEAVING ROOM COMPLETE === All resources cleaned up", category: .network)
        
        print("Left room and disposed context")
    }
    
    func dispose() async throws {
        // カメラキャプチャを停止
        CameraVideoSource.shared().stopCapturing()
        
        // Contextの破棄はアプリ終了時のみ行う
        // 通常の通話終了では破棄しない
        if isContextInitialized {
            Log.info("Disposing SkyWay context (app termination only)", category: .network)
            do {
                try await Context.dispose()
                isContextInitialized = false
            } catch {
                Log.error("Failed to dispose context: \(error)", category: .network)
            }
        }
    }
    
    // MARK: - Media Control Functions
    
    /// メディア操作が可能な状態かチェック
    private func canPerformMediaOperation() -> Bool {
        // ローカルメンバーの存在確認
        guard let localMember = localMember else {
            Log.error("No local member available")
            return false
        }
        
        // メンバーの状態を確認
        guard localMember.state == .joined else {
            Log.warning("Cannot perform media operation - member not in joined state", category: .network)
            return false
        }
        
        // 接続状態の確認
        guard isConnected else {
            Log.warning("Cannot perform media operation - not connected to room", category: .network)
            return false
        }
        
        // 他のメンバーの存在確認
        if let room = room {
            let otherMembers = room.members.filter { $0 != localMember }
            if otherMembers.isEmpty {
                Log.warning("Cannot perform media operation - no other participants in the room", category: .network)
                return false
            }
        }
        
        return true
    }
    
    func toggleMute() async {
        // メディア操作可能かチェック
        guard canPerformMediaOperation(),
              let localMember = localMember else { return }
        
        isMuted.toggle()
        
        if isMuted {
            // Unpublish audio stream
            if let audioPublication = audioPublication {
                do {
                    try await localMember.unpublish(publicationId: audioPublication.id)
                    self.audioPublication = nil
                    localAudioStream = nil
                    Log.info("Audio unpublished (muted)", category: .network)
                } catch {
                    Log.error("Failed to unpublish audio: \(error)")
                }
            }
        } else {
            // Republish audio stream
            do {
                let audioStream = MicrophoneAudioSource().createStream()
                localAudioStream = audioStream
                audioPublication = try await localMember.publish(audioStream, options: nil)
                Log.info("Audio republished (unmuted)", category: .network)
            } catch {
                Log.error("Failed to republish audio: \(error)")
            }
        }
    }
    
    func setMute(_ muted: Bool) async {
        guard let localMember = localMember else {
            Log.error("No local member available")
            return
        }
        
        isMuted = muted
        
        if muted {
            // Unpublish audio stream
            if let audioPublication = audioPublication {
                do {
                    try await localMember.unpublish(publicationId: audioPublication.id)
                    self.audioPublication = nil
                    localAudioStream = nil
                    Log.info("Audio unpublished (muted)", category: .network)
                } catch {
                    Log.error("Failed to unpublish audio: \(error)")
                }
            }
        } else {
            // Republish audio stream
            do {
                let audioStream = MicrophoneAudioSource().createStream()
                localAudioStream = audioStream
                audioPublication = try await localMember.publish(audioStream, options: nil)
                Log.info("Audio republished (unmuted)", category: .network)
            } catch {
                Log.error("Failed to republish audio: \(error)")
            }
        }
    }
    
    func toggleCamera() async {
        // メディア操作可能かチェック
        guard canPerformMediaOperation(),
              let localMember = localMember else { return }
        
        isCameraEnabled.toggle()
        
        if isCameraEnabled {
            // Republish video stream
            do {
                let videoStream = CameraVideoSource.shared().createStream()
                localVideoStream = videoStream
                
                let videoOptions = RoomPublicationOptions()
                
                // P2P用のシンプルな設定
                let encoding = Encoding()
                encoding.scaleResolutionDownBy = 1.0
                encoding.maxBitrate = 2000000
                
                videoOptions.encodings = [encoding]
                
                videoPublication = try await localMember.publish(videoStream, options: videoOptions)
                Log.info("Video republished (camera enabled)", category: .network)
            } catch {
                Log.error("Failed to republish video: \(error)")
                // エラーが発生した場合はカメラ状態を元に戻す
                isCameraEnabled = false
                localVideoStream = nil
            }
        } else {
            // Unpublish video stream
            if let videoPublication = videoPublication {
                do {
                    try await localMember.unpublish(publicationId: videoPublication.id)
                    self.videoPublication = nil
                    localVideoStream = nil
                    Log.info("Video unpublished (camera disabled)", category: .network)
                } catch {
                    Log.error("Failed to unpublish video: \(error)")
                }
            }
        }
    }
    
    func setCameraEnabled(_ enabled: Bool) async {
        // メディア操作可能かチェック
        guard canPerformMediaOperation(),
              let localMember = localMember else { return }
        
        isCameraEnabled = enabled
        
        if enabled {
            // Republish video stream
            do {
                let cameraSource = CameraVideoSource.shared()
                
                // カメラFPSを設定
                setupCameraFPS(cameraSource)
                
                let videoStream = cameraSource.createStream()
                localVideoStream = videoStream
                
                let videoOptions = RoomPublicationOptions()
                
                // P2P用のシンプルな設定
                let encoding = Encoding()
                encoding.scaleResolutionDownBy = 1.0
                encoding.maxBitrate = 2000000
                
                videoOptions.encodings = [encoding]
                
                videoPublication = try await localMember.publish(videoStream, options: videoOptions)
                Log.info("Video republished (camera enabled)", category: .network)
            } catch {
                Log.error("Failed to republish video: \(error)")
                // エラーが発生した場合はカメラ状態を元に戻す
                isCameraEnabled = false
                localVideoStream = nil
            }
        } else {
            // Unpublish video stream
            if let videoPublication = videoPublication {
                do {
                    try await localMember.unpublish(publicationId: videoPublication.id)
                    self.videoPublication = nil
                    localVideoStream = nil
                    Log.info("Video unpublished (camera disabled)", category: .network)
                } catch {
                    Log.error("Failed to unpublish video: \(error)")
                }
            }
        }
    }
    
    // MARK: - Camera Switching
    
    func switchCamera() async {
        // メディア操作可能かチェック
        guard canPerformMediaOperation(),
              let localMember = localMember else { return }
        
        guard isCameraEnabled else {
            Log.error("Camera is disabled")
            return
        }
        
        Log.info("Switching camera...", category: .network)
        
        let cameras = CameraVideoSource.supportedCameras()
        
        // 切り替え先のカメラを探す
        let newCamera = isUsingFrontCamera 
            ? cameras.first(where: { $0.position == .back })
            : cameras.first(where: { $0.position == .front })
        
        guard let targetCamera = newCamera else {
            Log.error("Target camera not found")
            return
        }
        
        // カメラを切り替えるために、一旦unpublishして再publish
        do {
            // 現在のビデオストリームをunpublish
            if let videoPublication = videoPublication {
                do {
                    try await localMember.unpublish(publicationId: videoPublication.id)
                    self.videoPublication = nil
                    localVideoStream = nil
                } catch {
                    Log.error("Failed to unpublish video: \(error)")
                    throw error
                }
            }
            
            // 新しいカメラで再度キャプチャを開始
            let cameraSource = CameraVideoSource.shared()
            cameraSource.stopCapturing()
            try await cameraSource.startCapturing(with: targetCamera, options: nil)
            
            // カメラFPSを設定
            setupCameraFPS(cameraSource)
            
            // 新しいビデオストリームを作成して公開
            let videoStream = cameraSource.createStream()
            localVideoStream = videoStream
            
            let videoOptions = RoomPublicationOptions()
            let encoding = Encoding()
            encoding.scaleResolutionDownBy = 1.0
            videoOptions.encodings = [encoding]
            
            videoPublication = try await localMember.publish(videoStream, options: videoOptions)
            
            // フラグを更新
            isUsingFrontCamera = targetCamera.position == .front
            
            Log.info("Camera switched to \(isUsingFrontCamera ? "front" : "back")", category: .network)
        } catch {
            Log.error("Failed to switch camera: \(error)")
        }
    }
    
    // MARK: - Speaker Control
    
    func toggleSpeaker() {
        isSpeakerEnabled.toggle()
        configureSpeaker(enabled: isSpeakerEnabled)
    }
    
    func setSpeaker(_ enabled: Bool) {
        isSpeakerEnabled = enabled
        configureSpeaker(enabled: enabled)
    }
    
    // MARK: - Permission Checks
    
    /// マイクのパーミッションを確認
    private func checkMicrophonePermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            switch AVCaptureDevice.authorizationStatus(for: .audio) {
            case .authorized:
                // 許可済み
                continuation.resume(returning: true)
            case .notDetermined:
                // まだ許可を求めていない -> 許可をリクエスト
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    continuation.resume(returning: granted)
                }
            case .denied, .restricted:
                // 拒否または制限されている
                continuation.resume(returning: false)
            @unknown default:
                continuation.resume(returning: false)
            }
        }
    }
    
    private func configureSpeaker(enabled: Bool) {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            if enabled {
                // スピーカーに切り替え
                try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
                try audioSession.overrideOutputAudioPort(.speaker)
                Log.info("Switched to speaker", category: .network)
            } else {
                // イヤホン/通常出力に切り替え
                try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth])
                try audioSession.overrideOutputAudioPort(.none)
                Log.info("Switched to earpiece", category: .network)
            }
            
            try audioSession.setActive(true)
        } catch {
            Log.error("Failed to configure audio session: \(error)")
        }
    }
    
    // MARK: - Camera FPS Setup
    
    private func setupCameraFPS(_ cameraSource: CameraVideoSource) {
        // CameraVideoSourceからデバイスを取得する方法を確認
        // SkyWay SDKではカメラの詳細設定は内部で管理されている
        
        // 現在利用中のカメラを取得
        let cameras = CameraVideoSource.supportedCameras()
        let currentCamera = isUsingFrontCamera 
            ? cameras.first(where: { $0.position == .front })
            : cameras.first(where: { $0.position == .back })
        
        guard let camera = currentCamera else {
            Log.error("No camera available for FPS setup")
            return
        }
        
        // AVCaptureDeviceを取得
        guard let device = AVCaptureDevice.default(
            camera.position == .front ? .builtInWideAngleCamera : .builtInWideAngleCamera,
            for: .video,
            position: camera.position == .front ? .front : .back
        ) else {
            Log.error("Failed to get AVCaptureDevice")
            return
        }
        
        captureDevice = device
        
        do {
            try device.lockForConfiguration()
            
            // 30FPSを設定
            let targetFPS = 30
            device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(targetFPS))
            device.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(targetFPS))
            
            // 実際に設定されたFPSを取得
            let frameDuration = device.activeVideoMinFrameDuration
            let fps = frameDuration.timescale > 0 ? Int(Double(frameDuration.timescale) / Double(frameDuration.value)) : 30
            // FPS設定を適用
            
            device.unlockForConfiguration()
            
            Log.info("Camera FPS set to: \(fps)", category: .network)
        } catch {
            Log.error("Failed to configure camera FPS: \(error)")
            // デフォルト値を使用
        }
    }
}

// MARK: - RoomDelegate
extension SkyWayManager: RoomDelegate {
    // メンバーの状態変更を検知
    nonisolated func room(_ room: Room, memberDidUpdateState member: RoomMember) {
        Task { @MainActor in
            Log.info("Member state changed - \(member.name): \(member.state)", category: .network)
            
            // 相手が離脱状態になった場合
            if member != localMember && member.state == .left {
                Log.warning("Other participant has left (state change detected)", category: .network)
                
                // コールバックを実行
                if let callback = onOtherParticipantLeft {
                    callback()
                }
            }
        }
    }
    
    nonisolated func room(_ room: Room, didPublishStreamOf publication: RoomPublication) {
        Task { @MainActor in
            guard let localMember = localMember else { return }
            
            // 他のメンバーのPublicationの場合、自動的にSubscribe
            if publication.publisher != localMember {
                Log.info("New publication detected from: \(publication.publisher?.name ?? "Unknown")", category: .network)
                remotePublications.append(publication)
                
                do {
                    _ = try await subscribeToPublication(publication)
                    Log.info("Auto-subscribed to new publication", category: .network)
                } catch {
                    Log.error("Failed to auto-subscribe: \(error)")
                }
            }
        }
    }
    
    nonisolated func room(_ room: Room, didUnsubscribePublicationOf subscription: RoomSubscription) {
        Task { @MainActor in
            localSubscriptions.removeAll(where: { $0 == subscription })
            
            // ビデオストリームの削除
            if let videoStream = subscription.stream as? RemoteVideoStream {
                remoteVideoStreams.removeAll(where: { $0 == videoStream })
            }
            
            Log.info("Subscription removed for: \(subscription.publication?.publisher?.name ?? "Unknown")", category: .network)
            
            // すべてのサブスクリプションがなくなった場合（相手が切断した可能性）
            if localSubscriptions.isEmpty && isConnected {
                Log.warning("All subscriptions lost - other participant may have disconnected", category: .network)
                
                // 少し待ってから再確認（一時的な切断の可能性があるため）
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2秒待つ
                
                // まだサブスクリプションが空なら相手が離脱したと判断
                if localSubscriptions.isEmpty && isConnected {
                    Log.error("Other participant confirmed disconnected", category: .network)
                    if let callback = onOtherParticipantLeft {
                        callback()
                    }
                }
            }
        }
    }
    
    nonisolated func roomPublicationListDidChange(_ room: Room) {
        Task { @MainActor in
            remotePublications = room.publications.filter({ $0.publisher != localMember })
        }
    }
    
    nonisolated func roomMemberListDidChange(_ room: Room) {
        Task { @MainActor in
            guard isConnected else { return }
            
            // メンバー情報をログ出力
            Log.info("Room member list changed - Total members: \(room.members.count)", category: .network)
            let localMemberName = localMember?.name ?? "nil"
            Log.info("Local member: \(localMemberName)", category: .network)
            
            // 自分以外のメンバーを確認
            let otherMembers = room.members.filter { member in
                // nameで比較（localMemberがnilの場合も考慮）
                if let localMember = localMember {
                    return member.name != localMember.name
                }
                return true
            }
            
            Log.info("Other members count: \(otherMembers.count)", category: .network)
            for member in otherMembers {
                Log.info("Other member: \(member.name)", category: .network)
            }
            
            // 自分以外のメンバーがいなくなったら通知
            // ただし、自分が退出中（isConnected = false）の場合は通知しない
            if otherMembers.isEmpty && localMember != nil && isConnected {
                Log.info("All other participants have left, notifying UI", category: .network)
                
                // コールバックを実行（nilチェックあり）
                // UIの処理と退出処理はViewModelで管理
                if let callback = onOtherParticipantLeft {
                    callback()
                }
            }
        }
    }
}

enum SkyWayError: LocalizedError {
    case contextNotInitialized
    case notJoinedRoom
    case roomCreationFailed
    case roomIsFull
    case noAuthToken
    case publishTimeout
    case microphonePermissionDenied
    
    var errorDescription: String? {
        switch self {
        case .contextNotInitialized:
            return "SkyWay context is not initialized"
        case .notJoinedRoom:
            return "Not joined to any room"
        case .roomCreationFailed:
            return "Failed to create or find room"
        case .roomIsFull:
            return "ルームは満員です（最大2人まで）"
        case .noAuthToken:
            return "SkyWay認証トークンが設定されていません"
        case .publishTimeout:
            return "接続タイムアウト：ネットワーク環境を確認してください"
        case .microphonePermissionDenied:
            return "マイクへのアクセスが許可されていません。設定からアクセスを許可してください"
        }
    }
}
