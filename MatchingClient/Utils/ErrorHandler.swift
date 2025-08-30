import Foundation
import SwiftUI

/// エラーアラートを表示するViewModifier
struct ErrorAlert: ViewModifier {
    @Binding var errorMessage: String?
    
    func body(content: Content) -> some View {
        content
            .alert("エラー", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
    }
}

extension View {
    /// エラーアラートを追加
    /// - Parameter errorMessage: エラーメッセージのBinding
    func errorAlert(errorMessage: Binding<String?>) -> some View {
        modifier(ErrorAlert(errorMessage: errorMessage))
    }
}

/// ローディングオーバーレイを表示するViewModifier
struct LoadingOverlay: ViewModifier {
    let isLoading: Bool
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
            
            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
    }
}

extension View {
    /// ローディングオーバーレイを追加
    /// - Parameter isLoading: ローディング状態
    func loadingOverlay(isLoading: Bool) -> some View {
        modifier(LoadingOverlay(isLoading: isLoading))
    }
}