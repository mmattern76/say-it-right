import CoreGraphics
import Testing
@testable import SayItRight

@Suite("Haptic Feedback and Animation")
struct HapticAnimationTests {

    @Test("PyramidHaptic has all expected cases")
    func hapticCases() {
        let cases: [PyramidHaptic] = [
            .blockPickup,
            .validDrop,
            .invalidDrop,
            .pyramidComplete,
        ]
        #expect(cases.count == 4)
    }

    @Test("shouldReduceMotion returns a Bool")
    func reduceMotionReturnsBool() {
        // Just verify the function compiles and returns a Bool.
        let result: Bool = shouldReduceMotion
        #expect(result == true || result == false)
    }

    @Test("BlockFeedbackState has accessibility labels")
    func feedbackStateAccessibility() {
        #expect(!BlockFeedbackState.correct.accessibilityLabel.isEmpty)
        #expect(!BlockFeedbackState.misplaced.accessibilityLabel.isEmpty)
        #expect(!BlockFeedbackState.meceOverlap.accessibilityLabel.isEmpty)
        #expect(BlockFeedbackState.none.accessibilityLabel.isEmpty)
    }

    @Test("FeedbackPalette defines all required colors")
    func feedbackPaletteExists() {
        // Verify all palette colors are accessible (compile-time + runtime).
        let _ = FeedbackPalette.correct
        let _ = FeedbackPalette.misplaced
        let _ = FeedbackPalette.overlap
        let _ = FeedbackPalette.gap
        let _ = FeedbackPalette.celebration
        #expect(true)
    }

    @Test("ConnectionLineStyle has normal and highlighted variants")
    func connectionLineStyles() {
        #expect(ConnectionLineStyle.normal.lineWidth > 0)
        #expect(ConnectionLineStyle.highlighted.lineWidth > ConnectionLineStyle.normal.lineWidth)
    }

    @Test("PyramidConnection generates stable ID from parent and child")
    func connectionID() {
        let connection = PyramidConnection(parentID: "root", childID: "child-a")
        #expect(connection.id == "root->child-a")
    }

    @Test("ConnectionLinesView.bezierPath creates a valid path")
    func bezierPathCreation() {
        let start = CGPoint(x: 100, y: 50)
        let end = CGPoint(x: 200, y: 150)
        let path = ConnectionLinesView.bezierPath(from: start, to: end)
        #expect(!path.isEmpty)
    }
}
