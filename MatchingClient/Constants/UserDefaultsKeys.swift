import Foundation

/// UserDefaultsのキー定数
enum UserDefaultsKeys {
    /// 認証関連
    enum Auth {
        static let authToken = "authToken"
        static let refreshToken = "refreshToken"
        static let userId = "userId"
        static let isLoggedIn = "isLoggedIn"
        static let lastLoginDate = "lastLoginDate"
    }
    
    /// ユーザー設定
    enum Settings {
        static let pushNotificationEnabled = "pushNotificationEnabled"
        static let soundEnabled = "soundEnabled"
        static let vibrationEnabled = "vibrationEnabled"
        static let cameraPermissionGranted = "cameraPermissionGranted"
        static let microphonePermissionGranted = "microphonePermissionGranted"
    }
    
    /// アプリ設定
    enum App {
        static let isFirstLaunch = "isFirstLaunch"
        static let appVersion = "appVersion"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let preferredLanguage = "preferredLanguage"
    }
    
    /// キャッシュ
    enum Cache {
        static let lastCacheCleanDate = "lastCacheCleanDate"
        static let cacheSize = "cacheSize"
    }
    
    /// デバイス情報
    enum Device {
        static let deviceId = "deviceId"
        static let deviceName = "deviceName"
        static let deviceModel = "deviceModel"
    }
}