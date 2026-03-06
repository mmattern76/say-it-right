import SwiftUI

/// Avatar options for learner profiles.
///
/// Maxi and Alex are sourced from the Think app's character artwork
/// and serve as default profile pictures in Say it right!
enum LearnerAvatar: String, CaseIterable, Codable, Sendable {
    case maxi
    case alex

    /// Asset catalog image name.
    var assetName: String {
        switch self {
        case .maxi: "avatar-maxi"
        case .alex: "avatar-alex"
        }
    }

    /// Localized display name.
    var displayName: String {
        switch self {
        case .maxi: "Maxi"
        case .alex: "Alex"
        }
    }
}

/// Displays a learner's avatar in the chat and profile UI.
struct LearnerAvatarView: View {
    let avatar: LearnerAvatar
    var size: CGFloat = 40

    var body: some View {
        Image(avatar.assetName)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: size, height: size)
            .clipShape(Circle())
    }
}

#Preview("Learner Avatars") {
    HStack(spacing: 20) {
        ForEach(LearnerAvatar.allCases, id: \.self) { avatar in
            VStack {
                LearnerAvatarView(avatar: avatar, size: 60)
                Text(avatar.displayName)
                    .font(.caption)
            }
        }
    }
    .padding()
}
