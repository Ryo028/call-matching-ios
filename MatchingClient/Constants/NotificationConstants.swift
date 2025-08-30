import Foundation

/// 通知関連の定数
enum NotificationConstants {
    /// Pusherチャンネル名
    enum PusherChannel {
        static let matchingPrefix = "matching."
        static let privatePrefix = "private-"
        static let presencePrefix = "presence-"
        
        /// ユーザー専用チャンネル名を生成
        static func userChannel(userId: Int) -> String {
            // 開発用: 固定チャンネル名を使用
            #if DEBUG
            return "private-matching-channel.1"
            #else
            return "\(privatePrefix)user.\(userId)"
            #endif
        }
        
        /// マッチングチャンネル名を生成
        static func matchingChannel(roomId: String) -> String {
            // 開発用: 固定チャンネル名を使用
            #if DEBUG
            return "private-matching-channel.1"
            #else
            return "\(privatePrefix)\(matchingPrefix)\(roomId)"
            #endif
        }
    }
    
    /// Pusherイベント名
    enum PusherEvent {
        /// 開発用: 統一イベント名
        static let matchingEvent = "matching-event"
        
        /// マッチング関連イベント
        static let matchingFound = "matching.found"
        static let matchingAccepted = "matching.accepted"
        static let matchingRejected = "matching.rejected"
        
        /// 通話関連イベント
        static let callStarted = "call.started"
        static let callEnded = "call.ended"
        
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