//
//  MatchingClientApp.swift
//  MatchingClient
//
//  Created by 宮田涼 on 2025/08/24.
//

import SwiftUI

@main
struct MatchingClientApp: App {
    
    init() {
        // アプリ起動時の初期化処理
        setupApplication()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    /// アプリケーションの初期設定
    private func setupApplication() {
        // ログレベルの設定（デバッグビルドのみ）
        #if DEBUG
        Logger.shared.setMinimumLogLevel(.debug)
        #endif
        
        // デバイスIDの確認とログ出力
        let deviceInfo = DeviceManager.shared.getDeviceInfo()
        Log.info("App launched", category: .general)
        Log.debug(deviceInfo.debugDescription, category: .general)
        
        // 通知マネージャーの初期化
        _ = NotificationManager.shared
        
        // 通知権限のリクエスト（初回起動時）
        Task {
            await NotificationManager.shared.requestAuthorization()
        }
        
        // アプリがフォアグラウンドに戻った時にバッジをクリア
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            NotificationManager.shared.clearBadge()
        }
    }
}
