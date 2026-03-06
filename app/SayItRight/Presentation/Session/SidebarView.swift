import SwiftUI

/// Session type descriptor for the sidebar picker.
struct SessionTypeItem: Identifiable, Hashable, Sendable {
    let id: String
    let titleEN: String
    let titleDE: String
    let subtitle: String
    let icon: String

    /// Display title based on current language setting.
    func title(language: String) -> String {
        language == "de" ? titleDE : titleEN
    }
}

/// Predefined session types available in the sidebar.
extension SessionTypeItem {
    static let allTypes: [SessionTypeItem] = [
        SessionTypeItem(
            id: "say-it-clearly",
            titleEN: "Say it clearly",
            titleDE: "Sag's klar",
            subtitle: "Quick structured response drill",
            icon: "text.bubble"
        ),
        SessionTypeItem(
            id: "find-the-point",
            titleEN: "Find the point",
            titleDE: "Finde den Punkt",
            subtitle: "Extract governing thought",
            icon: "scope"
        ),
        SessionTypeItem(
            id: "fix-this-mess",
            titleEN: "Fix this mess",
            titleDE: "Raum das auf",
            subtitle: "Restructure a bad argument",
            icon: "arrow.triangle.2.circlepath"
        ),
        SessionTypeItem(
            id: "build-the-pyramid",
            titleEN: "Build the pyramid",
            titleDE: "Bau die Pyramide",
            subtitle: "Visual tree construction",
            icon: "triangle"
        ),
        SessionTypeItem(
            id: "elevator-pitch",
            titleEN: "The elevator pitch",
            titleDE: "30 Sekunden",
            subtitle: "Timed spoken drill",
            icon: "timer"
        ),
        SessionTypeItem(
            id: "spot-the-gap",
            titleEN: "Spot the gap",
            titleDE: "Finde die Lucke",
            subtitle: "Find structural weakness",
            icon: "magnifyingglass"
        ),
        SessionTypeItem(
            id: "decode-and-rebuild",
            titleEN: "Decode and rebuild",
            titleDE: "Entschlusseln und Neubauen",
            subtitle: "Full-cycle read + restructure",
            icon: "arrow.2.squarepath"
        ),
    ]
}

/// Sidebar for the iPad layout showing session type picker,
/// Barbara's status, and a settings access point.
///
/// Designed for `NavigationSplitView` sidebar column on iPad.
/// On iPhone this view is not used — the compact layout goes
/// directly to `ChatView`.
struct SidebarView: View {
    @Binding var selectedSessionType: SessionTypeItem?
    var language: String = "en"
    var onSettingsTapped: () -> Void = {}

    var body: some View {
        List(selection: $selectedSessionType) {
            barbaraStatusSection
            sessionTypeSection
            settingsSection
        }
        .listStyle(.sidebar)
        .navigationTitle(language == "de" ? "Sag's richtig!" : "Say it right!")
    }

    // MARK: - Barbara Status

    private var barbaraStatusSection: some View {
        Section {
            HStack(spacing: 12) {
                BarbaraAvatarView(mood: .attentive, size: .header)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Barbara")
                        .font(.headline)

                    Text(language == "de"
                         ? "Bereit loszulegen."
                         : "Ready when you are.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Session Types

    private var sessionTypeSection: some View {
        Section(language == "de" ? "Ubungstypen" : "Session Types") {
            ForEach(SessionTypeItem.allTypes) { sessionType in
                sessionTypeRow(sessionType)
                    .tag(sessionType)
            }
        }
    }

    private func sessionTypeRow(_ item: SessionTypeItem) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title(language: language))
                    .font(.body)

                Text(item.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: item.icon)
                .foregroundStyle(Color.accentColor)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Settings

    private var settingsSection: some View {
        Section {
            Button(action: onSettingsTapped) {
                Label(
                    language == "de" ? "Einstellungen" : "Settings",
                    systemImage: "gearshape"
                )
            }
        }
    }
}

// MARK: - Previews

#Preview("Sidebar — English") {
    NavigationSplitView {
        SidebarView(
            selectedSessionType: .constant(SessionTypeItem.allTypes.first),
            language: "en"
        )
    } detail: {
        Text("Detail area")
    }
}

#Preview("Sidebar — German") {
    NavigationSplitView {
        SidebarView(
            selectedSessionType: .constant(nil),
            language: "de"
        )
    } detail: {
        Text("Detail area")
    }
}

#Preview("Sidebar — Dark Mode") {
    NavigationSplitView {
        SidebarView(
            selectedSessionType: .constant(SessionTypeItem.allTypes[1]),
            language: "en"
        )
    } detail: {
        Text("Detail area")
    }
    .preferredColorScheme(.dark)
}
