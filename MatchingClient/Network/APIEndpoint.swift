import Foundation

/// APIエンドポイントの定義
enum APIEndpoint {
    case login
    case createAccount
    case getAccount
    case updateAccount
    case uploadImage
    case startMatching
    case stopMatching
    case getMatchingToken
    case acceptMatching(userId: Int)
    case rejectMatching(userId: Int)
    case acceptCall(roomId: String)
    case rejectCall(roomId: String)
    case endCall(roomId: String)
    case continueCall(userId: Int)
    case sendMessage
    case getMessages(talkId: Int)
    
    /// エンドポイントのパスを取得
    var path: String {
        switch self {
        case .login:
            return "/login"
        case .createAccount:
            return "/accounts"
        case .getAccount:
            return "/account"
        case .updateAccount:
            return "/accounts"
        case .uploadImage:
            return "/accounts/upload-image"
        case .startMatching:
            return "/matchings"
        case .stopMatching:
            return "/matchings"
        case .getMatchingToken:
            return "/matching/token"
        case .acceptMatching(let userId):
            return "/matching/accept/\(userId)"
        case .rejectMatching(let userId):
            return "/matching/reject/\(userId)"
        case .acceptCall(let roomId):
            return "/call/accept/\(roomId)"
        case .rejectCall(let roomId):
            return "/call/reject/\(roomId)"
        case .endCall(let roomId):
            return "/call/end/\(roomId)"
        case .continueCall(let userId):
            return "/call/continue/\(userId)"
        case .sendMessage:
            return "/messages"
        case .getMessages(let talkId):
            return "/talks/\(talkId)/messages"
        }
    }
}