import AppKit
import SwiftUI

struct InputLauncherView: View {
    @ObservedObject var viewModel: OpenCodeViewModel
    @FocusState private var isFocused: Bool
    @State private var isVisible = false
    let onSendMessage: () -> Void
    let onCancel: () -> Void
    
    private var trimmedInput: String {
        viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var hasPendingImage: Bool {
        viewModel.pendingImageData != nil
    }
    
    private var pendingImage: NSImage? {
        guard let data = viewModel.pendingImageData else { return nil }
        return NSImage(data: data)
    }
    
    private var isSendDisabled: Bool {
        (trimmedInput.isEmpty && !hasPendingImage) || viewModel.isLoading
    }
    
    private var accentGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.18, green: 0.54, blue: 0.95),
                Color(red: 0.22, green: 0.78, blue: 0.68)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        ZStack {
            launcherBackground
            content
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 10)
        }
        .padding(16)
        .onAppear {
            DispatchQueue.main.async {
                isFocused = true
            }
            withAnimation(.easeOut(duration: 0.25)) {
                isVisible = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            DispatchQueue.main.async {
                isFocused = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .inputLauncherFocusRequested)) { _ in
            DispatchQueue.main.async {
                isFocused = true
            }
        }
    }
    
    private var launcherBackground: some View {
        let cornerRadius: CGFloat = 24
        return ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(accentGradient.opacity(0.18))
                .blendMode(.overlay)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(accentGradient.opacity(0.55), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.18), radius: 22, x: 0, y: 10)
    }
    
    private var content: some View {
        VStack(spacing: 14) {
            headerView
            
            if let image = pendingImage {
                attachmentCard(image: image)
                    .transition(.opacity)
            }
            
            if let errorMessage = viewModel.errorMessage {
                errorBanner(errorMessage)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            inputField
            actionRow
            hintRow
        }
        .padding(22)
        .animation(.easeOut(duration: 0.2), value: viewModel.errorMessage)
    }
    
    private var headerView: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(accentGradient.opacity(0.2))
                    .frame(width: 34, height: 34)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(accentGradient)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("OpenCode ランチャー")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Text("ショートカットで素早く送信")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
                sessionBadge
            }
        }
    }
    
    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
            Text(message)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.86, green: 0.22, blue: 0.2),
                            Color(red: 0.95, green: 0.48, blue: 0.2)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
        )
    }
    
    private var inputField: some View {
        HStack(spacing: 10) {
            Image(systemName: "message.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(accentGradient)
            TextField("メッセージを入力...", text: $viewModel.inputMessage)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .onSubmit {
                    guard !trimmedInput.isEmpty || hasPendingImage else { return }
                    onSendMessage()
                }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.thinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
        )
    }
    
    private var actionRow: some View {
        HStack(spacing: 12) {
            Button(action: onCancel) {
                Label("キャンセル", systemImage: "xmark")
                    .frame(minWidth: 90)
            }
            .keyboardShortcut(.cancelAction)
            .buttonStyle(.bordered)
            
            Button(action: onSendMessage) {
                HStack(spacing: 6) {
                    if viewModel.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Image(systemName: "paperplane.fill")
                    Text("送信")
                }
                .frame(minWidth: 120)
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.18, green: 0.54, blue: 0.95))
            .disabled(isSendDisabled)
            
            Spacer()
            
            Button(action: {
                Task {
                    await viewModel.attachScreenshotForPrompt()
                }
            }) {
                Label("スクリーンショット", systemImage: "camera")
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isLoading)
        }
    }
    
    private var hintRow: some View {
        HStack {
            Text("Enterで送信 / Escで閉じる")
            Spacer()
            Text("Cmd+Shift+I")
        }
        .font(.system(size: 11, weight: .medium, design: .rounded))
        .foregroundColor(.secondary)
    }
    
    private func attachmentCard(image: NSImage) -> some View {
        HStack(spacing: 12) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 6) {
                Text("スクリーンショットを添付")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                Text("このまま送信できます")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                viewModel.clearPendingImage()
            }) {
                Text("削除")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
            .buttonStyle(.bordered)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.thinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
        )
    }
    
    private var sessionBadge: some View {
        let isActive = viewModel.currentSession != nil
        return HStack(spacing: 6) {
            Circle()
                .fill(isActive ? Color.green.opacity(0.9) : Color.orange.opacity(0.9))
                .frame(width: 6, height: 6)
            Text(isActive ? "セッション有効" : "セッション未作成")
        }
        .font(.system(size: 11, weight: .semibold, design: .rounded))
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
        )
    }
}
