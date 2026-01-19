import SwiftUI

struct LogViewerView: View {
    @ObservedObject var logStore: RuntimeLogStore
    @Binding var autoScroll: Bool
    
    var body: some View {
        logsView
    }
    
    private var logsView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(logStore.entries) { entry in
                        logRow(entry)
                            .id(entry.id)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onChange(of: logStore.entries.count) { _, _ in
                guard autoScroll, let last = logStore.entries.last else { return }
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }
    
    private func logRow(_ entry: RuntimeLogEntry) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(entry.formattedTimestamp)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 130, alignment: .leading)
            
            Text(entry.level.rawValue)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(color(for: entry.level))
                .frame(width: 50, alignment: .leading)
            
            Text("[\(entry.category)]")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
            
            Text(entry.message)
                .font(.system(size: 12, design: .monospaced))
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func color(for level: RuntimeLogLevel) -> Color {
        switch level {
        case .info:
            return .primary
        case .warning:
            return .orange
        case .error:
            return .red
        }
    }
}
