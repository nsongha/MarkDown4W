import Foundation
import Combine

/// Shared, persisted view/display settings for the markdown viewer.
///
/// Values are backed by `UserDefaults` so they persist across launches, and
/// are exposed as `@Published` so SwiftUI views observing this object refresh
/// whenever a setting changes. The gear popover and the Preferences pane both
/// edit this single shared instance.
final class AppSettings: ObservableObject {

    /// Shared instance used by both the SwiftUI scene and the app delegate
    /// (which installs the global shortcut monitor).
    static let shared = AppSettings()

    // MARK: Allowed values

    /// Allowed body-font identifiers understood by the web renderer.
    static let allowedBodyFonts = ["system", "newyork", "georgia", "helvetica"]

    /// Display names for the body fonts, in menu order.
    static let bodyFontNames: [(id: String, name: String)] = [
        ("system", "System"),
        ("newyork", "New York"),
        ("georgia", "Georgia"),
        ("helvetica", "Helvetica Neue"),
    ]

    /// Theme shades the user can choose. "auto" resolves to light/dark by the
    /// system appearance (never sepia). The other three pass through unchanged.
    static let allowedThemeModes = ["light", "sepia", "dark", "auto"]

    /// The five discrete font sizes (px). The slider snaps to these.
    static let fontSizeStops = [14, 16, 18, 20, 22]
    /// Default level index (middle = 18px).
    static let defaultFontLevel = 2

    // MARK: UserDefaults keys

    private enum Key {
        static let bodyFont = "bodyFont"
        static let fontSizePx = "fontSizePx"
        static let fontLevel = "fontLevel"
        static let themeMode = "themeMode"
        static let shortcuts = "customShortcuts"
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

    /// Font-size level (0…4 → `fontSizeStops`). Drives `fontSizePx`.
    @Published var fontLevel: Int {
        didSet {
            let clamped = min(max(fontLevel, 0), Self.fontSizeStops.count - 1)
            if clamped != fontLevel {
                fontLevel = clamped   // re-enters didSet once; next pass is a no-op
                return
            }
            defaults.set(fontLevel, forKey: Key.fontLevel)
            fontSizePx = Self.fontSizeStops[fontLevel]
        }
    }

    /// Body font size in px — derived from `fontLevel`, persisted as a mirror so
    /// the renderer bridge (`MarkdownWebView`) consumes it unchanged.
    @Published var fontSizePx: Int {
        didSet {
            guard fontSizePx != oldValue else { return }
            defaults.set(fontSizePx, forKey: Key.fontSizePx)
        }
    }

    /// Theme shade. One of `allowedThemeModes`. Default: "auto".
    @Published var themeMode: String {
        didSet {
            guard themeMode != oldValue else { return }
            defaults.set(themeMode, forKey: Key.themeMode)
        }
    }

    /// Customizable keyboard shortcuts. Absent action = disabled (no binding).
    @Published private(set) var shortcuts: [ShortcutAction: KeyShortcut]

    // MARK: Init

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Seed simple defaults so first launch matches documented values.
        defaults.register(defaults: [
            Key.bodyFont: "system",
            Key.themeMode: "auto",
        ])

        let storedFont = defaults.string(forKey: Key.bodyFont) ?? "system"
        self.bodyFont = Self.allowedBodyFonts.contains(storedFont) ? storedFont : "system"

        // Theme: migrate any unknown / legacy value to "auto".
        let storedTheme = defaults.string(forKey: Key.themeMode) ?? "auto"
        self.themeMode = Self.allowedThemeModes.contains(storedTheme) ? storedTheme : "auto"

        // Font level: migrate from an older `fontSizePx` if no level is stored.
        let level: Int
        if defaults.object(forKey: Key.fontLevel) != nil {
            level = min(max(defaults.integer(forKey: Key.fontLevel), 0), Self.fontSizeStops.count - 1)
        } else if let oldPx = defaults.object(forKey: Key.fontSizePx) as? Int {
            level = Self.nearestLevel(forPx: oldPx)
        } else {
            level = Self.defaultFontLevel
        }
        self.fontLevel = level
        self.fontSizePx = Self.fontSizeStops[level]

        // Shortcuts: load stored custom bindings, else seed factory defaults.
        self.shortcuts = Self.loadShortcuts(from: defaults, key: Key.shortcuts)

        // Persist the resolved level/size + any seeded shortcuts on first run.
        defaults.set(level, forKey: Key.fontLevel)
        defaults.set(Self.fontSizeStops[level], forKey: Key.fontSizePx)
        persistShortcuts()
    }

    /// Nearest font-size stop to a raw px value, biasing ties upward (17 → 18).
    private static func nearestLevel(forPx px: Int) -> Int {
        var best = defaultFontLevel
        var bestDist = Int.max
        for (i, stop) in fontSizeStops.enumerated() {
            let d = abs(stop - px)
            if d < bestDist || (d == bestDist && stop > fontSizeStops[best]) {
                bestDist = d
                best = i
            }
        }
        return best
    }

    // MARK: Font helpers

    /// Increase the font size by one level (clamped). Used by the shortcut.
    func increaseFont() { fontLevel = min(fontLevel + 1, Self.fontSizeStops.count - 1) }

    /// Decrease the font size by one level (clamped). Used by the shortcut.
    func decreaseFont() { fontLevel = max(fontLevel - 1, 0) }

    // MARK: Theme resolution

    /// Resolve the current theme mode to a concrete shade for the renderer.
    /// - Parameter systemIsDark: whether the system appearance is currently dark.
    /// - Returns: "light", "sepia", or "dark" (auto → light/dark by system).
    func resolvedTheme(systemIsDark: Bool) -> String {
        switch themeMode {
        case "light", "sepia", "dark": return themeMode
        default: return systemIsDark ? "dark" : "light"   // "auto"
        }
    }

    // MARK: Shortcuts

    /// The binding for an action, or nil if the user disabled it.
    func shortcut(for action: ShortcutAction) -> KeyShortcut? { shortcuts[action] }

    /// Assign a binding. Any other action holding the same combo is disabled,
    /// keeping bindings unique.
    func setShortcut(_ shortcut: KeyShortcut, for action: ShortcutAction) {
        for (other, existing) in shortcuts where other != action && existing == shortcut {
            shortcuts[other] = nil
        }
        shortcuts[action] = shortcut
        persistShortcuts()
    }

    /// Remove an action's binding (disables it).
    func clearShortcut(for action: ShortcutAction) {
        shortcuts[action] = nil
        persistShortcuts()
    }

    /// Restore an action's factory default binding.
    func resetShortcut(for action: ShortcutAction) {
        setShortcut(action.defaultShortcut, for: action)
    }

    /// First action whose binding matches the event (used by the monitor).
    func action(matching event: NSEventLike) -> ShortcutAction? {
        for action in ShortcutAction.allCases {
            if let sc = shortcuts[action], sc.matchesRaw(chars: event.charsLower, modifiersRaw: event.modifiersRaw) {
                return action
            }
        }
        return nil
    }

    private func persistShortcuts() {
        var encodable: [String: KeyShortcut] = [:]
        for (action, sc) in shortcuts { encodable[action.rawValue] = sc }
        if let data = try? JSONEncoder().encode(encodable) {
            defaults.set(data, forKey: Key.shortcuts)
        }
    }

    private static func loadShortcuts(from defaults: UserDefaults, key: String) -> [ShortcutAction: KeyShortcut] {
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([String: KeyShortcut].self, from: data) {
            var result: [ShortcutAction: KeyShortcut] = [:]
            for (raw, sc) in decoded {
                if let action = ShortcutAction(rawValue: raw) { result[action] = sc }
            }
            return result
        }
        // First run: seed factory defaults.
        var seeded: [ShortcutAction: KeyShortcut] = [:]
        for action in ShortcutAction.allCases { seeded[action] = action.defaultShortcut }
        return seeded
    }
}

/// Minimal event abstraction so `AppSettings` (Foundation/Combine only) can match
/// shortcuts without importing AppKit. `ShortcutMonitor` adapts `NSEvent` to this.
struct NSEventLike {
    let charsLower: String
    let modifiersRaw: UInt
}

extension KeyShortcut {
    /// Match against raw chars + modifier rawValue (used via `NSEventLike`).
    func matchesRaw(chars: String, modifiersRaw raw: UInt) -> Bool {
        raw == self.modifiersRaw && chars == key
    }
}
