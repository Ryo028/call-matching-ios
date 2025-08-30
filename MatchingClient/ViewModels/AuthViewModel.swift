import Foundation
import SwiftUI

/// 認証機能を管理するViewModel
@MainActor
final class AuthViewModel: ObservableObject, BaseViewModel {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    /// 認証トークンを永続化（@AppStorageを使用）
    @AppStorage(UserDefaultsKeys.Auth.authToken) private var storedAuthToken: String?
    
    /// ユーザーIDを永続化（@AppStorageを使用）
    @AppStorage(UserDefaultsKeys.Auth.userId) private var storedUserId: Int?
    
    /// デバイスIDを永続化（カスタムプロパティラッパーを使用）
    @DeviceID() private var deviceId: String
    
    private let apiClient = APIClient.shared
    
    init() {
        checkAuthStatus()
    }
    
    /// 認証状態を確認
    func checkAuthStatus() {
        Log.info("Checking authentication status", category: .auth)
        
        // @AppStorageから読み込んだトークンをAPIClientに設定
        if let token = storedAuthToken {
            apiClient.authToken = token  // 直接設定
            Log.info("Auth token found, verifying with server", category: .auth)
            
            // ローディング状態を表示
            withAnimation(.easeInOut(duration: 0.3)) {
                isLoading = true
            }
            
            // トークンがあってもサーバーで検証する
            Task {
                await fetchCurrentUser()
                withAnimation(.easeInOut(duration: 0.3)) {
                    isLoading = false
                }
            }
        } else {
            Log.info("No auth token found", category: .auth)
            isAuthenticated = false
            isLoading = false
        }
    }
    
    /// ログイン処理
    /// - Parameters:
    ///   - email: メールアドレス
    ///   - password: パスワード
    func login(email: String, password: String) async {
        Log.info("Login attempt for email: \(email)", category: .auth)
        
        isLoading = true
        errorMessage = nil
        
        do {
            #if DEBUG
            // 開発環境でのテストログイン
            if email == "test@example.com" && password == "password" {
                Log.debug("Using debug test login", category: .auth)
                // デバッグ用の即座ログイン
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let now = Date()
                
                let testUser = User(
                    id: 1,
                    name: "テストユーザー",
                    email: email,
                    genderType: 1,
                    age: 25,
                    imagePath: nil,
                    profile: nil,
                    appleUserId: nil,
                    deviceId: "debug-device-id",
                    pushToken: nil,
                    lastLoginedAt: nil,
                    createdAt: now,
                    updatedAt: now,
                    deletedAt: nil
                )
                // デバッグモード用のトークン設定
                storedAuthToken = "debug_token_12345"
                apiClient.authToken = "debug_token_12345"
                currentUser = testUser
                
                // アニメーション付きで画面遷移
                withAnimation(.easeInOut(duration: 0.5)) {
                    isAuthenticated = true
                    isLoading = false
                }
                return
            }
            #endif
            
            // @DeviceIDプロパティラッパーから永続的なデバイスIDを取得
            let request = LoginRequest(email: email, password: password, deviceId: self.deviceId)
            let response = try await apiClient.request(
                .login,
                method: .post,
                parameters: try? request.toDictionary(),
                responseType: AuthResponse.self
            )
            
            // トークンを@AppStorageに保存
            storedAuthToken = response.accessToken
            apiClient.authToken = response.accessToken
            currentUser = response.user
            
            // ユーザーIDを@AppStorageに保存（Pusher接続用）
            storedUserId = response.user.id
            
            // アニメーション付きで画面遷移
            withAnimation(.easeInOut(duration: 0.5)) {
                isAuthenticated = true
                isLoading = false
            }
            
            Log.info("Login successful for user: \(response.user.name)", category: .auth)
        } catch {
            Log.error("Login failed: \(error)", category: .auth)
            handleError(error)
        }
    }
    
    /// アカウント作成処理
    /// - Parameters:
    ///   - name: ユーザー名
    ///   - email: メールアドレス
    ///   - password: パスワード
    ///   - gender: 性別
    ///   - age: 年齢
    func createAccount(
        name: String,
        email: String,
        password: String,
        gender: Int,
        age: Int?
    ) async {
        Log.info("Creating account for email: \(email)", category: .auth)
        
        isLoading = true
        errorMessage = nil
        
        do {
            // @DeviceIDプロパティラッパーから永続的なデバイスIDを取得
            let request = CreateAccountRequest(
                name: name,
                email: email,
                password: password,
                genderType: gender,
                age: age,
                deviceId: self.deviceId
            )
            
            let response = try await apiClient.request(
                .createAccount,
                method: .post,
                parameters: try? request.toDictionary(),
                responseType: AuthResponse.self
            )
            
            // トークンを@AppStorageに保存
            storedAuthToken = response.accessToken
            apiClient.authToken = response.accessToken
            currentUser = response.user
            
            // ユーザーIDを@AppStorageに保存（Pusher接続用）
            storedUserId = response.user.id
            
            // アニメーション付きで画面遷移
            withAnimation(.easeInOut(duration: 0.5)) {
                isAuthenticated = true
                isLoading = false
            }
            
            Log.info("Account created successfully for user: \(response.user.name)", category: .auth)
        } catch {
            Log.error("Account creation failed: \(error)", category: .auth)
            handleError(error)
        }
    }
    
    /// 現在のユーザー情報を取得
    func fetchCurrentUser() async {
        do {
            let response = try await apiClient.request(
                .getAccount,
                responseType: UserResponse.self
            )
            currentUser = response.user
            
            // ユーザーIDを@AppStorageに保存（Pusher接続用）
            storedUserId = response.user.id
            
            // アニメーション付きで認証状態を更新
            withAnimation(.easeInOut(duration: 0.5)) {
                isAuthenticated = true
            }
            Log.info("User authenticated successfully: \(response.user.name)", category: .auth)
        } catch {
            // 認証エラーの場合はログアウトしてログイン画面へ
            Log.error("Authentication failed, logging out: \(error)", category: .auth)
            logout()
        }
    }
    /// ログアウト処理
    func logout() {
        Log.info("User logged out", category: .auth)
        
        // @AppStorageからトークンを削除
        storedAuthToken = nil
        apiClient.authToken = nil
        currentUser = nil
        
        // アニメーション付きで認証状態を更新
        withAnimation(.easeInOut(duration: 0.5)) {
            isAuthenticated = false
        }
    }
}

