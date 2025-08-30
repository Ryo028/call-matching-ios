import Foundation
import UIKit

/// 画像読み込みユーティリティ
enum ImageLoader {
    
    /// プロフィール画像を非同期で読み込む
    /// - Parameter path: 画像のパス（S3のフルURLまたは相対パス）
    /// - Returns: 読み込んだUIImage、失敗した場合はnil
    static func loadProfileImage(from path: String) async -> UIImage? {
        // S3のURLまたは相対パスから完全なURLを構築
        let imageURL: String
        if path.starts(with: "http://") || path.starts(with: "https://") {
            imageURL = path
        } else {
            // 相対パスの場合はベースURLと結合
            imageURL = AppConfig.API.baseURL.replacingOccurrences(of: "/api", with: "") + "/" + path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }
        
        guard let url = URL(string: imageURL) else {
            Log.warning("Invalid image URL: \(imageURL)", category: .network)
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                Log.debug("Profile image loaded from: \(imageURL)", category: .network)
                return image
            }
        } catch {
            Log.error("Failed to load profile image: \(error)", category: .network)
        }
        
        return nil
    }
}