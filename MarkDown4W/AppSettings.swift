import Foundation
import Combine

/// Shared, persisted view/display settings for the markdown viewer.
///
/// Values are backed by `UserDefaults` so they persist across launches, and
/// are exposed as `@Published` so SwiftUI views observing this object refresh
/// whenever a setting changes. The toolbar and the Preferences pane both edit
/// this single shared instance.
final class AppSettings: ObservableObject {

    // MARK: Allowed values

    /// Allowed body-font identifiers understood by the web renderer.
    static let allowedBodyFonts = ["system", "newyork", "georgia", "helvetica"]
    /// Allowed theme modes ("auto" is resolved to light/dark before rendering).
    static let allowedThemeModes = ["light", "dark", "auto"]

    /// Inclusive font-size bounds (in points/px) and step used by the +/- helpers.
    static let minFontSize = 12
    static let maxFontSize = 28
    static let fontStep = 1

    // MARK: UserDefaults keys

    private enum Key {
        static let bodyFont = "bodyFont"
        static let fontSizePx = "fontSizePx"
        static let themeMode = "themeMode"
    }

    private let defaults: UserDefaults

    // MARK: Published, persisted values

    /// Body font identifier. One of `allowedBodyFonts`. Default: "system".
    @Published var bodyFont: String {
        didSet {
            guard bodyFont != oldValue else { return }
            defaults.set(bodyFont, forKey: Key.bodyFont)
        }
    }

    /// Body font size in px. Clamped to `minFontSize...maxFontSize`. Default: 17.
    @Published var fontSizePx: Int {
        didSet {
            let clamped = Self.clampFontSize(fontSizePx)
            if clamped != fontSizePx {
                // Re-assign triggers didSet again, but the next pass is a no-op
                // because `clamped == fontSizePx`, so we persist exactly once.
                fontSizePx = clamped
                return
            }
            guard fontSizePx != oldValue else { return }
            defaults.set(fontSizePx, forKey: Key.fontSizePx)
        }
    }

    /// Theme mode. One of `allowedThemeModes`. Default: "auto".
    @Published var themeMode: String {
        didSet {
            guard themeMode != oldValue else { return }
            defaults.set(themeMode, forKey: Key.themeMode)
        }
    }

    // MARK: Init

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Seed defaults so first launch matches the documented values.
        defaults.register(defaults: [
            Key.bodyFont: "system",
            Key.fontSizePx: 17,
            Key.themeMode: "auto",
        ])

        let storedFont = defaults.string(forKey: Key.bodyFont) ?? "system"
        self.bodyFont = Self.allowedBodyFonts.contains(storedFont) ? storedFont : "system"

        let storedSize = defaults.object(forKey: Key.fontSizePx) as? Int ?? 17
        self.fontSizePx = Self.clampFontSize(storedSize)

        let storedTheme = defaults.string(forKey: Key.themeMode) ?? "auto"
        self.themeMode = Self.allowedThemeModes.contains(storedTheme) ? storedTheme : "auto"
    }

    // MARK: Font helpers

    /// Increase the font size by one step, clamped to the allowed maximum.
    func increaseFont() {
        fontSizePx = Self.clampFontSize(fontSizePx + Self.fontStep)
    }

    /// Decrease the font size by one step, clamped to the allowed minimum.
    func decreaseFont() {
        fontSizePx = Self.clampFontSize(fontSizePx - Self.fontStep)
    }

    private static func clampFontSize(_ value: Int) -> Int {
        min(max(value, minFontSize), maxFontSize)
    }

    // MARK: Theme resolution

    /// Resolve the current theme mode to a concrete "light"/"dark" value.
    /// - Parameter systemIsDark: whether the system appearance is currently dark.
    /// - Returns: "light" or "dark" (auto resolves based on `systemIsDark`).
    func resolvedTheme(systemIsDark: Bool) -> String {
        switch themeMode {
        case "light": return "light"
        case "dark": return "dark"
        default: return systemIsDark ? "dark" : "light"
        }
    }
}
