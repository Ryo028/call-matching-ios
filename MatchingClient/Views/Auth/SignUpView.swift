import SwiftUI

/// 新規登録画面
struct SignUpView: View {
    @EnvironmentObject var viewModel: AuthViewModel  // LoginViewから渡されるAuthViewModelを使用
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep = 1
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var selectedGender: Gender = .female
    @State private var age = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景グラデーション
                Theme.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // ヘッダー
                    SignUpHeaderView(
                        currentStep: currentStep,
                        dismiss: { dismiss() }
                    )
                    
                    // ステップインジケーター
                    StepIndicator(currentStep: currentStep, totalSteps: 3)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                    
                    // コンテンツ
                    ScrollView {
                        VStack(spacing: 30) {
                            // ステップごとの内容
                            Group {
                                switch currentStep {
                                case 1:
                                    BasicInfoStep(
                                        name: $name,
                                        email: $email
                                    )
                                case 2:
                                    PasswordStep(
                                        password: $password,
                                        confirmPassword: $confirmPassword
                                    )
                                case 3:
                                    ProfileStep(
                                        selectedGender: $selectedGender,
                                        age: $age
                                    )
                                default:
                                    EmptyView()
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing),
                                removal: .move(edge: .leading)
                            ))
                            .animation(.easeInOut, value: currentStep)
                            
                            // ボタン
                            VStack(spacing: 16) {
                                GradientButton(
                                    title: currentStep == 3 ? "登録する" : "次へ",
                                    action: handleNextStep,
                                    isLoading: viewModel.isLoading,
                                    isDisabled: !isCurrentStepValid
                                )
                                
                                if currentStep > 1 {
                                    OutlineButton(
                                        title: "戻る",
                                        action: {
                                            withAnimation {
                                                currentStep -= 1
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    /// 現在のステップのバリデーション
    ///
    /// 各ステップごとに入力値を検証し、次へボタンの有効/無効を制御します。
    /// - Returns: 現在のステップの入力値が有効な場合は`true`
    private var isCurrentStepValid: Bool {
        switch currentStep {
        case 1:
            // ステップ1: 名前とメールアドレスの検証
            return ValidationHelper.isValidName(name) && 
                   ValidationHelper.isValidEmail(email)
        case 2:
            // ステップ2: パスワードの検証
            return ValidationHelper.isValidPassword(password) &&
                   ValidationHelper.passwordsMatch(password, confirmation: confirmPassword)
        case 3:
            // ステップ3: 年齢の検証
            if let ageInt = Int(age) {
                return ValidationHelper.isValidAge(ageInt)
            }
            return false
        default:
            return false
        }
    }
    
    /// 次のステップへ進む処理
    ///
    /// 現在のステップに応じて、次のステップへの遷移または登録処理を実行します。
    private func handleNextStep() {
        if currentStep < 3 {
            // 次のステップへ遷移
            withAnimation {
                currentStep += 1
            }
        } else {
            // 最終ステップ: 登録処理を実行
            performSignUp()
        }
    }
    
    /// 新規登録処理
    ///
    /// 入力値を検証してから新規登録APIを呼び出します。
    private func performSignUp() {
        // 全入力値の最終バリデーション
        if let errorMessage = ValidationHelper.validateSignUpForm(
            name: name,
            email: email,
            password: password,
            passwordConfirmation: confirmPassword,
            age: Int(age)
        ) {
            viewModel.errorMessage = errorMessage
            return
        }
        
        // 非同期で登録処理を実行
        Task {
            await viewModel.createAccount(
                name: name,
                email: email,
                password: password,
                gender: selectedGender.rawValue,
                age: Int(age)
            )
            
            // 登録成功時は画面を閉じる
            if viewModel.isAuthenticated {
                dismiss()
            }
        }
    }
}

/// ヘッダービュー
struct SignUpHeaderView: View {
    let currentStep: Int
    let dismiss: () -> Void
    
    var body: some View {
        HStack {
            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.Text.secondary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white))
                    .shadow(color: Theme.cardShadow, radius: 8, x: 0, y: 4)
            }
            
            Spacer()
            
            Text("新規登録")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Theme.Text.primary)
            
            Spacer()
            
            // バランスを取るための透明なビュー
            Color.clear
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
}

/// ステップインジケーター
struct StepIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                RoundedRectangle(cornerRadius: 4)
                    .fill(step <= currentStep ? Theme.primaryColor : Color.gray.opacity(0.3))
                    .frame(height: 8)
            }
        }
    }
}

/// 基本情報入力ステップ
struct BasicInfoStep: View {
    @Binding var name: String
    @Binding var email: String
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.buttonGradient)
                
                Text("基本情報を入力")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Theme.Text.primary)
                
                Text("あなたのことを教えてください")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Text.secondary)
            }
            .padding(.top, 20)
            
            VStack(spacing: 16) {
                CustomTextField(
                    placeholder: "ニックネーム",
                    text: $name,
                    icon: "person.fill"
                )
                
                CustomTextField(
                    placeholder: "メールアドレス",
                    text: $email,
                    keyboardType: .emailAddress,
                    icon: "envelope.fill"
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            }
            .padding(.horizontal, 20)
        }
    }
}

/// パスワード入力ステップ
struct PasswordStep: View {
    @Binding var password: String
    @Binding var confirmPassword: String
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "lock.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.buttonGradient)
                
                Text("パスワードを設定")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Theme.Text.primary)
                
                Text("8文字以上で英数字を含めてください")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Text.secondary)
            }
            .padding(.top, 20)
            
            VStack(spacing: 16) {
                CustomTextField(
                    placeholder: "パスワード",
                    text: $password,
                    isSecure: true,
                    icon: "lock.fill"
                )
                
                CustomTextField(
                    placeholder: "パスワード（確認）",
                    text: $confirmPassword,
                    isSecure: true,
                    icon: "lock.fill"
                )
            }
            .padding(.horizontal, 20)
        }
    }
}

/// プロフィール入力ステップ
struct ProfileStep: View {
    @Binding var selectedGender: Gender
    @Binding var age: String
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.buttonGradient)
                
                Text("プロフィール設定")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Theme.Text.primary)
                
                Text("もう少しで完了です！")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Text.secondary)
            }
            .padding(.top, 20)
            
            VStack(spacing: 20) {
                // 性別選択
                VStack(alignment: .leading, spacing: 12) {
                    Text("性別")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Text.secondary)
                        .padding(.horizontal, 20)
                    
                    HStack(spacing: 12) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            GenderButton(
                                gender: gender,
                                isSelected: selectedGender == gender,
                                action: {
                                    selectedGender = gender
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // 年齢入力
                CustomTextField(
                    placeholder: "年齢",
                    text: $age,
                    keyboardType: .numberPad,
                    icon: "calendar"
                )
                .padding(.horizontal, 20)
            }
        }
    }
}

/// 性別選択ボタン
struct GenderButton: View {
    let gender: Gender
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: gender == .male ? "person.fill" : "person.dress.line.vertical.figure")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : Theme.Text.secondary)
                
                Text(gender.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : Theme.Text.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Theme.buttonGradient)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                    }
                }
                .shadow(color: isSelected ? Theme.buttonShadow : Theme.cardShadow,
                       radius: isSelected ? 8 : 4,
                       x: 0,
                       y: isSelected ? 4 : 2)
            )
        }
    }
}

#Preview("新規登録画面") {
    SignUpView()
        .environmentObject(AuthViewModel())
}

#Preview("基本情報ステップ") {
    BasicInfoStep(
        name: .constant(""),
        email: .constant("")
    )
    .padding()
    .background(Theme.backgroundGradient)
}

#Preview("パスワードステップ") {
    PasswordStep(
        password: .constant(""),
        confirmPassword: .constant("")
    )
    .padding()
    .background(Theme.backgroundGradient)
}

#Preview("プロフィールステップ") {
    ProfileStep(
        selectedGender: .constant(.female),
        age: .constant("")
    )
    .padding()
    .background(Theme.backgroundGradient)
}

#Preview("性別選択ボタン") {
    HStack(spacing: 12) {
        GenderButton(
            gender: .male,
            isSelected: false,
            action: {}
        )
        GenderButton(
            gender: .female,
            isSelected: true,
            action: {}
        )
    }
    .padding()
    .background(Theme.backgroundGradient)
}