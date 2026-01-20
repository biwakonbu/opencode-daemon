import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: OpenCodeViewModel
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            messagesView
            Divider()
            inputView
        }
        .frame(width: 400, height: 500)
        .onAppear {
            isInputFocused = true
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("OpenCode")
                .font(.headline)
                .padding(.leading)
            
            Spacer()
            
            if viewModel.currentSession != nil {
                Text("アクティブ")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Text("非アクティブ")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
    }
    
    private var messagesView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.messages) { message in
                    messageBubble(message)
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .padding()
                }
            }
            .padding()
        }
    }
    
    private func messageBubble(_ message: OpenCodeMessage) -> some View {
        HStack {
            if message.role == "user" {
                Spacer()
            }
            
            VStack(alignment: message.role == "user" ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .padding(10)
                    .background(message.role == "user" ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(message.role == "user" ? .white : .primary)
                    .cornerRadius(10)
                
                Text(formatDate(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: 280, alignment: message.role == "user" ? .trailing : .leading)
            
            if message.role != "user" {
                Spacer()
            }
        }
    }
    
    private var inputView: some View {
        VStack(spacing: 8) {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            HStack(spacing: 8) {
                TextField("メッセージを入力...", text: $viewModel.inputMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isInputFocused)
                    .onSubmit {
                        Task {
                            await viewModel.sendMessage()
                        }
                    }
                
                Button(action: {
                    Task {
                        await viewModel.sendMessage()
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.inputMessage.isEmpty || viewModel.isLoading)
                
                Button(action: {
                    Task {
                        await viewModel.captureAndSendScreenshot()
                    }
                }) {
                    Image(systemName: "camera")
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isLoading || viewModel.currentSession == nil)
            }
            .padding(.horizontal)
            
            HStack(spacing: 8) {
                Spacer()
                
                Button(action: {
                    Task {
                        await viewModel.createSession()
                    }
                }) {
                    Text("セッション作成")
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isLoading)
                
                Button(action: {
                    viewModel.clearSession()
                }) {
                    Text("クリア")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
