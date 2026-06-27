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

    /// Shared identifier so newly opened documents tab into the same window.
    static let tabbingIdentifier = "net.songha.MarkDown4W.document"

    /// Resolved shade ("light"/"sepia"/"dark") — drives the titlebar appearance
    /// so the window header darkens with the Dark theme.
    var resolvedTheme: String = "light"

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        let theme = resolvedTheme
        DispatchQueue.main.async { [weak view] in
            guard let window = view?.window else { return }
            Self.configure(window, coordinator: context.coordinator)
            Self.applyAppearance(theme, to: window, coordinator: context.coordinator)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        let theme = resolvedTheme
        // Only react when the shade actually changed (avoids re-setting the
        // window appearance on unrelated SwiftUI updates, which caused flicker).
        guard theme != context.coordinator.appliedAppearance else { return }
        // Apply synchronously when the window is available so the titlebar
        // switches in the same frame the content begins its fade (no lag→snap).
        if let window = nsView.window {
            Self.applyAppearance(theme, to: window, coordinator: context.coordinator)
        } else {
            DispatchQueue.main.async { [weak nsView] in
                guard let window = nsView?.window else { return }
                Self.applyAppearance(theme, to: window, coordinator: context.coordinator)
            }
        }
    }

    /// Match the window chrome (titlebar/toolbar) to the chosen shade: dark for
    /// the Dark theme, light otherwise (light/sepia are light backgrounds).
    private static func applyAppearance(_ theme: String, to window: NSWindow, coordinator: Coordinator) {
        guard theme != coordinator.appliedAppearance else { return }
        coordinator.appliedAppearance = theme
        let name: NSAppearance.Name = (theme == "dark") ? .darkAqua : .aqua
        window.appearance = NSAppearance(named: name)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var didConfigure = false
        var appliedAppearance: String?
    }

    private static func configure(_ window: NSWindow, coordinator: Coordinator) {
        guard !coordinator.didConfigure else { return }
        coordinator.didConfigure = true

        window.tabbingIdentifier = tabbingIdentifier
        window.tabbingMode = .preferred

        // Unified title bar; the centered filename is drawn by a principal
        // toolbar item, so hide the default (leading) titlebar text. The window
        // title is still set, so tab labels remain correct.
        window.toolbarStyle = .unified
        window.titleVisibility = .hidden

        // SwiftUI's DocumentGroup opens each document as its own window and sets
        // tabbingMode too late to auto-tab, so attach explicitly: if another
        // document window already exists, add this one as a tab to it. Otherwise
        // it's the first window — give it the default size.
        if let host = NSApp.windows.first(where: { other in
            other !== window
                && other.tabbingIdentifier == tabbingIdentifier
                && other.isVisible
        }) {
            host.addTabbedWindow(window, ordered: .above)
            window.makeKeyAndOrderFront(nil)
        } else {
            applyDefaultSize(to: window)
        }
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
