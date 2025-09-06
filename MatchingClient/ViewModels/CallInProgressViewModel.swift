import Foundation
import SwiftUI
import SkyWayRoom
import Combine

@MainActor
final class CallInProgressViewModel: ObservableObject {
    @Published var localVideoStream: LocalVideoStream?
    @Published var remoteVideoStreams: [RemoteVideoStream] = []
    @Published var isMuted = false
    @Published var isVideoEnabled = false  // 初期状態はカメラオフ
    @Published var isUsingFrontCamera = false
    @Published var participantCount = 1
    @Published var callDuration = "00:00"
    @Published var isSpeakerEnabled = false
    @Published var shouldDismiss = false
    @Published var dismissReason: String?
    @Published var otherParticipantLeft = false
    
    private let skyWayManager = SkyWayManager.shared
    private var callTimer: Timer?
    private var callStartTime: Date?
    var cancellables = Set<AnyCancellable>()  // CallInProgressViewからアクセス可能に
    
    private func handleOtherParticipantLeft() {
        // 相手が退出した場合、通話継続ダイアログが表示される可能性があるため
        // ルームの即座の破棄は避け、フラグのみ設定
        Task {
            // メディアストリームのみ停止（ルームは維持）
            await stopStreaming()
            // UIの更新後に通話終了画面へ遷移
            await MainActor.run {
                otherParticipantLeft = true
            }
        }
    }
    
    func setupCall() {
        // SkyWayManagerから Stream を取得
        skyWayManager.$localVideoStream
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stream in
                self?.localVideoStream = stream
            }
            .store(in: &cancellables)
        
        skyWayManager.$remoteVideoStreams
            .receive(on: DispatchQueue.main)
            .sink { [weak self] streams in
                self?.remoteVideoStreams = streams
                self?.participantCount = 1 + streams.count
            }
            .store(in: &cancellables)
        
        // ミュートとカメラの状態を同期
        skyWayManager.$isMuted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] muted in
                self?.isMuted = muted
            }
            .store(in: &cancellables)
        
        skyWayManager.$isCameraEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                self?.isVideoEnabled = enabled
            }
            .store(in: &cancellables)
        
        // フロント/バックカメラ状態を同期
        skyWayManager.$isUsingFrontCamera
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isUsingFront in
                self?.isUsingFrontCamera = isUsingFront
            }
            .store(in: &cancellables)
        
        // スピーカー状態を同期
        skyWayManager.$isSpeakerEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                self?.isSpeakerEnabled = enabled
            }
            .store(in: &cancellables)
        
        startCallTimer()
        
        // 相手が退出した時のコールバックを設定
        skyWayManager.onOtherParticipantLeft = { [weak self] in
            guard let self = self else { return }
            self.handleOtherParticipantLeft()
        }
    }
    
    func toggleMute() {
        Task {
            await skyWayManager.toggleMute()
        }
    }
    
    func toggleCamera() {
        Task {
            await skyWayManager.toggleCamera()
        }
    }
    
    func switchCamera() {
        Task {
            await skyWayManager.switchCamera()
        }
    }
    
    func toggleSpeaker() {
        skyWayManager.toggleSpeaker()
    }
    
    /// 音声/映像を即座に停止（画面遷移用の高速処理）
    func stopStreaming() async {
        // タイマーを停止
        callTimer?.invalidate()
        
        // 音声/映像ストリームを即座に停止
        await skyWayManager.stopMediaStreams()
        
        Log.info("Media streams stopped for quick transition", category: .network)
    }
    
    /// 残りのクリーンアップ処理（バックグラウンドで実行）
    func cleanupResources() async {
        skyWayManager.onOtherParticipantLeft = nil
        do {
            try await skyWayManager.leaveRoom()
            Log.info("Successfully left room and cleaned up resources", category: .network)
        } catch {
            Log.error("Error leaving room: \(error)", category: .network)
        }
    }
    
    /// 従来の終了処理（後方互換性のため残す）
    func endCall() async {
        await stopStreaming()
        await cleanupResources()
    }
    
    private func startCallTimer() {
        callStartTime = Date()
        callTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateCallDuration()
            }
        }
    }
    
    private func updateCallDuration() {
        guard let startTime = callStartTime else { return }
        
        let elapsed = Int(Date().timeIntervalSince(startTime))
        let minutes = elapsed / 60
        let seconds = elapsed % 60
        
        callDuration = String(format: "%02d:%02d", minutes, seconds)
    }
    
    deinit {
        callTimer?.invalidate()
        // onOtherParticipantLeft は endCall() で既にnilに設定されている
    }
}