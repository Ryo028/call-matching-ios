import Foundation
import SwiftUI
import Combine
import PusherSwift

/// マッチングの状態を表すenum
enum MatchingState: Equatable {
    case idle                                      // 初期状態
    case searching                                 // マッチング検索中
    case matched(user: User, roomId: String)      // マッチング成功
    case selfAccepted(user: User, roomId: String) // 自分が承認済み
    case otherAccepted(user: User, roomId: String) // 相手が承認済み
    case bothAccepted(user: User, roomId: String, token: String) // 両者承認済み（通話可能）
    case rejected                                  // マッチング拒否
    case error(String)                            // エラー状態
    
    static func == (lhs: MatchingState, rhs: MatchingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.searching, .searching),
             (.rejected, .rejected):
            return true
        case let (.matched(lUser, lRoom), .matched(rUser, rRoom)),
             let (.selfAccepted(lUser, lRoom), .selfAccepted(rUser, rRoom)),
             let (.otherAccepted(lUser, lRoom), .otherAccepted(rUser, rRoom)):
            return lUser.id == rUser.id && lRoom == rRoom
        case let (.bothAccepted(lUser, lRoom, lToken), .bothAccepted(rUser, rRoom, rToken)):
            return lUser.id == rUser.id && lRoom == rRoom && lToken == rToken
        case let (.error(lMsg), .error(rMsg)):
            return lMsg == rMsg
        default:
            return false
        }
    }
    
    // 便利なプロパティ
    var isSearching: Bool {
        if case .searching = self { return true }
        return false
    }
    
    var matchedUser: User? {
        switch self {
        case .matched(let user, _), 
             .selfAccepted(let user, _),
             .otherAccepted(let user, _),
             .bothAccepted(let user, _, _):
            return user
        default:
            return nil
        }
    }
    
    var roomId: String? {
        switch self {
        case .matched(_, let roomId),
             .selfAccepted(_, let roomId),
             .otherAccepted(_, let roomId),
             .bothAccepted(_, let roomId, _):
            return roomId
        default:
            return nil
        }
    }
    
    var canTransitionToCall: Bool {
        if case .bothAccepted = self { return true }
        return false
    }
    
    var isSelfAccepted: Bool {
        switch self {
        case .selfAccepted, .bothAccepted:
            return true
        default:
            return false
        }
    }
    
    var isOtherAccepted: Bool {
        switch self {
        case .otherAccepted, .bothAccepted:
            return true
        default:
            return false
        }
    }
}

/// マッチング機能を管理するViewModel
@MainActor
final class MatchingViewModel: ObservableObject, BaseViewModel {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var matchingState: MatchingState = .idle
    @Published var skywayToken: String?
    @Published var pusherConnectionState = ConnectionState.disconnected
    @Published var shouldRestartMatching = false  // 再マッチングトリガー
    
    /// ユーザーIDを取得（@AppStorageを使用）
    @AppStorage(UserDefaultsKeys.Auth.userId) private var storedUserId: Int?
    
    private let apiClient = APIClient.shared
    private let pusherManager = PusherManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        Log.info("MatchingViewModel init", category: .api)
        setupPusherSubscriptions()
    }
    
    deinit {
        Log.warning("MatchingViewModel deinit - this should not happen during active session", category: .api)
    }
    
    /// Pusherイベントの購読設定
    private func setupPusherSubscriptions() {
        Log.info("Setting up Pusher subscriptions in MatchingViewModel", category: .api)
        
        // マッチングイベントの購読
        pusherManager.matchingEventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                Log.info("MatchingViewModel received event from publisher: \(event.type)", category: .api)
                self?.handleMatchingEvent(event)
            }
            .store(in: &cancellables)
        
        // 接続状態の監視
        pusherManager.$connectionState
            .receive(on: DispatchQueue.main)
            .assign(to: &$pusherConnectionState)
    }
    
    /// Pusher接続を開始（非同期版）
    func connectPusherAsync() async throws {
        // ユーザーIDを取得（保存されている場合）
        guard let userId = storedUserId else {
            Log.warning("No user ID found for Pusher connection", category: .network)
            throw PusherConnectionError.notInitialized
        }
        
        // 非同期で接続完了を待つ
        try await pusherManager.connectAsync()
        
        // ユーザーチャンネルを購読
        pusherManager.subscribeToUserChannel(userId: userId)
        let channelName = NotificationConstants.PusherChannel.userChannel(userId: userId)
        Log.info("Connected to Pusher for user: \(userId), channel: \(channelName)", category: .network)
    }
    
    
    /// Pusher接続を切断
    func disconnectPusher() {
        pusherManager.disconnect()
    }
    
    /// マッチングイベントを処理
    private func handleMatchingEvent(_ event: PusherManager.MatchingEvent) {
        Log.info("Handling matching event: \(event.type)", category: .api)
        
        // イベントの送信者IDと現在のユーザーIDを確認
        let eventUserId = event.user?.id
        let currentUserId = storedUserId
        
        // デバッグログ: イベントの詳細を出力
        Log.debug("Event user ID: \(eventUserId ?? -1), Current user ID: \(currentUserId ?? -1)", category: .api)
        Log.debug("Current state: \(matchingState)", category: .api)
        
        switch event.type {
        case "matched":
            // マッチング成功（相手が先にマッチングAPIを呼んだ場合のPusherイベント）
            // このイベントは相手から送信され、event.userには相手の情報が含まれる
            guard let user = event.user, let roomId = event.roomId else { return }
            
            // デバッグ: Pusherイベントで受信したユーザー情報を詳細にログ出力
            Log.info("Pusher Event - Matched with user:", category: .api)
            Log.info("  - User ID: \(user.id)", category: .api)
            Log.info("  - User Name: \(user.name)", category: .api)
            Log.info("  - User Image: \(user.imagePath ?? "nil")", category: .api)
            Log.info("  - Current User ID: \(currentUserId ?? -1)", category: .api)
            
            withAnimation(.spring()) {
                self.matchingState = .matched(user: user, roomId: roomId)
            }
            
            // ルームチャンネルを購読（マッチした2人で共有）
            pusherManager.subscribeToRoomChannel(roomId: roomId)
            Log.info("Matched with user: \(user.id)", category: .api)
            
            // バックグラウンドの場合はローカル通知を送信
            NotificationManager.shared.sendMatchingNotification(
                userName: user.name,
                userAge: user.age,
                userGender: user.genderType
            )
            
        case "accept":
            // マッチング承認
            // 重要: イベントの送信者が自分でない場合のみ、相手の承認として処理
            if let eventUserId = eventUserId, let currentUserId = currentUserId {
                if eventUserId != currentUserId {
                    // 相手からの承認
                    Log.info("Matching accepted by other user (ID: \(eventUserId))", category: .api)
                    
                    // 現在の状態に応じて遷移
                    switch matchingState {
                    case .selfAccepted(let user, let roomId):
                        // 自分が既に承認済みの場合、両者承認状態へ
                        if let token = skywayToken {
                            withAnimation(.spring()) {
                                self.matchingState = .bothAccepted(user: user, roomId: roomId, token: token)
                            }
                            Log.info("Both users accepted - ready to start call", category: .api)
                        } else {
                            Log.warning("Both accepted but no token available", category: .api)
                        }
                    case .matched(let user, let roomId):
                        // 相手が先に承認した場合
                        withAnimation(.spring()) {
                            self.matchingState = .otherAccepted(user: user, roomId: roomId)
                        }
                        Log.info("Other user accepted - waiting for self acceptance", category: .api)
                    default:
                        Log.warning("Unexpected state for accept event: \(matchingState)", category: .api)
                    }
                } else {
                    // 自分のイベントがエコーバックされた場合
                    Log.debug("Received own accept event (echo) - ignoring", category: .api)
                }
            } else {
                Log.warning("Could not determine event sender for accept event", category: .api)
            }
            
        case "reject":
            // マッチング拒否
            // 重要: イベントの送信者が自分でない場合のみ処理
            if let eventUserId = eventUserId, let currentUserId = currentUserId {
                if eventUserId != currentUserId {
                    // 相手からの拒否
                    Log.info("Matching rejected by other user (ID: \(eventUserId))", category: .api)
                    withAnimation(.spring()) {
                        self.matchingState = .rejected
                        // 再マッチングフラグを立てる
                        self.shouldRestartMatching = true
                    }
                } else {
                    // 自分のイベントがエコーバックされた場合
                    Log.debug("Received own reject event (echo) - ignoring", category: .api)
                }
            } else {
                Log.warning("Could not determine event sender for reject event", category: .api)
            }
            
        case "continue_call":
            // 通話継続イベント（このイベントが来た = そのユーザーは継続したい）
            // 重要: 自分のイベントは無視する（エコーバック対策）
            if let user = event.user, 
               let roomId = event.roomId,
               let currentUserId = storedUserId,
               user.id != currentUserId {  // 自分以外のイベントのみ処理
                // CallContinueEventを作成して発行（wantsToContinue は常に true）
                let continueEvent = PusherManager.CallContinueEvent(
                    userId: user.id,
                    wantsToContinue: true,  // continue_callイベントが来た = 継続したい
                    roomId: roomId
                )
                // CallInProgressViewで購読しているpublisherに送信
                PusherManager.shared.callContinueEventPublisher.send(continueEvent)
                Log.info("Received continue_call event from other user \(user.id) - wants to continue", category: .api)
            } else if let user = event.user, user.id == storedUserId {
                Log.debug("Ignoring own continue_call event (echo)", category: .api)
            }
            
        default:
            Log.warning("Unknown matching event type: \(event.type)", category: .api)
        }
    }
    
    /// マッチング開始
    /// - Parameters:
    ///   - genderType: 希望する性別（nil=指定なし、0=男性、1=女性）
    ///   - ageRange: 年齢範囲
    ///   - distance: 距離（km）
    func startMatching(
        genderType: Gender?,
        ageRange: ClosedRange<Double>,
        distance: Double
    ) async {
        Log.info("Starting matching", category: .api)
        
        // マッチング開始時に状態をリセット
        matchingState = .searching
        skywayToken = nil
        
        // isLoadingは最初は設定しない（ちらつき防止）
        errorMessage = nil
        
        do {
            // gender_typeは必須なので、nilの場合は0（指定なし）を送る
            let genderValue: Int
            if let genderType = genderType {
                genderValue = genderType.rawValue
            } else {
                genderValue = 0  // 指定なし（GENDER_TYPE_NONE）
            }
            
            // マッチング開始時にPusher接続を確立（まだ接続されていない場合）
            if !pusherConnectionState.isConnected {
                // 非同期で接続完了を待つ
                try await connectPusherAsync()
            }
            
            let request = StartMatchingRequest(
                genderType: genderValue,
                ageMin: Int(ageRange.lowerBound),
                ageMax: Int(ageRange.upperBound),
                distance: Int(distance)
            )
            
            // マッチングAPIを呼び出す
            let response = try await apiClient.request(
                .startMatching,
                method: .post,
                parameters: try? request.toDictionary(),
                responseType: MatchingResponse.self
            )
            
            if let matchedUser = response.user {
                // マッチング相手が見つかった場合（APIレスポンスから相手の情報を取得）
                Log.info("API Response - Matched with user:", category: .api)
                Log.info("  - User ID: \(matchedUser.id)", category: .api)
                Log.info("  - User Name: \(matchedUser.name)", category: .api)
                Log.info("  - User Image: \(matchedUser.imagePath ?? "nil")", category: .api)
                
                withAnimation(.spring()) {
                    self.matchingState = .matched(user: matchedUser, roomId: response.roomId)
                }
                
                // ルームチャンネルを購読（マッチした2人で共有）
                pusherManager.subscribeToRoomChannel(roomId: response.roomId)
                
                Log.info("Matching found user: \(matchedUser.id)", category: .api)
                
                // マッチング成功画面が自動的に表示される（ViewのobserveによるUI更新）
            } else {
                // マッチング相手が見つからない場合（待機中）
                // searchingの状態を維持（roomIdは一時的に保持）
                Log.info("Waiting for matching with room: \(response.roomId)", category: .api)
                
                // Pusherでリアルタイム通知を待機（handleMatchingEventで処理される）
            }
            
            // TODO: Pusherチャンネルを購読してマッチング通知を待機
            
        } catch {
            Log.error("Failed to start matching: \(error)", category: .api)
            handleError(error)
        }
    }
    
    /// マッチング状態をリセット
    func resetMatching() async {
        await MainActor.run {
            // すべての状態を初期値にリセット
            matchingState = .idle
            skywayToken = nil
            isLoading = false
            errorMessage = nil
            shouldRestartMatching = false
            
            // Pusherのルームチャンネル購読を解除
            if let roomId = self.matchingState.roomId {
                PusherManager.shared.unsubscribe(from: NotificationConstants.PusherChannel.roomChannel(roomId: roomId))
            }
            
            // ユーザーチャンネル購読を解除
            if let userId = storedUserId {
                PusherManager.shared.unsubscribe(from: NotificationConstants.PusherChannel.userChannel(userId: userId))
            }
            
            // Pusher接続を切断（リソース節約）
            pusherManager.disconnect()
            
            Log.info("Matching state completely reset and Pusher disconnected", category: .api)
        }
    }
    
    /// マッチングキャンセル
    func cancelMatching() async {
        Log.info("Cancelling matching", category: .api)
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiClient.request(
                .stopMatching,
                method: .delete,
                responseType: MatchingActionResponse.self
            )
            
            // is_successがfalseでも、すでにマッチング済みやキャンセル済みの場合があるため
            // エラーとしては扱わず、常に状態をリセットする
            withAnimation(.spring()) {
                matchingState = .idle
                isLoading = false
            }
            
            // チャンネル購読解除とPusher切断
            if let roomId = self.matchingState.roomId {
                PusherManager.shared.unsubscribe(from: NotificationConstants.PusherChannel.roomChannel(roomId: roomId))
            }
            if let userId = storedUserId {
                PusherManager.shared.unsubscribe(from: NotificationConstants.PusherChannel.userChannel(userId: userId))
            }
            pusherManager.disconnect()
            
            if response.isSuccess {
                Log.info("Matching cancelled successfully", category: .api)
            } else {
                // すでにマッチング済みまたはキャンセル済みの可能性
                Log.info("Matching was already cancelled or completed", category: .api)
            }
            
        } catch {
            Log.error("Failed to cancel matching: \(error)", category: .api)
            handleError(error)
        }
    }
    
    /// マッチング承認
    /// - Parameters:
    ///   - userId: 承認するユーザーID
    ///   - roomId: ルームID
    func acceptMatching(userId: Int, roomId: String) async {
        Log.info("Accepting matching for user: \(userId)", category: .api)
        Log.debug("Current state before accept: \(matchingState)", category: .api)
        
        // 即座にUIを更新（承認待ち状態に）
        await MainActor.run {
            if case .matched(let user, let roomId) = matchingState {
                matchingState = .selfAccepted(user: user, roomId: roomId)
            }
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let request = MatchingActionRequest(roomId: roomId)
            
            let response = try await apiClient.request(
                .acceptMatching(userId: userId),
                method: .put,
                parameters: try? request.toDictionary(),
                responseType: MatchingActionResponse.self
            )
            
            if response.isSuccess {
                // SkyWayトークンを取得
                do {
                    try await fetchSkyWayToken()
                    
                    // 現在の状態に応じて遷移
                    switch matchingState {
                    case .selfAccepted:
                        // すでにselfAcceptedに更新済み
                        isLoading = false
                        Log.info("Self accepted - waiting for other user", category: .api)
                        
                    case .otherAccepted(let user, let roomId):
                        // 相手が既に承認済みの場合
                        if let token = skywayToken {
                            withAnimation(.spring()) {
                                self.matchingState = .bothAccepted(user: user, roomId: roomId, token: token)
                                isLoading = false
                            }
                            Log.info("Both users accepted - transitioning to call view", category: .api)
                        }
                        
                    default:
                        Log.warning("Unexpected state for accept: \(matchingState)", category: .api)
                    }
                    
                    Log.debug("State after accept: \(matchingState)", category: .api)
                    Log.info("Matching accepted successfully", category: .api)
                    
                } catch {
                    // トークン取得失敗時のエラーメッセージを設定
                    withAnimation(.spring()) {
                        isLoading = false
                        errorMessage = "通話の準備に失敗しました。もう一度お試しください。"
                    }
                    throw error
                }
            } else {
                throw APIClientError.unknown
            }
            
        } catch {
            Log.error("Failed to accept matching: \(error)", category: .api)
            
            // エラー時は状態を元に戻す
            await MainActor.run {
                if case .selfAccepted(let user, let roomId) = matchingState {
                    matchingState = .matched(user: user, roomId: roomId)
                }
            }
            
            handleError(error)
        }
    }
    
    /// マッチング拒否
    /// - Parameters:
    ///   - userId: 拒否するユーザーID
    ///   - roomId: ルームID
    func rejectMatching(userId: Int, roomId: String) async {
        Log.info("Rejecting matching for user: \(userId)", category: .api)
        
        isLoading = true
        errorMessage = nil
        
        do {
            let request = MatchingActionRequest(roomId: roomId)
            
            let response = try await apiClient.request(
                .rejectMatching(userId: userId),
                method: .put,
                parameters: try? request.toDictionary(),
                responseType: MatchingActionResponse.self
            )
            
            if response.isSuccess {
                // ルームチャンネルを先に解除（状態変更前に）
                if let roomId = self.matchingState.roomId {
                    PusherManager.shared.unsubscribe(from: NotificationConstants.PusherChannel.roomChannel(roomId: roomId))
                }
                
                withAnimation(.spring()) {
                    matchingState = .rejected
                    isLoading = false
                }
                
                Log.info("Matching rejected successfully", category: .api)
                
                // 拒否時はPusher接続とユーザーチャンネルを維持（再マッチングの可能性があるため）
            } else {
                throw APIClientError.unknown
            }
            
        } catch {
            Log.error("Failed to reject matching: \(error)", category: .api)
            handleError(error)
        }
    }
    
    /// SkyWayトークン取得
    private func fetchSkyWayToken() async throws {
        do {
            let response = try await apiClient.request(
                .getMatchingToken,
                responseType: SkyWayTokenResponse.self
            )
            
            self.skywayToken = response.skywayToken
            Log.info("SkyWay token fetched successfully", category: .api)
            
        } catch {
            Log.error("Failed to fetch SkyWay token: \(error)", category: .api)
            
            // 開発環境の場合、モックトークンを使用（実際の通話はできない）
            #if DEBUG
            if ProcessInfo.processInfo.environment["USE_MOCK_TOKEN"] == "1" {
                Log.info("Using mock token for development", category: .api)
                self.skywayToken = "mock_token_for_development"
                return
            }
            #endif
            
            // エラーを再スローして呼び出し元で処理
            throw error
        }
    }
    
    /// マッチング成功をシミュレート（テスト用）
    func simulateMatchSuccess(user: User, roomId: String) {
        withAnimation(.spring()) {
            self.matchingState = .matched(user: user, roomId: roomId)
        }
    }
}