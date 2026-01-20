import SwiftUI

struct InputLauncherView: View {
    @ObservedObject var viewModel: OpenCodeViewModel
    @FocusState private var isFocused: Bool
    let onSendMessage: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            if let errorMessage = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.white)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(8)
                .background(Color.red.opacity(0.8))
                .cornerRadius(8)
            }
            
            VStack(spacing: 8) {
                TextField("メッセージを入力...", text: $viewModel.inputMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isFocused)
                    .font(.body)
                    .onSubmit {
                        onSendMessage()
                    }
                
                HStack(spacing: 12) {
                    Button(action: onCancel) {
                        Text("キャンセル")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: onSendMessage) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("送信")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.inputMessage.isEmpty || viewModel.isLoading)
                    
                    Button(action: {
                        Task {
                            await viewModel.captureAndSendScreenshot()
                            onCancel()
                        }
                    }) {
                        Image(systemName: "camera")
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isLoading || viewModel.currentSession == nil)
                }
            }
            .padding(16)
            .background(Color.black.opacity(0.7))
            .cornerRadius(16)
        }
        .padding(24)
        .onAppear {
            isFocused = true
        }
    }
}
