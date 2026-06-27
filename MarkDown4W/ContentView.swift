import SwiftUI

/// The main document view: a full-window markdown renderer, a native toolbar
/// (single gear button), and an overlay find bar.
struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.controlActiveState) private var controlActiveState

    /// The document being viewed (read-only).
    let document: MarkdownDocument
    /// The document's file URL (for the centered title); nil if unsaved.
    var fileURL: URL? = nil

    /// Filename without extension, shown centered in the title bar.
    private var title: String {
        fileURL?.deletingPathExtension().lastPathComponent ?? "MarkDown4W"
    }

    /// Bridge to drive the web view's native find from the find bar.
    @StateObject private var webProxy = WebViewProxy()

    @State private var showFind = false

    /// The chosen shade ("light"/"sepia"/"dark"); "auto" resolves to light/dark
    /// against the live system appearance.
    private var resolvedTheme: String {
        settings.resolvedTheme(systemIsDark: colorScheme == .dark)
    }

    var body: some View {
        MarkdownWebView(markdown: document.text,
                        bodyFont: settings.bodyFont,
                        fontSizePx: settings.fontSizePx,
                        theme: resolvedTheme,
                        proxy: webProxy)
            .ignoresSafeArea()
            // Find bar lives in the top safe-area inset, so toggling it pushes
            // the content without the full-window relayout that caused flicker.
            .safeAreaInset(edge: .top, spacing: 0) {
                if showFind {
                    FindBar(proxy: webProxy, isPresented: $showFind)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: showFind)
            .background(WindowConfigurator(resolvedTheme: resolvedTheme))
            .toolbar {
                MarkdownToolbar(title: title)
            }
        .onReceive(NotificationCenter.default.publisher(for: .mdShowFind)) { _ in
            // Only the active (key) window/tab should reveal its find bar.
            guard controlActiveState == .key else { return }
            showFind = true
        }
    }
}
