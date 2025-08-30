import Foundation
import UIKit

/// デバイス情報を管理するマネージャー
///
/// デバイスIDの生成と永続化を管理します。
/// 一度生成されたデバイスIDは、アプリを削除するまで変更されません。
final class DeviceManager {
    
    // MARK: - Properties
    
    /// シングルトンインスタンス
    static let shared = DeviceManager()
    
    /// デバイスIDのUserDefaultsキー
    private let deviceIdKey = "com.matchingclient.deviceId"
    
    /// キャッシュされたデバイスID
    private var cachedDeviceId: String?
    
    // MARK: - Initialization
    
    private init() {
        // 起動時にデバイスIDをキャッシュ
        cachedDeviceId = UserDefaults.standard.string(forKey: deviceIdKey)
    }
    
    // MARK: - Public Methods
    
    /// 永続的なデバイスIDを取得
    ///
    /// - Returns: デバイスID（保存されていない場合は新規生成して保存）
    ///
    /// ## 仕様
    /// - 初回起動時: UUIDを生成してUserDefaultsに保存
    /// - 2回目以降: UserDefaultsから取得
    /// - アプリ削除まで同じIDを使い続ける
    ///
    /// ## Example
    /// ```swift
    /// let deviceId = DeviceManager.shared.getDeviceId()
    /// print(deviceId) // "550E8400-E29B-41D4-A716-446655440000"
    /// ```
    func getDeviceId() -> String {
        // キャッシュがある場合はそれを返す
        if let cachedId = cachedDeviceId {
            Log.debug("Using cached device ID: \(cachedId)", category: .general)
            return cachedId
        }
        
        // UserDefaultsから取得を試みる
        if let savedId = UserDefaults.standard.string(forKey: deviceIdKey) {
            Log.info("Device ID loaded from UserDefaults: \(savedId)", category: .general)
            cachedDeviceId = savedId
            return savedId
        }
        
        // 新規生成
        let newId = generateNewDeviceId()
        saveDeviceId(newId)
        Log.info("New device ID generated and saved: \(newId)", category: .general)
        return newId
    }
    
    /// デバイスIDをリセット（デバッグ用）
    ///
    /// - Warning: この関数は開発時のテスト用です。本番環境では使用しないでください。
    #if DEBUG
    func resetDeviceId() {
        UserDefaults.standard.removeObject(forKey: deviceIdKey)
        cachedDeviceId = nil
        Log.warning("Device ID has been reset", category: .general)
    }
    #endif
    
    /// デバイスIDが既に存在するかチェック
    ///
    /// - Returns: デバイスIDが保存されている場合は`true`
    func hasDeviceId() -> Bool {
        return cachedDeviceId != nil || UserDefaults.standard.string(forKey: deviceIdKey) != nil
    }
    
    // MARK: - Private Methods
    
    /// 新しいデバイスIDを生成
    ///
    /// - Returns: UUID形式の新しいデバイスID
    private func generateNewDeviceId() -> String {
        // iOSデバイスのidentifierForVendorを優先的に使用
        // 同じベンダー（開発者）のアプリ間で一意のID
        if let vendorId = UIDevice.current.identifierForVendor?.uuidString {
            return vendorId
        }
        
        // フォールバック: 通常のUUIDを生成
        return UUID().uuidString
    }
    
    /// デバイスIDを保存
    ///
    /// - Parameter deviceId: 保存するデバイスID
    private func saveDeviceId(_ deviceId: String) {
        UserDefaults.standard.set(deviceId, forKey: deviceIdKey)
        UserDefaults.standard.synchronize() // 即座に永続化
        cachedDeviceId = deviceId
    }
    
    // MARK: - Device Information
    
    /// デバイス情報を取得
    ///
    /// - Returns: デバイスの詳細情報
    func getDeviceInfo() -> DeviceInfo {
        return DeviceInfo(
            deviceId: getDeviceId(),
            deviceName: UIDevice.current.name,
            systemName: UIDevice.current.systemName,
            systemVersion: UIDevice.current.systemVersion,
            model: UIDevice.current.model,
            localizedModel: UIDevice.current.localizedModel
        )
    }
}

/// デバイス情報を表す構造体
struct DeviceInfo {
    /// デバイスID
    let deviceId: String
    /// デバイス名（例: "山田のiPhone"）
    let deviceName: String
    /// システム名（例: "iOS"）
    let systemName: String
    /// システムバージョン（例: "17.0"）
    let systemVersion: String
    /// モデル（例: "iPhone"）
    let model: String
    /// ローカライズされたモデル名
    let localizedModel: String
    
    /// デバッグ用の説明
    var debugDescription: String {
        """
        Device Info:
        - ID: \(deviceId)
        - Name: \(deviceName)
        - System: \(systemName) \(systemVersion)
        - Model: \(localizedModel)
        """
    }
}