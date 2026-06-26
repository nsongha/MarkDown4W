import SwiftUI
import WebKit
import AppKit

/// Hosts the bundled HTML renderer (`Renderer/index.html`) in a `WKWebView`
/// and drives it via JavaScript.
///
/// The page exposes:
///   window.renderMarkdownB64(b64)  // b64 = base64 of UTF-8 markdown
///   window.applySettings({ bodyFont, codeFont, fontSizePx, theme })
///
/// Rendering is always ordered: render markdown first, then apply settings.
struct MarkdownWebView: NSViewRepresentable {

    /// Raw markdown source to display.
    let markdown: String
    /// Body font identifier ("system" | "newyork" | "georgia" | "helvetica").
    let bodyFont: String
    /// Body font size in px.
    let fontSizePx: Int
    /// Concrete theme — already resolved to "light" or "dark" by the caller.
    let theme: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.suppressesIncrementalRendering = false

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = false

        // Reduce overscroll "bounce" so the document scrolls like a native view.
        if let scrollView = webView.enclosingScrollView {
            scrollView.verticalScrollElasticity = .none
            scrollView.horizontalScrollElasticity = .none
        }

        loadRenderer(into: webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let coordinator = context.coordinator
        // The page may not be ready yet; the navigation delegate performs the
        // initial push on didFinish using the latest values it reads back.
        coordinator.latestMarkdown = markdown
        coordinator.latestBodyFont = bodyFont
        coordinator.latestFontSizePx = fontSizePx
        coordinator.latestTheme = theme

        guard coordinator.isLoaded else { return }

        // Only re-render markdown if it actually changed (avoids reflow churn).
        if coordinator.lastPushedMarkdown != markdown {
            coordinator.lastPushedMarkdown = markdown
            Self.renderMarkdown(markdown, in: webView)
        }
        // Settings are cheap to re-apply and idempotent; always push.
        Self.applySettings(bodyFont: bodyFont,
                           fontSizePx: fontSizePx,
                           theme: theme,
                           in: webView)
    }

    // MARK: Loading

    private func loadRenderer(into webView: WKWebView) {
        guard let url = Bundle.main.url(forResource: "index",
                                        withExtension: "html",
                                        subdirectory: "Renderer") else {
            assertionFailure("Renderer/index.html missing from app bundle")
            return
        }
        let directory = url.deletingLastPathComponent()
        webView.loadFileURL(url, allowingReadAccessTo: directory)
    }

    // MARK: JavaScript bridge

    /// Render markdown by passing a base64-encoded UTF-8 payload. Base64 is
    /// safe to embed directly inside a JS single-quoted string.
    private static func renderMarkdown(_ markdown: String, in webView: WKWebView) {
        let b64 = Data(markdown.utf8).base64EncodedString()
        let js = "window.renderMarkdownB64('\(b64)');"
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    /// Apply display settings. The settings object is built via
    /// `JSONSerialization` so values are escaped correctly.
    private static func applySettings(bodyFont: String,
                                      fontSizePx: Int,
                                      theme: String,
                                      in webView: WKWebView) {
        let settings: [String: Any] = [
            "bodyFont": bodyFont,
            "codeFont": "sfmono",
            "fontSizePx": fontSizePx,
            "theme": theme,
        ]

        let json: String
        if let data = try? JSONSerialization.data(withJSONObject: settings),
           let string = String(data: data, encoding: .utf8) {
            json = string
        } else {
            // Fallback — values are constrained, so this is a safe literal.
            json = "{\"bodyFont\":\"system\",\"codeFont\":\"sfmono\",\"fontSizePx\":17,\"theme\":\"light\"}"
        }

        let js = "window.applySettings(\(json));"
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    // MARK: Coordinator

    final class Coordinator: NSObject, WKNavigationDelegate {
        /// True once the page has finished its initial load.
        var isLoaded = false
        /// Last markdown actually pushed to the page (change-detection).
        var lastPushedMarkdown: String?

        // Latest values from SwiftUI, used for the initial post-load push.
        var latestMarkdown: String = ""
        var latestBodyFont: String = "system"
        var latestFontSizePx: Int = 17
        var latestTheme: String = "light"

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoaded = true
            // Initial push — render first, then settings (ordered).
            lastPushedMarkdown = latestMarkdown
            MarkdownWebView.renderMarkdown(latestMarkdown, in: webView)
            MarkdownWebView.applySettings(bodyFont: latestBodyFont,
                                          fontSizePx: latestFontSizePx,
                                          theme: latestTheme,
                                          in: webView)
        }

        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Open clicked web links in the user's default browser instead of
            // navigating the embedded renderer away from the document.
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url,
               let scheme = url.scheme?.lowercased(),
               scheme == "http" || scheme == "https" {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            // Allow the initial file load and in-page "#anchor" scrolls.
            decisionHandler(.allow)
        }
    }
}
