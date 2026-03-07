import SwiftUI

// MARK: - Haptic Feedback Manager

/// Centralized haptic feedback for pyramid builder interactions.
///
/// Provides platform-aware haptic feedback using `sensoryFeedback()` modifiers
/// on iOS 17+ and guards against Mac (no haptic hardware).
/// All haptics are silenced when `UIAccessibility.isReduceMotionEnabled` is true.
enum PyramidHaptic: Sendable {
    /// Light tap when picking up a block.
    case blockPickup
    /// Medium impact when a block snaps into a valid drop zone.
    case validDrop
    /// Error notification when a block is returned to pool.
    case invalidDrop
    /// Success notification when the entire pyramid is correct.
    case pyramidComplete
}

// MARK: - Haptic Modifier

/// View modifier that triggers sensory feedback for pyramid interactions.
///
/// Uses the iOS 17+ `sensoryFeedback()` API. On macOS this is a no-op.
struct PyramidHapticModifier: ViewModifier {
    let trigger: PyramidHaptic?
    @State private var hapticTrigger: Int = 0

    func body(content: Content) -> some View {
        content
            #if os(iOS)
            .sensoryFeedback(feedback, trigger: hapticTrigger)
            #endif
            .onChange(of: trigger) { _, newValue in
                guard newValue != nil else { return }
                #if os(iOS)
                if !UIAccessibility.isReduceMotionEnabled {
                    hapticTrigger += 1
                }
                #endif
            }
    }

    #if os(iOS)
    private var feedback: SensoryFeedback {
        switch trigger {
        case .blockPickup: .impact(flexibility: .soft, intensity: 0.5)
        case .validDrop: .impact(flexibility: .rigid, intensity: 0.7)
        case .invalidDrop: .error
        case .pyramidComplete: .success
        case .none: .impact(flexibility: .soft, intensity: 0.0)
        }
    }
    #endif
}

// MARK: - Reduce Motion Helper

/// Whether animations should be simplified for accessibility.
///
/// Checks `UIAccessibility.isReduceMotionEnabled` on iOS,
/// `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion` on macOS.
var shouldReduceMotion: Bool {
    #if os(iOS)
    UIAccessibility.isReduceMotionEnabled
    #elseif os(macOS)
    NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    #else
    false
    #endif
}

// MARK: - View Extension

extension View {
    /// Attach a pyramid haptic trigger to this view.
    func pyramidHaptic(_ haptic: PyramidHaptic?) -> some View {
        modifier(PyramidHapticModifier(trigger: haptic))
    }
}
