import Foundation
import Alamofire

/// API通信を管理するシングルトンクラス
///
/// 全てのAPI通信はこのクラスを通じて行われます。
/// 認証トークンの管理とHTTPリクエストの共通処理を提供します。
final class APIClient: @unchecked Sendable {
    /// 共有インスタンス
    static let shared = APIClient()
    
    /// APIのベースURL
    private let baseURL = AppConfig.API.baseURL
    
    /// 認証トークン（AuthViewModelから直接アクセス可能）
    var authToken: String?
    
    /// JSONデコーダー（Laravel API用の共通設定を使用）
    private let jsonDecoder: JSONDecoder = JSONDecoder.laravelDecoder
    
    private init() {}
    
    /// HTTPヘッダーを生成
    private var headers: HTTPHeaders {
        var headers: HTTPHeaders = [
            APIConstants.Headers.contentType: APIConstants.Headers.applicationJson,
            APIConstants.Headers.accept: APIConstants.Headers.applicationJson
        ]
        
        if let token = authToken {
            headers[APIConstants.Headers.authorization] = "\(APIConstants.Headers.bearer) \(token)"
        }
        
        return headers
    }
    /// APIリクエストを実行
    ///
    /// - Parameters:
    ///   - endpoint: APIエンドポイント
    ///   - method: HTTPメソッド（デフォルト: GET）
    ///   - parameters: リクエストパラメータ
    ///   - encoding: パラメータエンコーディング（デフォルト: JSON）
    ///   - responseType: レスポンスの型
    /// - Returns: デコードされたレスポンス
    /// - Throws: `APIClientError`
    func request<T: Codable>(
        _ endpoint: APIEndpoint,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = JSONEncoding.default,
        responseType: T.Type
    ) async throws -> T {
        let url = baseURL + endpoint.path
        
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(
                url,
                method: method,
                parameters: parameters,
                encoding: encoding,
                headers: headers
            )
            .validate()
            .responseDecodable(of: T.self, decoder: jsonDecoder) { response in
                // リクエストログを出力
                Logger.shared.logAPIRequest(
                    url: url,
                    method: method.rawValue,
                    headers: self.headers.dictionary,
                    parameters: parameters
                )
                
                // レスポンスログを出力
                switch response.result {
                case .success(let data):
                    Logger.shared.logAPIResponse(
                        statusCode: response.response?.statusCode,
                        data: response.data,
                        decodedObject: data
                    )
                    continuation.resume(returning: data)
                    
                case .failure(let error):
                    // APIエラーをデコードしてログに含める
                    var decodedError: APIError?
                    if let data = response.data {
                        decodedError = try? self.jsonDecoder.decode(APIError.self, from: data)
                    }
                    
                    Logger.shared.logAPIResponse(
                        statusCode: response.response?.statusCode,
                        data: response.data,
                        error: error,
                        decodedObject: decodedError
                    )
                    
                    if let apiError = decodedError {
                        continuation.resume(throwing: APIClientError.apiError(apiError))
                    } else {
                        continuation.resume(throwing: APIClientError.networkError(error))
                    }
                }
            }
        }
    }
    
    /// ファイルをアップロード
    ///
    /// - Parameters:
    ///   - endpoint: APIエンドポイント
    ///   - data: アップロードするデータ
    ///   - fileName: ファイル名
    ///   - mimeType: MIMEタイプ
    ///   - parameters: 追加パラメータ
    ///   - responseType: レスポンスの型
    /// - Returns: デコードされたレスポンス
    /// - Throws: `APIClientError`
    func upload<T: Codable>(
        _ endpoint: APIEndpoint,
        data: Data,
        fileName: String,
        mimeType: String,
        parameters: [String: String]? = nil,
        responseType: T.Type
    ) async throws -> T {
        let url = baseURL + endpoint.path
        
        return try await withCheckedThrowingContinuation { continuation in
            AF.upload(
                multipartFormData: { multipartFormData in
                    multipartFormData.append(
                        data,
                        withName: APIConstants.Multipart.imageName,
                        fileName: fileName,
                        mimeType: mimeType
                    )
                    
                    parameters?.forEach { key, value in
                        if let data = value.data(using: .utf8) {
                            multipartFormData.append(data, withName: key)
                        }
                    }
                },
                to: url,
                headers: headers
            )
            .validate()
            .responseDecodable(of: T.self, decoder: jsonDecoder) { response in
                // アップロードログを出力
                Logger.shared.logAPIUpload(
                    url: url,
                    fileName: fileName,
                    mimeType: mimeType,
                    parameters: parameters
                )
                
                // レスポンスログを出力
                switch response.result {
                case .success(let data):
                    Logger.shared.logAPIResponse(
                        statusCode: response.response?.statusCode,
                        data: response.data,
                        decodedObject: data
                    )
                    continuation.resume(returning: data)
                    
                case .failure(let error):
                    // APIエラーをデコードしてログに含める
                    var decodedError: APIError?
                    if let data = response.data {
                        decodedError = try? self.jsonDecoder.decode(APIError.self, from: data)
                    }
                    
                    Logger.shared.logAPIResponse(
                        statusCode: response.response?.statusCode,
                        data: response.data,
                        error: error,
                        decodedObject: decodedError
                    )
                    
                    if let apiError = decodedError {
                        continuation.resume(throwing: APIClientError.apiError(apiError))
                    } else {
                        continuation.resume(throwing: APIClientError.networkError(error))
                    }
                }
            }
        }
    }
    
    /// 通話継続リクエストを送信
    /// - Parameters:
    ///   - userId: 相手のユーザーID
    ///   - roomId: ルームID
    ///   - wantsToContinue: 継続するかどうか
    /// - Returns: レスポンス
    func continueCall(userId: Int, roomId: String, wantsToContinue: Bool) async throws -> ContinueCallResponse {
        struct ContinueCallRequest: Encodable {
            let roomId: String
            let wantsToContinue: Bool
            
            enum CodingKeys: String, CodingKey {
                case roomId = "room_id"
                case wantsToContinue = "wants_to_continue"
            }
        }
        
        let parameters = ContinueCallRequest(roomId: roomId, wantsToContinue: wantsToContinue)
        
        return try await request(
            .continueCall(userId: userId),
            method: .put,
            parameters: try? JSONEncoder().encode(parameters).jsonObject(),
            responseType: ContinueCallResponse.self
        )
    }
}

/// 通話継続レスポンス
struct ContinueCallResponse: Codable {
    let isSuccess: Bool
    
    enum CodingKeys: String, CodingKey {
        case isSuccess = "is_success"
    }
    
    // successプロパティへのアクセスを提供（後方互換性のため）
    var success: Bool {
        return isSuccess
    }
}

// JSON Data から Dictionary への変換拡張
extension Data {
    func jsonObject() -> [String: Any]? {
        try? JSONSerialization.jsonObject(with: self, options: []) as? [String: Any]
    }
}

/// APIクライアントのエラー
enum APIClientError: LocalizedError {
    /// APIエラー
    case apiError(APIError)
    /// ネットワークエラー
    case networkError(AFError)
    /// 不明なエラー
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .apiError(let error):
            // バリデーションエラーの場合は詳細メッセージを表示
            return error.detailedMessage
        case .networkError(let error):
            return error.localizedDescription
        case .unknown:
            return ErrorMessages.Network.unknown
        }
    }
}

/// APIからのエラーレスポンス
struct APIError: Codable {
    /// エラーメッセージ
    let message: String
    /// 詳細なエラー情報（フィールド別のエラー）
    let errors: [String: [String]]?
    
    /// ユーザーに表示する詳細なエラーメッセージ
    ///
    /// バリデーションエラーの場合は各フィールドのエラーメッセージを結合して返します。
    /// それ以外の場合は基本メッセージを返します。
    var detailedMessage: String {
        // バリデーションエラーがある場合
        if let errors = errors, !errors.isEmpty {
            // 各フィールドのエラーメッセージを結合
            let errorMessages = errors.flatMap { (field, messages) in
                messages.map { message in
                    // フィールド名を日本語に変換（必要に応じて）
                    let fieldName = fieldNameInJapanese(field)
                    return fieldName.isEmpty ? message : "\(fieldName): \(message)"
                }
            }
            
            // メッセージが1つの場合はそのまま、複数の場合は改行で結合
            if errorMessages.count == 1 {
                return errorMessages[0]
            } else {
                return errorMessages.joined(separator: "\n")
            }
        }
        
        // バリデーションエラーでない場合は基本メッセージを返す
        return message
    }
    
    /// フィールド名を日本語に変換
    ///
    /// - Parameter field: APIのフィールド名
    /// - Returns: 日本語のフィールド名（該当しない場合は空文字）
    private func fieldNameInJapanese(_ field: String) -> String {
        switch field {
        case "email":
            return ""  // メッセージに既に含まれている場合が多いので空にする
        case "password":
            return ""
        case "name":
            return ""
        case "device_id":
            return ""
        case "age":
            return ""
        case "gender_type":
            return ""
        default:
            return ""
        }
    }
}
