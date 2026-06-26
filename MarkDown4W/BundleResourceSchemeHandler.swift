import WebKit
import UniformTypeIdentifiers

/// Serves the bundled `Renderer/` web assets to the `WKWebView` through a custom
/// URL scheme instead of `file://`.
///
/// Under App Sandbox, handing a `file://` URL to a `WKWebView` requires granting
/// the separate web-content process a sandbox extension, which is unreliable for
/// bundle resources. Reading the app's *own* bundle from the main process is
/// always permitted, so this handler reads each requested file and feeds the
/// bytes to the web view — making local rendering work correctly inside the
/// sandbox.
final class BundleResourceSchemeHandler: NSObject, WKURLSchemeHandler {

    /// Custom scheme (must not be a built-in like http/file/about).
    static let scheme = "markdown4w"
    /// Base URL the renderer is loaded from: `markdown4w://app/`.
    static let baseURL = "\(scheme)://app/"

    /// Absolute URL of the bundled `Renderer` directory.
    private let rootDirectory: URL

    override init() {
        // `Renderer` is bundled as a folder reference under Resources.
        if let index = Bundle.main.url(forResource: "index",
                                       withExtension: "html",
                                       subdirectory: "Renderer") {
            rootDirectory = index.deletingLastPathComponent().standardizedFileURL
        } else {
            rootDirectory = (Bundle.main.resourceURL ?? URL(fileURLWithPath: "/"))
                .appendingPathComponent("Renderer").standardizedFileURL
        }
        super.init()
    }

    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let url = task.request.url else {
            task.didFailWithError(Self.error("Missing URL"))
            return
        }

        // Map the request path onto a file inside the Renderer directory.
        var path = url.path
        if path.isEmpty || path == "/" { path = "/index.html" }
        let relative = String(path.drop(while: { $0 == "/" }))
        let fileURL = rootDirectory.appendingPathComponent(relative).standardizedFileURL

        // Guard against path traversal outside the Renderer directory.
        guard fileURL.path == rootDirectory.path
                || fileURL.path.hasPrefix(rootDirectory.path + "/") else {
            task.didFailWithError(Self.error("Forbidden path: \(relative)"))
            return
        }

        guard let data = try? Data(contentsOf: fileURL) else {
            task.didFailWithError(Self.error("Resource not found: \(relative)"))
            return
        }

        let response = URLResponse(url: url,
                                   mimeType: Self.mimeType(forExtension: fileURL.pathExtension),
                                   expectedContentLength: data.count,
                                   textEncodingName: "utf-8")
        task.didReceive(response)
        task.didReceive(data)
        task.didFinish()
    }

    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {
        // Reads are synchronous; nothing to cancel.
    }

    /// MIME type for a file extension. Correct types matter: a stylesheet served
    /// as text/plain won't apply, and a script with the wrong type won't run.
    private static func mimeType(forExtension ext: String) -> String {
        // Return a bare MIME type (no "; charset=…"): WebKit must recognize
        // "text/html" exactly to parse the response as HTML rather than display
        // it as plain text. The character set is conveyed via textEncodingName.
        switch ext.lowercased() {
        case "html", "htm": return "text/html"
        case "css":         return "text/css"
        case "js", "mjs":   return "text/javascript"
        case "json", "map": return "application/json"
        case "svg":         return "image/svg+xml"
        case "png":         return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif":         return "image/gif"
        case "webp":        return "image/webp"
        case "woff2":       return "font/woff2"
        case "woff":        return "font/woff"
        case "ttf":         return "font/ttf"
        case "otf":         return "font/otf"
        case "eot":         return "application/vnd.ms-fontobject"
        default:
            return UTType(filenameExtension: ext)?.preferredMIMEType
                ?? "application/octet-stream"
        }
    }

    private static func error(_ message: String) -> NSError {
        NSError(domain: "BundleResourceSchemeHandler", code: 1,
                userInfo: [NSLocalizedDescriptionKey: message])
    }
}
