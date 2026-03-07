import SwiftUI

/// A zoomable, pannable canvas for the pyramid builder.
///
/// Wraps the pyramid tree content in a scroll view with pinch-to-zoom
/// and two-finger pan. Block drag gestures take priority over canvas gestures.
struct ZoomablePyramidCanvas<Content: View>: View {
    /// Current zoom scale.
    @Binding var scale: CGFloat
    /// Whether to auto-fit the content to fill available space.
    @Binding var shouldAutoFit: Bool
    /// The canvas content (tree nodes, connections, drop zones).
    @ViewBuilder let content: () -> Content

    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var canvasSize: CGSize = .zero

    /// Minimum and maximum zoom levels.
    private let minScale: CGFloat = 0.5
    private let maxScale: CGFloat = 2.5

    var body: some View {
        GeometryReader { geo in
            let magnification = MagnifyGesture()
                .onChanged { value in
                    let newScale = lastScale * value.magnification
                    scale = min(max(newScale, minScale), maxScale)
                }
                .onEnded { value in
                    lastScale = scale
                }

            let pan = DragGesture()
                .onChanged { value in
                    offset = CGSize(
                        width: lastOffset.width + value.translation.width,
                        height: lastOffset.height + value.translation.height
                    )
                }
                .onEnded { _ in
                    lastOffset = offset
                }

            content()
                .frame(
                    width: max(geo.size.width, 1200),
                    height: max(geo.size.height, 800)
                )
                .scaleEffect(scale)
                .offset(offset)
                .gesture(magnification)
                .simultaneousGesture(pan)
                .clipped()
                .onChange(of: shouldAutoFit) { _, fit in
                    if fit {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            scale = 1.0
                            lastScale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        }
                        shouldAutoFit = false
                    }
                }
                .onAppear {
                    canvasSize = geo.size
                }
        }
    }
}

/// Orientation-aware layout for the pyramid builder on iPad.
///
/// - Landscape: sidebar on right (30%), canvas on left (70%)
/// - Portrait: canvas full-width, Barbara panel as bottom sheet
struct AdaptivePyramidLayout<Canvas: View, Sidebar: View>: View {
    @ViewBuilder let canvas: () -> Canvas
    @ViewBuilder let sidebar: () -> Sidebar

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    /// True when the device is in landscape (or on Mac).
    private var isLandscape: Bool {
        #if os(macOS)
        true
        #else
        verticalSizeClass == .compact || (horizontalSizeClass == .regular && verticalSizeClass == .regular)
        #endif
    }

    var body: some View {
        #if os(macOS)
        landscapeLayout
        #else
        if horizontalSizeClass == .regular {
            GeometryReader { geo in
                if geo.size.width > geo.size.height {
                    landscapeLayout
                } else {
                    portraitLayout
                }
            }
        } else {
            compactLayout
        }
        #endif
    }

    /// Landscape: canvas left (70%), sidebar right (30%).
    private var landscapeLayout: some View {
        HStack(spacing: 0) {
            canvas()
                .frame(maxWidth: .infinity)

            Divider()

            sidebar()
                .frame(width: 320)
        }
    }

    /// Portrait iPad: canvas full-width, sidebar as bottom panel.
    private var portraitLayout: some View {
        VStack(spacing: 0) {
            canvas()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            sidebar()
                .frame(maxHeight: 280)
        }
    }

    /// Compact (iPhone): canvas above, sidebar below.
    private var compactLayout: some View {
        VStack(spacing: 0) {
            canvas()

            Divider()

            sidebar()
                .frame(maxHeight: 200)
        }
    }
}

// MARK: - Previews

#Preview("Zoomable Canvas") {
    ZoomableCanvasPreview()
}

private struct ZoomableCanvasPreview: View {
    @State private var scale: CGFloat = 1.0
    @State private var shouldAutoFit = false

    var body: some View {
        VStack {
            ZoomablePyramidCanvas(scale: $scale, shouldAutoFit: $shouldAutoFit) {
                ZStack {
                    Color(white: 0.95)
                    VStack(spacing: 20) {
                        ForEach(0..<5) { i in
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.blue.opacity(0.5))
                                .frame(width: 200, height: 60)
                                .overlay(Text("Block \(i)").foregroundStyle(.white))
                        }
                    }
                }
            }

            HStack {
                Text("Scale: \(scale, specifier: "%.1f")")
                Button("Auto Fit") { shouldAutoFit = true }
            }
            .padding()
        }
    }
}

#Preview("Adaptive Layout — Landscape") {
    AdaptivePyramidLayout {
        Color.blue.opacity(0.2)
            .overlay(Text("Canvas"))
    } sidebar: {
        Color.green.opacity(0.2)
            .overlay(Text("Sidebar"))
    }
    .frame(width: 1024, height: 768)
}
