import SwiftUI

/// Displays collected debug log entries. Accessible from parent settings only.
struct DebugLogView: View {
    @State private var entries: [DebugLogger.Entry] = []
    @State private var isLoading = true
    @State private var showShareSheet = false
    @State private var showClearConfirm = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading logs...")
            } else if entries.isEmpty {
                ContentUnavailableView(
                    "No Debug Data",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Enable debug mode and use the app to collect diagnostic data.")
                )
            } else {
                logList
            }
        }
        .navigationTitle("Debug Log")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if !entries.isEmpty {
                    Button {
                        showClearConfirm = true
                    } label: {
                        Image(systemName: "trash")
                    }

                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .task { await loadEntries() }
        .confirmationDialog("Clear all debug data?", isPresented: $showClearConfirm) {
            Button("Clear", role: .destructive) {
                Task {
                    try? await DebugLogger.shared.clearLogs()
                    entries = []
                }
            }
        }
    }

    // MARK: - Log List

    private var logList: some View {
        List(entries.indices, id: \.self) { index in
            let entry = entries[index]
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    kindBadge(entry.kind)
                    Spacer()
                    Text(entry.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                ForEach(entry.data.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    HStack {
                        Text(key)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(value)
                            .font(.caption)
                            .lineLimit(2)
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - Badge

    private func kindBadge(_ kind: DebugLogger.EntryKind) -> some View {
        Text(kind.rawValue)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(badgeColor(kind).opacity(0.15))
            .foregroundStyle(badgeColor(kind))
            .clipShape(Capsule())
    }

    private func badgeColor(_ kind: DebugLogger.EntryKind) -> Color {
        switch kind {
        case .apiRequest:       .blue
        case .apiResponse:      .green
        case .apiError:         .red
        case .metadataParsed:   .purple
        case .sessionEvent:     .orange
        case .evaluationResult: .teal
        case .configChange:     .gray
        }
    }

    // MARK: - Data Loading

    private func loadEntries() async {
        do {
            let loaded = try await DebugLogger.shared.entries()
            entries = loaded.reversed() // newest first
        } catch {
            entries = []
        }
        isLoading = false
    }

    private var shareText: String {
        entries.map { entry in
            let data = entry.data.map { "\($0.key)=\($0.value)" }.joined(separator: " ")
            return "[\(entry.timestamp)] \(entry.kind.rawValue) \(data)"
        }.joined(separator: "\n")
    }
}

#Preview {
    NavigationStack {
        DebugLogView()
    }
}
