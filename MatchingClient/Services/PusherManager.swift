import Foundation
import PusherSwift
import Combine

/// Pusherリアルタイム通信管理クラス
final class PusherManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = PusherManager()
    
    // MARK: - Properties
    private var pusher: Pusher?
    private var channels: [String: PusherChannel] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    @Published var connectionState: ConnectionState = .disconnected
    @Published var lastError: Error?
    
    // イベントパブリッシャー
    let matchingEventPublisher = PassthroughSubject<MatchingEvent, Never>()
    let messageEventPublisher = PassthroughSubject<MessageEvent, Never>()
    let callContinueEventPublisher = PassthroughSubject<CallContinueEvent, Never>()
    
    // 接続完了を待つためのContinuation
    private var connectionContinuation: CheckedContinuation<Void, Error>?
    
    // MARK: - Initialization
    private init() {
        setupPusher()
    }
    
    // MARK: - Setup
    private func setupPusher() {
        // カスタム認証リクエストビルダーを使用
        let authRequestBuilder = PusherAuthRequestBuilder()
        
        // Pusher設定
        let options = PusherClientOptions(
            authMethod: .authRequestBuilder(authRequestBuilder: authRequestBuilder),
            host: .cluster(AppConfig.Pusher.cluster)
        )
        
        pusher = Pusher(
            key: AppConfig.Pusher.appKey,
            options: options
        )
        
        // 接続状態の監視
        pusher?.delegate = self
    }
    
    // MARK: - Connection Management
    
    /// Pusher接続を開始（非同期版）
    func connectAsync() async throws {
        guard let pusher = pusher else {
            Log.error("Pusher not initialized", category: .network)
            throw PusherConnectionError.notInitialized
        }
        
        // 既に接続済みの場合はすぐに返す
        if connectionState == .connected {
            Log.info("Already connected to Pusher", category: .network)
            return
        }
        
        // 接続完了を待つ
        try await withCheckedThrowingContinuation { continuation in
            self.connectionContinuation = continuation
            
            // タイムアウト処理（10秒）
            Task {
                try await Task.sleep(nanoseconds: 10_000_000_000) // 10秒
                if self.connectionContinuation != nil {
                    self.connectionContinuation = nil
                    continuation.resume(throwing: PusherConnectionError.connectionTimeout)
                }
            }
            
            pusher.connect()
            Log.info("Connecting to Pusher...", category: .network)
        }
    }
    
    /// Pusher接続を開始（同期版・後方互換性のため残す）
    func connect(with authToken: String? = nil) {
        guard let pusher = pusher else {
            Log.error("Pusher not initialized", category: .network)
            return
        }
        
        pusher.connect()
        Log.info("Connecting to Pusher...", category: .network)
    }
    
    /// Pusher接続を切断
    func disconnect() {
        pusher?.disconnect()
        channels.removeAll()
        // 接続待機中のContinuationがあればキャンセル
        if let continuation = connectionContinuation {
            connectionContinuation = nil
            continuation.resume(throwing: PusherConnectionError.connectionCancelled)
        }
        Log.info("Disconnected from Pusher", category: .network)
    }
    
    // MARK: - Channel Management
    
    /// ユーザー専用チャンネルを購読
    func subscribeToUserChannel(userId: Int) {
        let channelName = NotificationConstants.PusherChannel.userChannel(userId: userId)
        
        guard channels[channelName] == nil else {
            Log.debug("Already subscribed to channel: \(channelName)", category: .network)
            return
        }
        
        let channel = pusher?.subscribe(channelName)
        channels[channelName] = channel
        
        // マッチング関連イベントをバインド
        bindMatchingEvents(to: channel)
        
        Log.info("Subscribed to user channel: \(channelName)", category: .network)
    }
    
    /// マッチングチャンネルを購読
    func subscribeToMatchingChannel(roomId: String) {
        let channelName = NotificationConstants.PusherChannel.matchingChannel(roomId: roomId)
        
        guard channels[channelName] == nil else {
            Log.debug("Already subscribed to channel: \(channelName)", category: .network)
            return
        }
        
        let channel = pusher?.subscribe(channelName)
        channels[channelName] = channel
        
        // 通話関連イベントをバインド
        bindCallEvents(to: channel)
        
        Log.info("Subscribed to matching channel: \(channelName)", category: .network)
    }
    
    /// チャンネルの購読を解除
    func unsubscribe(from channelName: String) {
        pusher?.unsubscribe(channelName)
        channels.removeValue(forKey: channelName)
        Log.info("Unsubscribed from channel: \(channelName)", category: .network)
    }
    
    /// すべてのチャンネルの購読を解除
    func unsubscribeAll() {
        channels.keys.forEach { channelName in
            pusher?.unsubscribe(channelName)
        }
        channels.removeAll()
        Log.info("Unsubscribed from all channels", category: .network)
    }
    
    // MARK: - Event Triggering
    
    /// 通話継続の選択を送信
    /// - Parameters:
    ///   - roomId: ルームID（Pusherイベント用）
    ///   - userId: 自分のユーザーID（Pusherイベント用）
    ///   - otherUserId: 相手のユーザーID（API用）
    ///   - wantsToContinue: 継続するかどうか
    func sendCallContinueResponse(roomId: String, userId: Int, otherUserId: Int, wantsToContinue: Bool) {
        // APIを通じてサーバーに通話継続の選択を送信
        Task {
            do {
                // サーバーにリクエストを送信（相手のユーザーIDとルームIDを指定）
                let response = try await APIClient.shared.continueCall(
                    userId: otherUserId,
                    roomId: roomId,
                    wantsToContinue: wantsToContinue
                )
                
                if response.success {
                    Log.info("Successfully sent call continue response to server: \(wantsToContinue)", category: .network)
                    // サーバーからPusherイベントが送信されるのを待つ
                } else {
                    Log.error("Failed to send call continue response", category: .network)
                }
            } catch {
                Log.error("Error sending call continue response: \(error)", category: .network)
            }
            
            Log.info("Call continue response process completed for room: \(roomId), wantsToContinue: \(wantsToContinue)", category: .network)
        }
    }
    
    // MARK: - Event Binding
    
    private func bindMatchingEvents(to channel: PusherChannel?) {
        // 統一マッチングイベント (開発用)
        channel?.bind(eventName: NotificationConstants.PusherEvent.matchingEvent) { [weak self] event in
            guard let data = event.data,
                  let jsonData = data.data(using: .utf8) else {
                Log.error("Failed to get event data", category: .network)
                return
            }
            
            do {
                // Laravel側で"message"プロパティでラップされているため、その構造に対応
                let wrapper = try JSONDecoder().decode(MatchingEventWrapper.self, from: jsonData)
                let matchingEvent = wrapper.message
                
                DispatchQueue.main.async {
                    self?.matchingEventPublisher.send(matchingEvent)
                    Log.info("Received matching event: \(matchingEvent)", category: .network)
                }
            } catch {
                Log.error("Failed to decode matching event: \(error)", category: .network)
                // デバッグ用にJSON文字列を出力
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    Log.debug("Raw JSON: \(jsonString)", category: .network)
                }
            }
        }
        
        // マッチング成功イベント
        channel?.bind(eventName: NotificationConstants.PusherEvent.matchingFound) { [weak self] event in
            guard let data = event.data,
                  let jsonData = data.data(using: .utf8),
                  let matchingEvent = try? JSONDecoder().decode(MatchingEvent.self, from: jsonData) else {
                Log.error("Failed to decode matching event", category: .network)
                return
            }
            
            DispatchQueue.main.async {
                self?.matchingEventPublisher.send(matchingEvent)
                Log.info("Received matching event: \(matchingEvent)", category: .network)
            }
        }
        
        // マッチング承認イベント
        channel?.bind(eventName: NotificationConstants.PusherEvent.matchingAccepted) { [weak self] event in
            guard let data = event.data,
                  let jsonData = data.data(using: .utf8),
                  let matchingEvent = try? JSONDecoder().decode(MatchingEvent.self, from: jsonData) else {
                return
            }
            
            DispatchQueue.main.async {
                self?.matchingEventPublisher.send(matchingEvent)
            }
        }
        
        // マッチング拒否イベント
        channel?.bind(eventName: NotificationConstants.PusherEvent.matchingRejected) { [weak self] event in
            guard let data = event.data,
                  let jsonData = data.data(using: .utf8),
                  let matchingEvent = try? JSONDecoder().decode(MatchingEvent.self, from: jsonData) else {
                return
            }
            
            DispatchQueue.main.async {
                self?.matchingEventPublisher.send(matchingEvent)
            }
        }
    }
    
    private func bindCallEvents(to channel: PusherChannel?) {
        // 通話開始イベント
        channel?.bind(eventName: NotificationConstants.PusherEvent.callStarted) { event in
            Log.info("Call started event received", category: .network)
        }
        
        // 通話終了イベント
        channel?.bind(eventName: NotificationConstants.PusherEvent.callEnded) { event in
            Log.info("Call ended event received", category: .network)
        }
        
        // 通話継続確認イベントは matching-event の continue_call で処理されるため、
        // ここでは処理しない（重複を避けるため）
    }
    
    private func bindMessageEvents(to channel: PusherChannel?) {
        // メッセージ受信イベント
        channel?.bind(eventName: NotificationConstants.PusherEvent.messageReceived) { [weak self] event in
            guard let data = event.data,
                  let jsonData = data.data(using: .utf8),
                  let messageEvent = try? JSONDecoder().decode(MessageEvent.self, from: jsonData) else {
                return
            }
            
            DispatchQueue.main.async {
                self?.messageEventPublisher.send(messageEvent)
            }
        }
    }
    
    // MARK: - Event Models
    
    /// Laravel側からのイベントラッパー
    struct MatchingEventWrapper: Codable {
        let message: MatchingEvent
    }
    
    /// マッチングイベントモデル
    struct MatchingEvent: Codable {
        let type: String
        let user: User?
        let roomId: String?  // オプショナルに変更（continue_callイベントではnullの場合がある）
        let timestamp: Date?
        
        enum CodingKeys: String, CodingKey {
            case type = "push_type"
            case user
            case roomId = "room_id"
            case timestamp
        }
    }
    
    /// メッセージイベントモデル
    struct MessageEvent: Codable {
        let id: Int
        let message: String
        let senderId: Int
        let timestamp: Date
        
        enum CodingKeys: String, CodingKey {
            case id
            case message
            case senderId = "sender_id"
            case timestamp
        }
    }
    
    /// 通話継続確認イベントモデル
    struct CallContinueEvent: Codable {
        let userId: Int
        let wantsToContinue: Bool
        let roomId: String
        
        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case wantsToContinue = "wants_to_continue"
            case roomId = "room_id"
        }
    }
}

// MARK: - PusherDelegate
extension PusherManager: PusherDelegate {
    func changedConnectionState(from old: ConnectionState, to new: ConnectionState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.connectionState = new
            Log.info("Pusher connection state changed: \(old) -> \(new)", category: .network)
            
            // 接続完了時にContinuationを解決
            if new == .connected, let continuation = self.connectionContinuation {
                self.connectionContinuation = nil
                continuation.resume()
            }
            
            // 接続失敗時にContinuationをエラーで解決
            if new == .disconnected && old == .connecting,
               let continuation = self.connectionContinuation {
                self.connectionContinuation = nil
                continuation.resume(throwing: PusherConnectionError.connectionFailed)
            }
        }
    }
    
    func debugLog(message: String) {
        Log.debug("Pusher: \(message)", category: .network)
    }
    
    func subscribedToChannel(name: String) {
        Log.info("Subscribed to channel: \(name)", category: .network)
    }
    
    func failedToSubscribeToChannel(name: String, response: URLResponse?, data: String?, error: NSError?) {
        Log.error("Failed to subscribe to channel: \(name), error: \(error?.localizedDescription ?? "Unknown")", category: .network)
    }
    
    func receivedError(error: PusherError) {
        Log.error("Pusher error: \(error.message)", category: .network)
        // PusherErrorはErrorプロトコルに準拠していないため、エラーメッセージのみ保持
    }
}

// MARK: - PusherConnectionError
enum PusherConnectionError: LocalizedError {
    case notInitialized
    case connectionTimeout
    case connectionFailed
    case connectionCancelled
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Pusherが初期化されていません"
        case .connectionTimeout:
            return "接続がタイムアウトしました"
        case .connectionFailed:
            return "接続に失敗しました"
        case .connectionCancelled:
            return "接続がキャンセルされました"
        }
    }
}

// MARK: - Connection State Extension
extension ConnectionState {
    var isConnected: Bool {
        switch self {
        case .connected:
            return true
        default:
            return false
        }
    }
    
    var displayText: String {
        switch self {
        case .connecting:
            return "接続中..."
        case .connected:
            return "接続済み"
        case .disconnecting:
            return "切断中..."
        case .disconnected:
            return "未接続"
        case .reconnecting:
            return "再接続中..."
        @unknown default:
            return "不明"
        }
    }
}