import SwiftUI

/// Displays Barbara's illustrated avatar with mood-driven expression switching.
///
/// Two sizes are supported:
/// - `.thumbnail` (40pt) — for chat message bubbles
/// - `.header` (80pt) — for session screens and dashboard
///
/// Expression changes animate with a 0.3s crossfade driven by the `mood` value.
/// The mood is sourced from `BarbaraMetadata.mood`, extracted by `ResponseParser`.
struct BarbaraAvatarView: View {
    let mood: BarbaraMood
    var size: AvatarSize = .thumbnail

    enum AvatarSize: Sendable {
        case thumbnail
        case header

        var points: CGFloat {
            switch self {
            case .thumbnail: 40
            case .header: 80
            }
        }
    }

    var body: some View {
        Image(mood.assetName)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: size.points, height: size.points)
            .clipShape(Circle())
            .id(mood)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: mood)
            .accessibilityLabel("Barbara — \(mood.accessibilityLabel)")
    }
}

// MARK: - Previews

#Preview("Thumbnail — All Moods") {
    HStack(spacing: 12) {
        ForEach(BarbaraMood.allCases, id: \.self) { mood in
            VStack {
                BarbaraAvatarView(mood: mood, size: .thumbnail)
                Text(mood.rawValue)
                    .font(.caption2)
            }
        }
    }
    .padding()
}

#Preview("Header — All Moods") {
    LazyVGrid(columns: [
        GridItem(.adaptive(minimum: 100))
    ], spacing: 16) {
        ForEach(BarbaraMood.allCases, id: \.self) { mood in
            VStack(spacing: 8) {
                BarbaraAvatarView(mood: mood, size: .header)
                Text(mood.rawValue)
                    .font(.caption)
            }
        }
    }
    .padding()
}

#Preview("Mood Transition") {
    BarbaraAvatarMoodTransitionPreview()
}

/// Interactive preview demonstrating crossfade transitions between moods.
private struct BarbaraAvatarMoodTransitionPreview: View {
    @State private var currentMoodIndex = 0

    private var currentMood: BarbaraMood {
        BarbaraMood.allCases[currentMoodIndex]
    }

    var body: some View {
        VStack(spacing: 24) {
            BarbaraAvatarView(mood: currentMood, size: .header)

            Text(currentMood.rawValue)
                .font(.headline)

            Button("Next Mood") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentMoodIndex = (currentMoodIndex + 1) % BarbaraMood.allCases.count
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
