import SwiftUI

/// ホーム画面（カスタムタブ付き）
struct HomeView: View {
    
    @State private var selectedTab: TabType = .call
    @State private var isShowMatchingView = false
    @State private var isShowSetting = false
    @State private var genderType: GenderType = .all
    
    /// ContentViewから渡されるAuthViewModelを使用
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @StateObject private var matchingViewModel = MatchingViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景グラデーション
                Theme.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // メインコンテンツ
                    if selectedTab == .call {
                        // 通話タブの内容
                        VStack {
                            Text("どんな人とトークする？？")
                                .foregroundColor(Theme.Text.primary)
                                .font(.system(.title, design: .rounded))
                                .bold()
                                .padding(.top, 80)
                            
                            // 3D性別選択カード
                            Gender3DCardSelectionView(selectedGender: $genderType)
                                .padding(.top, 30)
                                .padding(.bottom, 20)
                            
                            Spacer()
                            
                            // 通話開始ボタン
                            Button(action: {
                                isShowMatchingView = true
                            }) {
                                Text("Goooo")
                                    .foregroundStyle(Theme.Text.primary)
                                    .font(.title)
                                    .bold()
                                    .italic()
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: .infinity)
                                    .stroke(Theme.buttonGradient, lineWidth: 5)
                                    .frame(width: 200, height: 60)
                                HStack {
                                    Image(systemName: "phone.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(Theme.primaryColor)
                                    Spacer(minLength: 150)
                                }
                            }
                            .padding(.bottom, 120) // タブバーの高さ分余白を増やす
                            .fullScreenCover(isPresented: $isShowMatchingView) {
                                MatchingSearchView(
                                    isPresented: $isShowMatchingView,
                                    matchingViewModel: matchingViewModel,
                                    selectedGender: genderType == .male ? .male : 
                                                   genderType == .female ? .female : nil,
                                    ageRange: 18.0...61.0,  // 61は制限なし
                                    distance: 301.0         // 301は制限なし
                                )
                                .onAppear {
                                    Task { @MainActor in
                                        await matchingViewModel.resetMatching()
                                    }
                                }
                            }
                        }
                    } else if selectedTab == .profile {
                        ProfileView()
                            .environmentObject(profileViewModel)
                            .frame(maxHeight: .infinity)
                    }
                }
                
                // カスタムタブバーを最前面に配置
                VStack {
                    Spacer()
                    CustomTabView(selectedTab: $selectedTab)
                        .padding(.bottom)
                        .background(
                            Color.white.opacity(0.95)
                                .blur(radius: 10)
                                .ignoresSafeArea()
                        )
                }
            }
            .navigationTitle("ランダムマッチ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowSetting = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.primaryColor)
                    }
                }
            }
            .sheet(isPresented: $isShowSetting) {
                MatchingSettingsView(
                    ageRange: .constant(18.0...61.0),  // 61は制限なし
                    distanceRange: .constant(301.0),   // 301は制限なし
                    isPresented: $isShowSetting
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
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
