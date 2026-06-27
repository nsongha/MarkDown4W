import SwiftUI

/// The main document view: a full-window markdown renderer, a native toolbar
/// (single gear button), and an overlay find bar.
struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.controlActiveState) private var controlActiveState

    /// The document being viewed (read-only).
    let document: MarkdownDocument

    /// Bridge to drive the web view's native find from the find bar.
    @StateObject private var webProxy = WebViewProxy()

    @State private var showFind = false

    /// The chosen shade ("light"/"sepia"/"dark"); "auto" resolves to light/dark
    /// against the live system appearance.
    private var resolvedTheme: String {
        settings.resolvedTheme(systemIsDark: colorScheme == .dark)
    }

    /// The title-bar background per shade (matches the renderer's `--bg`), so the
    /// toolbar takes on each theme's color and SwiftUI cross-fades it on change.
    private var titlebarColor: Color {
        switch resolvedTheme {
        case "dark":  return Color(red: 0x1e/255, green: 0x1e/255, blue: 0x1e/255)
        case "sepia": return Color(red: 0xf4/255, green: 0xec/255, blue: 0xd8/255)
        default:      return Color(red: 0xfa/255, green: 0xf9/255, blue: 0xf7/255)
        }
    }

    var body: some View {
        MarkdownWebView(markdown: document.text,
                        bodyFont: settings.bodyFont,
                        fontSizePx: settings.fontSizePx,
                        theme: resolvedTheme,
                        proxy: webProxy)
            // Respect the top safe area so content sits below the (opaque,
            // themed) toolbar; extend to the other edges.
            .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
            // Find bar lives in the top safe-area inset, so toggling it pushes
            // the content without the full-window relayout that caused flicker.
            .safeAreaInset(edge: .top, spacing: 0) {
                if showFind {
                    FindBar(proxy: webProxy, isPresented: $showFind,
                            barColor: titlebarColor, isDark: resolvedTheme == "dark")
                }
            }
            .background(WindowConfigurator(resolvedTheme: resolvedTheme))
            .toolbar {
                MarkdownToolbar()
            }
            // Themed, opaque toolbar background that SwiftUI cross-fades when the
            // shade changes — so the title bar matches each theme without snapping.
            .toolbarBackground(titlebarColor, for: .windowToolbar)
            .toolbarBackground(.visible, for: .windowToolbar)
            // Drive the whole window's appearance from the chosen shade (not the
            // system), so the system title text + gear render dark on light/sepia
            // and light on dark.
            .preferredColorScheme(resolvedTheme == "dark" ? .dark : .light)
            .animation(.easeInOut(duration: 0.6), value: resolvedTheme)
        .onReceive(NotificationCenter.default.publisher(for: .mdShowFind)) { _ in
            // Only the active (key) window/tab should reveal its find bar.
            guard controlActiveState == .key else { return }
            showFind = true
        }
    }
}
