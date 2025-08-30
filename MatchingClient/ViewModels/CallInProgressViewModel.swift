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
    private var connectionCheckTimer: Timer?
    private var lastConnectionCheck: Date = Date()
    var cancellables = Set<AnyCancellable>()  // CallInProgressViewからアクセス可能に
    
    private func handleOtherParticipantLeft() {
        // dismissReasonを設定しない（アラートを表示しない）
        // 通話を終了
        Task {
            await endCall()
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
        startConnectionCheck()
        
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
        connectionCheckTimer?.invalidate()
        
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
    
    private func startConnectionCheck() {
        // 5秒ごとに接続状態をチェック
        connectionCheckTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkConnection()
            }
        }
    }
    
    private func checkConnection() {
        // リモートストリームが存在するかチェック
        if skyWayManager.remoteVideoStreams.isEmpty && skyWayManager.localSubscriptions.isEmpty {
            let timeSinceLastCheck = Date().timeIntervalSince(lastConnectionCheck)
            
            // 10秒以上リモートストリームがない場合は切断と判断
            if timeSinceLastCheck > 10 {
                Log.error("No remote streams for 10 seconds - assuming disconnection", category: .network)
                handleOtherParticipantLeft()
                connectionCheckTimer?.invalidate()
            }
        } else {
            // 接続が確認できたら最終チェック時刻を更新
            lastConnectionCheck = Date()
        }
    }
    
    deinit {
        callTimer?.invalidate()
        connectionCheckTimer?.invalidate()
        // onOtherParticipantLeft は endCall() で既にnilに設定されている
    }
}