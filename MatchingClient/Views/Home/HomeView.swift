import SwiftUI

/// ホーム画面（カスタムタブ付き）
struct HomeView: View {
    @State private var selectedTab: TabType = .call
    @EnvironmentObject var authViewModel: AuthViewModel  // ContentViewから渡されるAuthViewModelを使用
    @StateObject private var matchingViewModel = MatchingViewModel()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 背景
            Theme.backgroundGradient
                .ignoresSafeArea()
            
            // コンテンツ
            Group {
                switch selectedTab {
                case .call:
                    MatchingView()
                        .environmentObject(matchingViewModel)
                case .profile:
                    ProfileView()
                }
            }
            
            // カスタムタブバー
            VStack {
                Spacer()
                CustomTabView(selectedTab: $selectedTab)
                    .padding(.bottom, 20)
            }
        }
        .environmentObject(authViewModel)
        .onAppear {
            // Pusher接続を開始
            matchingViewModel.connectPusher()
        }
        .onDisappear {
            // Pusher接続を切断
            matchingViewModel.disconnectPusher()
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthViewModel())
}