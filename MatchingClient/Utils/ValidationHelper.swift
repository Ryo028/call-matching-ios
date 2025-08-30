import Foundation

/// 入力値のバリデーションを行うヘルパークラス
///
/// アプリ全体で使用される共通のバリデーション処理を提供します。
/// 各種フォーム入力値の妥当性を検証するメソッドを含みます。
enum ValidationHelper {
    
    // MARK: - Email Validation
    
    /// メールアドレスの形式を検証
    ///
    /// RFC 5322に基づいた簡易的なメールアドレス検証を行います。
    ///
    /// - Parameter email: 検証するメールアドレス
    /// - Returns: メールアドレスが有効な形式の場合は`true`、そうでない場合は`false`
    ///
    /// ## Example
    /// ```swift
    /// let isValid = ValidationHelper.isValidEmail("user@example.com")
    /// print(isValid) // true
    /// ```
    static func isValidEmail(_ email: String) -> Bool {
        // 空文字チェック
        guard !email.isEmpty else { return false }
        
        // 正規表現パターン（簡易版）
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // MARK: - Password Validation
    
    /// パスワードの強度を検証
    ///
    /// パスワードが最小要件を満たしているかを確認します。
    ///
    /// - Parameter password: 検証するパスワード
    /// - Returns: パスワードが要件を満たす場合は`true`、そうでない場合は`false`
    ///
    /// ## Requirements
    /// - 最小8文字以上
    /// - 最大128文字以下
    static func isValidPassword(_ password: String) -> Bool {
        // 文字数チェック（8文字以上、128文字以下）
        return password.count >= APIConstants.Validation.minPasswordLength &&
               password.count <= APIConstants.Validation.maxPasswordLength
    }
    
    /// パスワードの確認が一致するか検証
    ///
    /// - Parameters:
    ///   - password: パスワード
    ///   - confirmation: 確認用パスワード
    /// - Returns: 両方のパスワードが一致する場合は`true`、そうでない場合は`false`
    static func passwordsMatch(_ password: String, confirmation: String) -> Bool {
        return !password.isEmpty && password == confirmation
    }
    
    // MARK: - Name Validation
    
    /// ユーザー名の妥当性を検証
    ///
    /// - Parameter name: 検証するユーザー名
    /// - Returns: ユーザー名が要件を満たす場合は`true`、そうでない場合は`false`
    ///
    /// ## Requirements
    /// - 空文字でない
    /// - 最大50文字以下
    static func isValidName(_ name: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && trimmedName.count <= APIConstants.Validation.maxNameLength
    }
    
    // MARK: - Age Validation
    
    /// 年齢の妥当性を検証
    ///
    /// - Parameter age: 検証する年齢
    /// - Returns: 年齢が有効な範囲内の場合は`true`、そうでない場合は`false`
    ///
    /// ## Requirements
    /// - 18歳以上
    /// - 120歳以下
    static func isValidAge(_ age: Int) -> Bool {
        return age >= APIConstants.Validation.minAge && age <= APIConstants.Validation.maxAge
    }
    
    // MARK: - Form Validation
    
    /// ログインフォームの入力値を一括検証
    ///
    /// - Parameters:
    ///   - email: メールアドレス
    ///   - password: パスワード
    /// - Returns: 検証結果（成功時は`nil`、失敗時はエラーメッセージ）
    static func validateLoginForm(email: String, password: String) -> String? {
        // メールアドレスの検証
        if email.isEmpty {
            return ErrorMessages.Validation.emailRequired
        }
        
        if !isValidEmail(email) {
            return ErrorMessages.Validation.invalidEmail
        }
        
        // パスワードの検証
        if password.isEmpty {
            return ErrorMessages.Validation.passwordRequired
        }
        
        return nil
    }
    
    /// 新規登録フォームの入力値を一括検証
    ///
    /// - Parameters:
    ///   - name: ユーザー名
    ///   - email: メールアドレス
    ///   - password: パスワード
    ///   - passwordConfirmation: パスワード確認
    ///   - age: 年齢（オプション）
    /// - Returns: 検証結果（成功時は`nil`、失敗時はエラーメッセージ）
    static func validateSignUpForm(
        name: String,
        email: String,
        password: String,
        passwordConfirmation: String,
        age: Int?
    ) -> String? {
        // 名前の検証
        if !isValidName(name) {
            return ErrorMessages.Validation.nameRequired
        }
        
        // メールアドレスの検証
        if email.isEmpty {
            return ErrorMessages.Validation.emailRequired
        }
        
        if !isValidEmail(email) {
            return ErrorMessages.Validation.invalidEmail
        }
        
        // パスワードの検証
        if password.isEmpty {
            return ErrorMessages.Validation.passwordRequired
        }
        
        if !isValidPassword(password) {
            return ErrorMessages.Validation.passwordTooShort
        }
        
        // パスワード確認の検証
        if !passwordsMatch(password, confirmation: passwordConfirmation) {
            return ErrorMessages.Validation.passwordMismatch
        }
        
        // 年齢の検証（任意項目）
        if let age = age, !isValidAge(age) {
            return ErrorMessages.Validation.invalidAge
        }
        
        return nil
    }
}