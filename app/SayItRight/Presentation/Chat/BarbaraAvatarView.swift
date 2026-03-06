import SwiftUI

/// Displays Barbara's illustrated avatar with mood-driven expression switching.
///
/// Two sizes are supported:
/// - `.thumbnail` (40pt) — for chat message bubbles
/// - `.header` (80pt) — for session screens and dashboard
///
/// Expression changes animate with a crossfade.
struct BarbaraAvatarView: View {
    let mood: BarbaraMood
    var size: AvatarSize = .thumbnail

    enum AvatarSize {
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
            .animation(.easeInOut(duration: 0.3), value: mood)
    }
}

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

#Preview("Header — Attentive") {
    BarbaraAvatarView(mood: .attentive, size: .header)
        .padding()
}
