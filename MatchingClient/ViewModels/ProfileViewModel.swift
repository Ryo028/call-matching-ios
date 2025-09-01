import Foundation
import SwiftUI

/// プロフィール画面のViewModel
@MainActor
final class ProfileViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// ユーザー情報
    @Published var user: User?
    
    /// ローディング状態
    @Published var isLoading = false
    
    /// エラーメッセージ
    @Published var errorMessage: String?
    
    /// 成功メッセージ
    @Published var successMessage: String?
    
    /// プロフィール画像
    @Published var profileImage: UIImage?
    
    /// 画像アップロード中フラグ
    @Published var isUploadingImage = false
    
    // MARK: - Private Properties
    
    /// APIクライアント
    private let apiClient = APIClient.shared
    
    // MARK: - Initialization
    
    init() {
        // 初期化時にAPIコールを行わない
        // ProfileViewのtaskモディファイアから呼び出す
    }
    
    // MARK: - Public Methods
    
    /// ユーザープロフィールを読み込む
    func loadUserProfile() async {
        // 既にロード済みの場合はスキップ
        if user != nil {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiClient.request(
                .getAccount,
                method: .get,
                responseType: UserResponse.self
            )
            
            self.user = response.user
            
            // プロフィール画像を読み込む
            if let imagePath = response.user.imagePath {
                await loadProfileImage(from: imagePath)
            }
            
            Log.info("User profile loaded successfully", category: .network)
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    /// プロフィールを更新する
    /// - Parameters:
    ///   - name: 名前
    ///   - age: 年齢
    ///   - genderType: 性別
    ///   - profile: 自己紹介
    func updateProfile(
        name: String,
        age: Int,
        genderType: Int,
        profile: String
    ) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        // 現在のユーザーのemailを取得
        guard let currentEmail = user?.email else {
            errorMessage = "ユーザー情報の取得に失敗しました"
            isLoading = false
            return
        }
        
        struct UpdateProfileRequest: Encodable {
            let name: String
            let email: String
            let age: Int
            let genderType: Int
            let profile: String
            
            enum CodingKeys: String, CodingKey {
                case name
                case email
                case age
                case genderType = "gender_type"
                case profile
            }
        }
        
        let request = UpdateProfileRequest(
            name: name,
            email: currentEmail,
            age: age,
            genderType: genderType,
            profile: profile
        )
        
        do {
            let parameters = try request.toDictionary()
            
            let response = try await apiClient.request(
                .updateAccount,
                method: .put,
                parameters: parameters,
                responseType: UserResponse.self
            )
            
            self.user = response.user
            successMessage = "プロフィールを更新しました"
            Log.info("Profile updated successfully", category: .network)
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    /// プロフィール画像をアップロードする
    /// - Parameter image: アップロードする画像
    func uploadProfileImage(_ image: UIImage) async {
        isUploadingImage = true
        errorMessage = nil
        successMessage = nil
        
        // 画像を適切なサイズに圧縮（最大5MB以下）
        guard let imageData = compressImageForUpload(image, maxSizeMB: 4.5) else {
            errorMessage = "画像の処理に失敗しました"
            isUploadingImage = false
            return
        }
        
        // ファイルサイズをログに出力
        let sizeInMB = Double(imageData.count) / (1024.0 * 1024.0)
        Log.debug("Compressed image size: \(String(format: "%.2f", sizeInMB))MB", category: .network)
        
        do {
            let response = try await apiClient.upload(
                .uploadImage,
                data: imageData,
                fileName: "profile.jpg",
                mimeType: "image/jpeg",
                responseType: UserResponse.self
            )
            
            self.user = response.user
            self.profileImage = image
            successMessage = "プロフィール画像を更新しました"
            
            // 更新された画像パスを読み込む
            if let imagePath = response.user.imagePath {
                await loadProfileImage(from: imagePath)
            }
            
            Log.info("Profile image uploaded successfully", category: .network)
        } catch {
            handleError(error)
        }
        
        isUploadingImage = false
    }
    
    // MARK: - Private Methods
    
    /// プロフィール画像を読み込む
    /// - Parameter path: 画像のパス
    private func loadProfileImage(from path: String) async {
        if let image = await ImageLoader.loadProfileImage(from: path) {
            self.profileImage = image
        }
    }
    
    /// 画像をリサイズする
    /// - Parameters:
    ///   - image: 元画像
    ///   - maxSize: 最大サイズ
    /// - Returns: リサイズ後の画像
    private func resizeImage(_ image: UIImage, maxSize: CGSize) -> UIImage {
        let size = image.size
        
        // アスペクト比を保持したままリサイズ
        let widthRatio = maxSize.width / size.width
        let heightRatio = maxSize.height / size.height
        let ratio = min(widthRatio, heightRatio)
        
        // 元画像が最大サイズより小さい場合はそのまま返す
        if ratio >= 1.0 {
            return image
        }
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
    
    /// 画像をアップロード用に圧縮する
    /// - Parameters:
    ///   - image: 元画像
    ///   - maxSizeMB: 最大ファイルサイズ（MB）
    /// - Returns: 圧縮されたJPEGデータ
    private func compressImageForUpload(_ image: UIImage, maxSizeMB: Double) -> Data? {
        let maxBytes = Int(maxSizeMB * 1024 * 1024)
        
        // 段階的にリサイズと圧縮品質を調整
        let resizeDimensions: [CGFloat] = [2048, 1536, 1024, 768, 512]
        let compressionQualities: [CGFloat] = [0.9, 0.8, 0.7, 0.6, 0.5]
        
        for dimension in resizeDimensions {
            let resizedImage = resizeImage(image, maxSize: CGSize(width: dimension, height: dimension))
            
            for quality in compressionQualities {
                if let data = resizedImage.jpegData(compressionQuality: quality) {
                    if data.count <= maxBytes {
                        Log.debug("Image compressed: dimension=\(dimension), quality=\(quality), size=\(data.count) bytes", category: .network)
                        return data
                    }
                }
            }
        }
        
        // 最小サイズ・最低品質でも大きすぎる場合
        let minImage = resizeImage(image, maxSize: CGSize(width: 512, height: 512))
        return minImage.jpegData(compressionQuality: 0.4)
    }
    
    /// エラーを処理する
    /// - Parameter error: エラー
    private func handleError(_ error: Error) {
        if let apiError = error as? APIClientError {
            switch apiError {
            case .apiError(let error):
                errorMessage = error.message
            case .networkError:
                errorMessage = "ネットワークエラーが発生しました"
            case .unknown:
                errorMessage = "不明なエラーが発生しました"
            }
        } else {
            errorMessage = error.localizedDescription
        }
        
        Log.error("Profile error: \(error)", category: .network)
    }
}