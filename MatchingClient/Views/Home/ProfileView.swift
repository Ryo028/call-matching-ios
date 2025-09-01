import SwiftUI

/// プロフィール画面
struct ProfileView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var viewModel: ProfileViewModel
    
    @State private var isEditing = false
    @State private var showingImagePicker = false
    @State private var showingLogoutAlert = false
    
    // 編集用の一時的な値
    @State private var editingName = ""
    @State private var editingAge = ""
    @State private var editingGender = Gender.female
    @State private var editingBio = ""
    @State private var tempProfileImage: UIImage?
    @State private var hasSelectedNewImage = false
    
    var body: some View {
        ZStack {
            // 背景グラデーション（親ViewのNavigationViewから提供される背景と合わせる）
            Color.clear
            
            if viewModel.isLoading && viewModel.user == nil {
                // 初回ローディング
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Theme.primaryColor))
                    .scaleEffect(1.5)
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                            // プロフィール画像セクション
                            ProfileImageSection(
                                profileImage: isEditing ? $tempProfileImage : .constant(viewModel.profileImage),
                                isEditing: isEditing,
                                showingImagePicker: $showingImagePicker,
                                isUploadingImage: viewModel.isUploadingImage
                            )
                            
                            // ユーザー情報カード
                            UserInfoCard(
                                userName: isEditing ? $editingName : .constant(viewModel.user?.name ?? ""),
                                userEmail: .constant(viewModel.user?.email ?? ""),
                                userAge: isEditing ? $editingAge : .constant(String(viewModel.user?.age ?? 0)),
                                userGender: isEditing ? $editingGender : .constant(Gender(rawValue: viewModel.user?.genderType ?? 0) ?? .none),
                                userBio: isEditing ? $editingBio : .constant(viewModel.user?.profile ?? ""),
                                isEditing: isEditing
                            )
                            
                            // アクションボタン
                            VStack(spacing: 16) {
                                if !isEditing {
                                    // 編集ボタン
                                    GradientButton(
                                        title: "プロフィールを編集",
                                        action: startEditing,
                                        isLoading: false
                                    )
                                    
                                    // ログアウトボタン
                                    OutlineButton(
                                        title: "ログアウト",
                                        action: { showingLogoutAlert = true }
                                    )
                                } else {
                                    // 保存ボタン
                                    GradientButton(
                                        title: "保存",
                                        action: saveProfile,
                                        isLoading: viewModel.isLoading
                                    )
                                    .disabled(viewModel.isLoading)
                                    
                                    // キャンセルボタン
                                    OutlineButton(
                                        title: "キャンセル",
                                        action: cancelEditing
                                    )
                                    .disabled(viewModel.isLoading)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 100) // タブバーの高さ分余白を追加
                        }
                    }
                }
            }
            .alert("ログアウト", isPresented: $showingLogoutAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("ログアウト", role: .destructive) {
                    Task {
                        await authViewModel.logout()
                    }
                }
            } message: {
                Text("本当にログアウトしますか？")
            }
            .imagePickerActionSheet(isPresented: $showingImagePicker, selectedImage: $tempProfileImage)
            .onChange(of: showingImagePicker) { isShowing in
                // ImagePickerが表示された時にフラグを設定
                if isShowing {
                    hasSelectedNewImage = true
                }
            }
            .onChange(of: tempProfileImage) { newImage in
                // 画像が選択されたら即座にアップロード
                // ImagePickerから明示的に選択された場合のみアップロード
                if let image = newImage, 
                   isEditing,
                   hasSelectedNewImage {
                    Task {
                        await viewModel.uploadProfileImage(image)
                        hasSelectedNewImage = false
                    }
                }
            }
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .alert("成功", isPresented: .constant(viewModel.successMessage != nil)) {
                Button("OK") {
                    viewModel.successMessage = nil
                    if viewModel.successMessage?.contains("プロフィール") == true {
                        isEditing = false
                    }
                }
            } message: {
                Text(viewModel.successMessage ?? "")
            }
        .task {
            // 初回読み込み
            if viewModel.user == nil {
                await viewModel.loadUserProfile()
            }
        }
    }
    
    /// 編集を開始
    private func startEditing() {
        guard let user = viewModel.user else { return }
        
        editingName = user.name
        editingAge = String(user.age ?? 25)
        editingGender = Gender(rawValue: user.genderType) ?? .female
        editingBio = user.profile ?? ""
        tempProfileImage = viewModel.profileImage
        hasSelectedNewImage = false  // フラグをリセット
        isEditing = true
    }
    
    /// 編集をキャンセル
    private func cancelEditing() {
        tempProfileImage = viewModel.profileImage
        isEditing = false
    }
    
    /// プロフィールを保存
    private func saveProfile() {
        Task {
            await viewModel.updateProfile(
                name: editingName,
                age: Int(editingAge) ?? 25,
                genderType: editingGender.rawValue,
                profile: editingBio
            )
            
            // 成功したら編集モードを終了
            if viewModel.errorMessage == nil {
                isEditing = false
            }
        }
    }
}

/// プロフィール画像セクション
struct ProfileImageSection: View {
    @Binding var profileImage: UIImage?
    let isEditing: Bool
    @Binding var showingImagePicker: Bool
    let isUploadingImage: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // プロフィール画像
                if let image = profileImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Theme.buttonGradient)
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        )
                }
                
                // アップロード中のインジケーター
                if isUploadingImage {
                    Circle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 120, height: 120)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        )
                }
                
                // 編集バッジ
                if isEditing && !isUploadingImage {
                    Circle()
                        .fill(Theme.primaryColor)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        )
                        .offset(x: 40, y: 40)
                        .onTapGesture {
                            showingImagePicker = true
                        }
                }
            }
            .shadow(color: Theme.cardShadow, radius: 10, x: 0, y: 5)
            
            Text("プロフィール")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Theme.Text.primary)
        }
        .padding(.top, 40)
    }
}

/// ユーザー情報カード
struct UserInfoCard: View {
    @Binding var userName: String
    @Binding var userEmail: String
    @Binding var userAge: String
    @Binding var userGender: Gender
    @Binding var userBio: String
    let isEditing: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // 名前
            ProfileInfoRow(
                label: "名前",
                value: $userName,
                isEditing: isEditing,
                icon: "person.fill"
            )
            
            // メールアドレス
            ProfileInfoRow(
                label: "メールアドレス",
                value: $userEmail,
                isEditing: false, // メールは編集不可
                icon: "envelope.fill",
                keyboardType: .emailAddress
            )
            
            // 年齢
            ProfileInfoRow(
                label: "年齢",
                value: $userAge,
                isEditing: isEditing,
                icon: "calendar",
                keyboardType: .numberPad
            )
            
            // 性別（編集不可）
            HStack {
                Label("性別", systemImage: "person.2.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Text.secondary)
                    .frame(width: 100, alignment: .leading)
                
                Text(userGender.displayName)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Text.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 20)
            
            // 自己紹介
            VStack(alignment: .leading, spacing: 8) {
                Label("自己紹介", systemImage: "text.bubble.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Text.secondary)
                
                if isEditing {
                    TextEditor(text: $userBio)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Text.primary)
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.1))
                        )
                } else {
                    Text(userBio.isEmpty ? "自己紹介を入力してください" : userBio)
                        .font(.system(size: 14))
                        .foregroundColor(userBio.isEmpty ? Theme.Text.secondary : Theme.Text.primary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.05))
                        )
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Theme.cardShadow, radius: 15, x: 0, y: 8)
        )
        .padding(.horizontal, 20)
    }
}

/// プロフィール情報行
struct ProfileInfoRow: View {
    let label: String
    @Binding var value: String
    let isEditing: Bool
    let icon: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.Text.secondary)
                .frame(width: 100, alignment: .leading)
            
            if isEditing {
                TextField(label, text: $value)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Text.primary)
                    .keyboardType(keyboardType)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            } else {
                Text(value.isEmpty ? "-" : value)
                    .font(.system(size: 16))
                    .foregroundColor(value.isEmpty ? Theme.Text.secondary : Theme.Text.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 20)
    }
}

#Preview("プロフィール画面") {
    ProfileView()
        .environmentObject(AuthViewModel())
        .environmentObject(ProfileViewModel())
}

#Preview("編集モード") {
    ProfileView()
        .environmentObject(AuthViewModel())
        .environmentObject(ProfileViewModel())
}