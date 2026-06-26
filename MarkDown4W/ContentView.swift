import SwiftUI

/// The main document view: a full-window markdown renderer plus a native
/// toolbar of display controls.
struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.colorScheme) private var colorScheme

    /// The document being viewed (read-only).
    let document: MarkdownDocument

    /// "auto" theme is resolved here, against the live system appearance, so
    /// the renderer always receives a concrete "light"/"dark" value.
    private var resolvedTheme: String {
        settings.resolvedTheme(systemIsDark: colorScheme == .dark)
    }

    var body: some View {
        MarkdownWebView(markdown: document.text,
                        bodyFont: settings.bodyFont,
                        fontSizePx: settings.fontSizePx,
                        theme: resolvedTheme)
            .ignoresSafeArea()
            .background(WindowConfigurator())
            .toolbar {
                MarkdownToolbar()
            }
    }
}
