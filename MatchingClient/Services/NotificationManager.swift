import Foundation
import UserNotifications
import UIKit

/// ローカル通知を管理するクラス
final class NotificationManager: NSObject {
    
    // MARK: - Singleton
    static let shared = NotificationManager()
    
    // MARK: - Properties
    private let notificationCenter = UNUserNotificationCenter.current()
    private var isAuthorized = false
    
    // MARK: - Initialization
    private override init() {
        super.init()
        notificationCenter.delegate = self
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    /// 通知権限をリクエスト
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            
            if granted {
                Log.info("Notification permission granted", category: .general)
            } else {
                Log.warning("Notification permission denied", category: .general)
            }
            
            return granted
        } catch {
            Log.error("Failed to request notification permission: \(error)", category: .general)
            return false
        }
    }
    
    /// 通知権限の状態を確認
    private func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized:
                self.isAuthorized = true
                Log.debug("Notification permission is authorized", category: .general)
            case .denied:
                self.isAuthorized = false
                Log.debug("Notification permission is denied", category: .general)
            case .notDetermined:
                self.isAuthorized = false
                Log.debug("Notification permission is not determined", category: .general)
            case .provisional:
                self.isAuthorized = true
                Log.debug("Notification permission is provisional", category: .general)
            case .ephemeral:
                self.isAuthorized = true
                Log.debug("Notification permission is ephemeral", category: .general)
            @unknown default:
                self.isAuthorized = false
            }
        }
    }
    
    // MARK: - Notifications
    
    /// マッチング成功通知を送信
    func sendMatchingNotification(userName: String, userAge: Int?, userGender: Int) {
        guard isAuthorized else {
            Log.warning("Cannot send notification - not authorized", category: .general)
            return
        }
        
        // アプリがフォアグラウンドにいる場合は通知を送らない
        guard UIApplication.shared.applicationState != .active else {
            Log.debug("App is in foreground - skipping notification", category: .general)
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "マッチングが成立しました！"
        
        // ユーザー情報を含めたメッセージ
        let genderText = userGender == 1 ? "男性" : "女性"
        if let age = userAge {
            content.body = "\(userName)さん（\(age)歳・\(genderText)）とマッチングしました。タップして通話を開始しましょう。"
        } else {
            content.body = "\(userName)さん（\(genderText)）とマッチングしました。タップして通話を開始しましょう。"
        }
        
        content.sound = .default
        content.badge = 1
        
        // カテゴリとユーザー情報を設定
        content.categoryIdentifier = "MATCHING_SUCCESS"
        content.userInfo = [
            "type": "matching",
            "userName": userName,
            "userAge": userAge ?? 0,
            "userGender": userGender
        ]
        
        // 即座に通知を送信
        let request = UNNotificationRequest(
            identifier: "matching-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // nilで即座に送信
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                Log.error("Failed to send notification: \(error)", category: .general)
            } else {
                Log.info("Matching notification sent successfully", category: .general)
            }
        }
    }
    
    /// 通話継続確認の通知を送信
    func sendCallContinueNotification() {
        guard isAuthorized else { return }
        guard UIApplication.shared.applicationState != .active else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "通話を続けますか？"
        content.body = "まもなく通話時間が終了します。継続する場合はアプリを開いてください。"
        content.sound = .default
        content.categoryIdentifier = "CALL_CONTINUE"
        
        let request = UNNotificationRequest(
            identifier: "call-continue-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                Log.error("Failed to send call continue notification: \(error)", category: .general)
            }
        }
    }
    
    /// すべての通知をクリア
    func clearAllNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
        notificationCenter.removeAllPendingNotificationRequests()
        
        // バッジもクリア
        Task { @MainActor in
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
    
    /// バッジ数をクリア
    func clearBadge() {
        Task { @MainActor in
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    
    /// フォアグラウンドで通知を受信した時の処理
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // フォアグラウンドでは通知を表示しない
        completionHandler([])
    }
    
    /// 通知をタップした時の処理
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        if let type = userInfo["type"] as? String {
            switch type {
            case "matching":
                // マッチング通知をタップした場合
                Log.info("User tapped matching notification", category: .general)
                // 既にマッチング画面が表示されているはずなので、特別な処理は不要
                
            case "call_continue":
                // 通話継続通知をタップした場合
                Log.info("User tapped call continue notification", category: .general)
                
            default:
                break
            }
        }
        
        completionHandler()
    }
}