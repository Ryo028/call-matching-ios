import Foundation

/// エラーメッセージの定数
enum ErrorMessages {
    /// ネットワークエラー
    enum Network {
        static let noConnection = "インターネット接続がありません"
        static let timeout = "タイムアウトしました"
        static let serverError = "サーバーエラーが発生しました"
        static let unknown = "不明なエラーが発生しました"
    }
    
    /// 認証エラー
    enum Auth {
        static let invalidCredentials = "メールアドレスまたはパスワードが正しくありません"
        static let tokenExpired = "セッションの有効期限が切れました。再度ログインしてください"
        static let unauthorized = "認証が必要です"
        static let emailAlreadyExists = "このメールアドレスは既に使用されています"
    }
    
    /// バリデーションエラー
    enum Validation {
        static let requiredField = "この項目は必須です"
        static let emailRequired = "メールアドレスを入力してください"
        static let invalidEmail = "有効なメールアドレスを入力してください"
        static let passwordRequired = "パスワードを入力してください"
        static let passwordTooShort = "パスワードは8文字以上で入力してください"
        static let passwordsDoNotMatch = "パスワードが一致しません"
        static let passwordMismatch = "パスワードが一致しません"
        static let nameRequired = "名前を入力してください"
        static let ageTooYoung = "18歳以上である必要があります"
        static let invalidAge = "年齢は18歳以上120歳以下で入力してください"
    }
    
    /// マッチングエラー
    enum Matching {
        static let noMatchesFound = "マッチング相手が見つかりませんでした"
        static let matchingTimeout = "マッチングがタイムアウトしました"
        static let alreadyMatching = "既にマッチング中です"
    }
    
    /// 通話エラー
    enum Call {
        static let microphonePermissionDenied = "マイクへのアクセスが拒否されました"
        static let cameraPermissionDenied = "カメラへのアクセスが拒否されました"
        static let connectionFailed = "通話接続に失敗しました"
        static let peerDisconnected = "相手が通話を終了しました"
    }
}