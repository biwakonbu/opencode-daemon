import SwiftUI

struct FloatingChatView: View {
    @ObservedObject var viewModel: OpenCodeViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            messagesView
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("OpenCode")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            if viewModel.currentSession != nil {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
            } else {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
            }
        }
        .padding()
        .background(Color.black.opacity(0.6))
    }
    
    private var messagesView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.messages) { message in
                    messageBubble(message)
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
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
                    .padding(12)
                    .background(
                        message.role == "user"
                        ? Color.blue.opacity(0.8)
                        : Color.gray.opacity(0.3)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                
                Text(formatDate(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: 320, alignment: message.role == "user" ? .trailing : .leading)
            
            if message.role != "user" {
                Spacer()
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
