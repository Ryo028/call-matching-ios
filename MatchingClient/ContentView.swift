//
//  ContentView.swift
//  MatchingClient
//
//  Created by 宮田涼 on 2025/08/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        ZStack {
            if authViewModel.isLoading {
                // ローディング画面
                LoadingView()
                    .transition(.opacity)
            } else if authViewModel.isAuthenticated {
                // ホーム画面
                HomeView()
                    .environmentObject(authViewModel)
                    .transition(.opacity)
            } else {
                // ログイン画面
                LoginView()
                    .environmentObject(authViewModel)
                    .transition(.opacity)
            }
        }
    }
}

/// ローディング画面
struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // 背景グラデーション
            Theme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // ローディングアニメーション
                ZStack {
                    Circle()
                        .fill(Theme.buttonGradient)
                        .frame(width: 100, height: 100)
                        .shadow(color: Theme.buttonShadow, radius: 20, x: 0, y: 10)
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 1.0)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }
                
                Text("認証中...")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Theme.Text.secondary)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview("メイン画面") {
    ContentView()
}

#Preview("ローディング画面") {
    LoadingView()
}
