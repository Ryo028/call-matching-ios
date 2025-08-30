import Foundation
import PusherSwift
import SwiftUI

/// Pusher認証リクエストビルダー
/// プライベートチャンネルの認証に必要なリクエストを構築
class PusherAuthRequestBuilder: AuthRequestBuilderProtocol {
    
    /// 認証トークンを取得（@AppStorageから）
    @AppStorage(UserDefaultsKeys.Auth.authToken) private var storedAuthToken: String?
    
    private var accessToken: String? {
        return storedAuthToken
    }
    
    /// 認証リクエストを構築
    /// - Parameters:
    ///   - socketID: PusherのソケットID
    ///   - channelName: 認証するチャンネル名
    /// - Returns: 認証用のURLRequest
    func requestFor(socketID: String, channelName: String) -> URLRequest? {
        // APIエンドポイントURLを構築
        guard let url = URL(string: "\(AppConfig.API.baseURL)/broadcasting/auth") else {
            Log.error("Invalid auth URL", category: .network)
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // リクエストボディを設定
        let bodyString = "socket_id=\(socketID)&channel_name=\(channelName)"
        request.httpBody = bodyString.data(using: .utf8)
        
        // ヘッダーを設定
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // 認証トークンがある場合は追加
        if let token = accessToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            Log.debug("Auth request with token for channel: \(channelName)", category: .network)
        } else {
            Log.warning("No auth token available for Pusher authentication", category: .network)
        }
        
        // Acceptヘッダーを追加（Laravel用）
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        // タイムアウトを設定
        request.timeoutInterval = 30
        
        Log.info("Created auth request for channel: \(channelName), socketID: \(socketID)", category: .network)
        
        return request
    }
}