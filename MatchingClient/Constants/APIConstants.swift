import Foundation

/// API関連の定数
enum APIConstants {
    /// HTTPヘッダー
    enum Headers {
        static let contentType = "Content-Type"
        static let accept = "Accept"
        static let authorization = "Authorization"
        static let applicationJson = "application/json"
        static let bearer = "Bearer"
    }
    
    /// HTTPメソッド
    enum Methods {
        static let get = "GET"
        static let post = "POST"
        static let put = "PUT"
        static let delete = "DELETE"
        static let patch = "PATCH"
    }
    
    /// タイムアウト設定
    enum Timeout {
        static let request: TimeInterval = 30
        static let resource: TimeInterval = 60
        static let upload: TimeInterval = 300
    }
    
    /// HTTPステータスコード
    ///
    /// APIレスポンスの状態を示すHTTPステータスコード定数
    enum StatusCode {
        /// 200: リクエスト成功（GET, PUT, DELETE等で使用）
        static let success = 200
        
        /// 201: リソース作成成功（POST等で新規作成時に使用）
        static let created = 201
        
        /// 400: 不正なリクエスト（クライアント側のリクエスト形式が不正）
        static let badRequest = 400
        
        /// 401: 認証エラー（ログインが必要、またはトークンが無効/期限切れ）
        static let unauthorized = 401
        
        /// 403: アクセス権限なし（認証済みだが、リソースへのアクセス権限がない）
        static let forbidden = 403
        
        /// 404: リソースが見つからない（指定されたエンドポイントやリソースが存在しない）
        static let notFound = 404
        
        /// 422: バリデーションエラー（リクエストは正しいが、データ内容が不正）
        static let unprocessableEntity = 422
        
        /// 500: サーバー内部エラー（サーバー側の処理で予期しないエラーが発生）
        static let serverError = 500
    }
    
    /// マルチパート
    enum Multipart {
        static let imageName = "user_image"  // サーバー側のフィールド名に合わせる
        static let imageMimeType = "image/jpeg"
        static let imageExtension = ".jpg"
    }
    
    /// バリデーション関連の定数
    enum Validation {
        static let minPasswordLength = 8
        static let maxPasswordLength = 128
        static let maxNameLength = 50
        static let minAge = 18
        static let maxAge = 120
    }
}