import SwiftUI

/// Maps Barbara's hidden metadata mood tags to avatar expression assets.
///
/// The `mood` field in `BARBARA_META` JSON drives which expression is shown.
/// See `docs/midjourney-prompts.md` → Expression → Mood Mapping table.
enum BarbaraMood: String, CaseIterable, Codable, Sendable {
    case attentive
    case skeptical
    case approving
    case waiting
    case proud
    case evaluating
    case teaching
    case disappointed

    /// Asset catalog image name for this mood's expression.
    var assetName: String {
        switch self {
        case .attentive:    "barbara-attentive"
        case .skeptical:    "barbara-raised-eyebrow"
        case .approving:    "barbara-nodding"
        case .waiting:      "barbara-crossed-arms"
        case .proud:        "barbara-warm-smile"
        case .evaluating:   "barbara-thinking"
        case .teaching:     "barbara-explaining"
        case .disappointed: "barbara-disappointed"
        }
    }

    /// Human-readable description for VoiceOver.
    var accessibilityLabel: String {
        switch self {
        case .attentive:     "listening"
        case .skeptical:     "raising an eyebrow"
        case .approving:     "nodding approvingly"
        case .waiting:       "arms crossed, waiting"
        case .proud:         "smiling warmly"
        case .evaluating:    "thinking"
        case .teaching:      "explaining"
        case .disappointed:  "looking disappointed"
        }
    }
}
