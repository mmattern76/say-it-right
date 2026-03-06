import Testing
import Foundation
@testable import SayItRight

@Suite("BarbaraMood")
struct BarbaraMoodTests {

    @Test func allCasesCount() {
        #expect(BarbaraMood.allCases.count == 8)
    }

    @Test func assetNameMapping() {
        let expected: [(BarbaraMood, String)] = [
            (.attentive, "barbara-attentive"),
            (.skeptical, "barbara-raised-eyebrow"),
            (.approving, "barbara-nodding"),
            (.waiting, "barbara-crossed-arms"),
            (.proud, "barbara-warm-smile"),
            (.evaluating, "barbara-thinking"),
            (.teaching, "barbara-explaining"),
            (.disappointed, "barbara-disappointed"),
        ]
        for (mood, asset) in expected {
            #expect(mood.assetName == asset, "Expected \(mood) to map to \(asset)")
        }
    }

    @Test func rawValueRoundTrip() {
        for mood in BarbaraMood.allCases {
            let decoded = BarbaraMood(rawValue: mood.rawValue)
            #expect(decoded == mood)
        }
    }

    @Test func codableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for mood in BarbaraMood.allCases {
            let data = try encoder.encode(mood)
            let decoded = try decoder.decode(BarbaraMood.self, from: data)
            #expect(decoded == mood)
        }
    }

    @Test func accessibilityLabelsAreNonEmpty() {
        for mood in BarbaraMood.allCases {
            #expect(!mood.accessibilityLabel.isEmpty, "\(mood) should have a non-empty accessibility label")
        }
    }

    @Test func decodingFromMetadataJSON() throws {
        // Simulates what ResponseParser does: mood field in BARBARA_META JSON
        let json = """
        {"scores":{"clarity":3},"totalScore":3,"mood":"skeptical","progressionSignal":"none","revisionRound":1,"sessionPhase":"evaluation","feedbackFocus":"test","language":"en"}
        """
        let data = json.data(using: .utf8)!
        let metadata = try JSONDecoder().decode(BarbaraMetadata.self, from: data)
        #expect(metadata.mood == .skeptical)
        #expect(metadata.mood.assetName == "barbara-raised-eyebrow")
    }

    @Test func uniqueAssetNames() {
        let assetNames = BarbaraMood.allCases.map(\.assetName)
        let uniqueNames = Set(assetNames)
        #expect(uniqueNames.count == assetNames.count, "Each mood must map to a unique asset")
    }
}

@Suite("BarbaraAvatarView")
struct BarbaraAvatarViewTests {

    @Test func thumbnailSize() {
        let size = BarbaraAvatarView.AvatarSize.thumbnail
        #expect(size.points == 40)
    }

    @Test func headerSize() {
        let size = BarbaraAvatarView.AvatarSize.header
        #expect(size.points == 80)
    }

    @Test @MainActor func moodDrivesAvatar() {
        // Verify the view accepts all moods without crashing
        for mood in BarbaraMood.allCases {
            let view = BarbaraAvatarView(mood: mood, size: .thumbnail)
            #expect(view.mood == mood)
        }
    }

    @Test @MainActor func headerVariant() {
        let view = BarbaraAvatarView(mood: .proud, size: .header)
        #expect(view.size.points == 80)
        #expect(view.mood == .proud)
    }

    @Test @MainActor func defaultSizeIsThumbnail() {
        let view = BarbaraAvatarView(mood: .attentive)
        #expect(view.size.points == 40)
    }
}
