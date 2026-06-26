import SwiftUI
import AppKit

/// Sizes a freshly-opened document window to a single portrait page with an
/// A4 aspect ratio (height : width = √2 : 1).
///
/// - On smaller displays the window is nearly full height.
/// - On large displays the height is capped, so the window never becomes
///   excessively tall — the A4 ratio then sets a comfortable width.
///
/// Runs exactly once per window (the first time the hosting view gains a
/// window), so it establishes the *default* size without fighting the user's
/// later manual resizes.
struct WindowConfigurator: NSViewRepresentable {
    /// A4 portrait aspect ratio (297mm / 210mm).
    private static let a4Ratio: CGFloat = 1.4142

    /// Fraction of the screen's usable height to occupy on small displays.
    private static let heightFraction: CGFloat = 0.92

    /// Upper bound on window height so large displays stay reasonable.
    private static let maxHeight: CGFloat = 1120

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async { [weak view] in
            guard let window = view?.window,
                  !context.coordinator.didConfigure else { return }
            context.coordinator.didConfigure = true
            Self.applyA4Size(to: window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var didConfigure = false
    }

    private static func applyA4Size(to window: NSWindow) {
        guard let screen = window.screen ?? NSScreen.main else { return }
        let visible = screen.visibleFrame

        // Pick a height: near-full on small screens, capped on large ones.
        var height = min(visible.height * heightFraction, maxHeight)
        var width = (height / a4Ratio).rounded()

        // In the unlikely case the A4 width exceeds the screen, clamp width
        // and recompute height to preserve the ratio.
        let maxWidth = visible.width * 0.9
        if width > maxWidth {
            width = maxWidth.rounded()
            height = min(height, (width * a4Ratio).rounded())
        }

        window.setContentSize(NSSize(width: width, height: height))
        window.center()
    }
}
