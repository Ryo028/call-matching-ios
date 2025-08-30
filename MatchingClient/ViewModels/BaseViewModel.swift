import Foundation
import Combine

/// ViewModelの基底プロトコル
@MainActor
protocol BaseViewModel: ObservableObject {
    /// ローディング状態
    var isLoading: Bool { get set }
    
    /// エラーメッセージ
    var errorMessage: String? { get set }
    
    /// エラーハンドリング
    /// - Parameter error: 発生したエラー
    func handleError(_ error: Error)
}

extension BaseViewModel {
    /// デフォルトのエラーハンドリング実装
    ///
    /// エラーをログに記録し、ユーザーに表示するメッセージを設定します。
    /// - Parameter error: 処理するエラー
    func handleError(_ error: Error) {
        isLoading = false
        
        // エラーログを出力
        Log.error("Error occurred: \(error)", category: .general)
        
        // エラーメッセージを設定
        if let apiError = error as? APIClientError {
            errorMessage = apiError.errorDescription
            
            // APIエラーの詳細をログ出力
            if case .apiError(let apiErrorDetail) = apiError {
                Log.error("API Error: \(apiErrorDetail.message)", category: .api)
                if let errors = apiErrorDetail.errors {
                    Log.error("Validation Errors: \(errors)", category: .api)
                }
            } else {
                Log.error("API Error: \(apiError.errorDescription ?? "Unknown")", category: .api)
            }
        } else {
            errorMessage = error.localizedDescription
            Log.error("System Error: \(error.localizedDescription)", category: .general)
        }
    }
}