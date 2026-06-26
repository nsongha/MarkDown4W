import SwiftUI
import AppKit

/// Sizes a freshly-opened document window to a comfortable portrait page that
/// is a bit wider than A4, so the centered reading column has clear margins on
/// both sides.
///
/// - On smaller displays the window is nearly full height.
/// - On large displays the height is capped, so the window never becomes
///   excessively tall — the aspect ratio then sets a comfortable width.
///
/// Runs exactly once per window (the first time the hosting view gains a
/// window), so it establishes the *default* size without fighting the user's
/// later manual resizes.
struct WindowConfigurator: NSViewRepresentable {
    /// Height : width aspect ratio. Wider than A4 (√2 ≈ 1.41) to leave clear
    /// side margins around the reading column.
    private static let aspectRatio: CGFloat = 1.12

    /// Fraction of the screen's usable height to occupy on small displays.
    private static let heightFraction: CGFloat = 0.90

    /// Upper bound on window height so large displays stay reasonable.
    private static let maxHeight: CGFloat = 1160

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async { [weak view] in
            guard let window = view?.window,
                  !context.coordinator.didConfigure else { return }
            context.coordinator.didConfigure = true
            Self.applyDefaultSize(to: window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var didConfigure = false
    }

    private static func applyDefaultSize(to window: NSWindow) {
        guard let screen = window.screen ?? NSScreen.main else { return }
        let visible = screen.visibleFrame

        // Pick a height: near-full on small screens, capped on large ones.
        let height = min(visible.height * heightFraction, maxHeight)
        // Width from the aspect ratio, clamped so it always fits the screen.
        let width = min((height / aspectRatio).rounded(), (visible.width * 0.9).rounded())

        window.setContentSize(NSSize(width: width, height: height))
        window.center()
    }
}
