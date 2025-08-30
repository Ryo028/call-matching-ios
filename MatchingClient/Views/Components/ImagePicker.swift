import SwiftUI

/// 画像選択機能を提供するView
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    let sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true // 画像を正方形にクロップ
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // 編集後の画像を優先、なければオリジナル画像を使用
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}


/// 画像選択のアクションシート
struct ImagePickerActionSheet: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    func body(content: Content) -> some View {
        content
            .confirmationDialog("プロフィール画像を選択", isPresented: $isPresented, titleVisibility: .visible) {
                Button("カメラで撮影") {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        sourceType = .camera
                        showCamera = true
                    }
                }
                
                Button("ライブラリから選択") {
                    sourceType = .photoLibrary
                    showImagePicker = true
                }
                
                if selectedImage != nil {
                    Button("画像を削除", role: .destructive) {
                        selectedImage = nil
                    }
                }
                
                Button("キャンセル", role: .cancel) {}
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage, sourceType: sourceType)
            }
            .fullScreenCover(isPresented: $showCamera) {
                ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
            }
    }
}

extension View {
    /// 画像選択アクションシートを表示する
    func imagePickerActionSheet(isPresented: Binding<Bool>, selectedImage: Binding<UIImage?>) -> some View {
        modifier(ImagePickerActionSheet(isPresented: isPresented, selectedImage: selectedImage))
    }
}