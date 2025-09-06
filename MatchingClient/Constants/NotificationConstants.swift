import Foundation

/// 通知関連の定数
enum NotificationConstants {
    /// Pusherチャンネル名
    enum PusherChannel {
        static let privatePrefix = "private-"
        static let presencePrefix = "presence-"
        
        /// ユーザー個人チャンネル名を生成
        /// - Parameter userId: ユーザーID
        /// - Returns: private-user.{userId} 形式のチャンネル名
        static func userChannel(userId: Int) -> String {
            return "\(privatePrefix)user.\(userId)"
        }
        
        /// ルームチャンネル名を生成（マッチング・通話共通）
        /// - Parameter roomId: ルームID
        /// - Returns: private-room.{roomId} 形式のチャンネル名
        static func roomChannel(roomId: String) -> String {
            return "\(privatePrefix)room.\(roomId)"
        }
        
        // 後方互換性のため残す（段階的に削除予定）
        @available(*, deprecated, message: "Use roomChannel instead")
        static func matchingChannel(roomId: String) -> String {
            return roomChannel(roomId: roomId)
        }
    }
    
    /// Pusherイベント名
    enum PusherEvent {
        /// 統一イベント名（サーバーから送信される実際のイベント名）
        static let matchingEvent = "matching-event"
        
        // 以下は将来的に個別イベントを実装する場合の予約名
        /// マッチング関連イベント
        static let matchingFound = "matching.found"
        static let matchingAccepted = "matching.accepted"
        static let matchingRejected = "matching.rejected"
        
        /// 通話関連イベント
        static let callStarted = "call.started"
        static let callEnded = "call.ended"
        static let callContinue = "call.continue"
        
        /// メッセージ関連イベント
        static let messageReceived = "message.received"
    }
    
    /// ローカル通知
    enum LocalNotification {
        static let matchingFoundTitle = "マッチング成功！"
        static let matchingFoundBody = "新しい相手とマッチングしました"
        static let callIncomingTitle = "着信"
        static let callIncomingBody = "通話リクエストが届いています"
        static let messageReceivedTitle = "新着メッセージ"
    }
}