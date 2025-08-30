import SwiftUI

struct CallEndView: View {
    let callDuration: String
    let otherUserName: String
    @Binding var showCallView: Bool
    @Binding var showCallEndView: Bool
    @Binding var showMatchingSearch: Bool  // マッチング検索画面の表示状態を追加
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // アイコン
                Image(systemName: "phone.down.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .shadow(radius: 10)
                
                // メッセージ
                VStack(spacing: 15) {
                    Text("通話が終了しました")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("\(otherUserName)さんとの通話")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.9))
                    
                    // 通話時間
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.white.opacity(0.8))
                        Text("通話時間: \(callDuration)")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
                }
                
                Spacer()
                    .frame(height: 50)
                
                // ボタンエリア
                VStack(spacing: 20) {
                    // ホームに戻るボタン
                    Button(action: {
                        // 通話終了後のクリーンアップ
                        Task {
                            // 通話終了画面を閉じる
                            showCallEndView = false
                            // 通話画面も閉じる
                            showCallView = false
                            // マッチング検索画面も閉じる（ホームに戻る）
                            showMatchingSearch = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "house.fill")
                            Text("ホームに戻る")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.blue)
                        .cornerRadius(28)
                        .shadow(radius: 5)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding(.top, 100)
        }
        .navigationBarHidden(true)
    }
}

struct CallEndView_Previews: PreviewProvider {
    static var previews: some View {
        CallEndView(
            callDuration: "5:23",
            otherUserName: "田中",
            showCallView: .constant(true),
            showCallEndView: .constant(true),
            showMatchingSearch: .constant(true)
        )
    }
}