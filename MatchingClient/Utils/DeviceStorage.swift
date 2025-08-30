import SwiftUI
import Foundation

/// デバイスIDを管理するプロパティラッパー
///
/// @AppStorageと同様の使い方で、デバイスIDの永続化を行います。
/// 初回アクセス時に自動的にUUIDを生成し、以降は同じIDを返します。
@propertyWrapper
struct DeviceID {
    private let key: String
    private let userDefaults: UserDefaults
    
    /// デバイスIDを管理するプロパティラッパーを初期化
    ///
    /// - Parameters:
    ///   - key: UserDefaultsのキー
    ///   - store: UserDefaultsのインスタンス（デフォルト: .standard）
    init(_ key: String = UserDefaultsKeys.Device.deviceId, store: UserDefaults = .standard) {
        self.key = key
        self.userDefaults = store
    }
    
    /// ラップされた値（デバイスID）
    var wrappedValue: String {
        get {
            // 保存されているIDがあれば返す
            if let savedId = userDefaults.string(forKey: key) {
                return savedId
            }
            
            // なければ新規生成して保存
            let newId = UUID().uuidString
            userDefaults.set(newId, forKey: key)
            Log.info("New device ID generated: \(newId)", category: .general)
            return newId
        }
        nonmutating set {
            userDefaults.set(newValue, forKey: key)
        }
    }
    
    /// プロジェクション値（Binding用）
    var projectedValue: Binding<String> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }
}

/// View内でデバイスIDを取得するための環境値
struct DeviceIDKey: EnvironmentKey {
    static let defaultValue: String = {
        // 初回アクセス時にデバイスIDを生成
        if let savedId = UserDefaults.standard.string(forKey: UserDefaultsKeys.Device.deviceId) {
            return savedId
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: UserDefaultsKeys.Device.deviceId)
        return newId
    }()
}

extension EnvironmentValues {
    /// 環境値としてデバイスIDを提供
    var deviceId: String {
        get { self[DeviceIDKey.self] }
        set { self[DeviceIDKey.self] = newValue }
    }
}