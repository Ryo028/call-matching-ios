import SwiftUI

/// ログイン画面
struct LoginView: View {
    @EnvironmentObject var viewModel: AuthViewModel  // ContentViewから渡されるAuthViewModelを使用
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
    @State private var isAnimating = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景グラデーション
                Theme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // ロゴとタイトル
                        VStack(spacing: 20) {
                            // ハートのアニメーションアイコン
                            ZStack {
                                Circle()
                                    .fill(Theme.buttonGradient)
                                    .frame(width: 120, height: 120)
                                    .shadow(color: Theme.buttonShadow, radius: 20, x: 0, y: 10)
                                
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                                    .animation(
                                        Animation.easeInOut(duration: 1.5)
                                            .repeatForever(autoreverses: true),
                                        value: isAnimating
                                    )
                            }
                            .padding(.top, 60)
                            
                            VStack(spacing: 8) {
                                Text("おかえりなさい！")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(Theme.Text.primary)
                                
                                Text("素敵な出会いが待っています")
                                    .font(.system(size: 16))
                                    .foregroundColor(Theme.Text.secondary)
                            }
                        }
                        
                        // 入力フォーム
                        VStack(spacing: 16) {
                            CustomTextField(
                                placeholder: "メールアドレス",
                                text: $email,
                                keyboardType: .emailAddress,
                                icon: "envelope.fill"
                            )
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            
                            CustomTextField(
                                placeholder: "パスワード",
                                text: $password,
                                isSecure: true,
                                icon: "lock.fill"
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // ログインボタン
                        VStack(spacing: 16) {
                            GradientButton(
                                title: "ログイン",
                                action: handleLogin,
                                isLoading: viewModel.isLoading,
                                isDisabled: !isFormValid
                            )
                            
                            Button(action: {
                                // パスワードリセット処理
                            }) {
                                Text("パスワードをお忘れですか？")
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.Text.secondary)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // 区切り線
                        HStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                            
                            Text("または")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.Text.secondary)
                                .padding(.horizontal, 10)
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 40)
                        
                        // 新規登録ボタン
                        OutlineButton(
                            title: "新規登録はこちら",
                            action: {
                                showingSignUp = true
                            }
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                isAnimating = true
            }
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .sheet(isPresented: $showingSignUp) {
                SignUpView()
                    .environmentObject(viewModel)  // AuthViewModelを渡す
            }
        }
    }
    
    /// フォームのバリデーション
    ///
    /// メールアドレスとパスワードの入力状態を確認し、
    /// ログインボタンの有効/無効を制御します。
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    /// ログイン処理
    ///
    /// バリデーションを実行してからログイン処理を開始します。
    /// エラーがある場合はViewModelにエラーメッセージを設定します。
    private func handleLogin() {
        // 入力値のバリデーション
        if let errorMessage = ValidationHelper.validateLoginForm(
            email: email,
            password: password
        ) {
            viewModel.errorMessage = errorMessage
            return
        }
        
        // 非同期でログイン処理を実行
        Task {
            await viewModel.login(email: email, password: password)
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}