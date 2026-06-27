import AppKit

/// Posted by `ShortcutMonitor` when the user triggers a find-related shortcut.
/// The key window's find bar / `ContentView` observes these.
extension Notification.Name {
    static let mdShowFind = Notification.Name("net.songha.MarkDown4W.showFind")
    static let mdFindNext = Notification.Name("net.songha.MarkDown4W.findNext")
    static let mdFindPrevious = Notification.Name("net.songha.MarkDown4W.findPrevious")
}

/// User-customizable actions, shown and rebindable in the Keyboard Shortcuts editor.
enum ShortcutAction: String, CaseIterable, Identifiable {
    case increaseSize
    case decreaseSize
    case find
    case findNext
    case findPrevious
    case newTab

    var id: String { rawValue }

    /// Human-readable label shown in the shortcuts list.
    var title: String {
        switch self {
        case .increaseSize: return "Increase Text Size"
        case .decreaseSize: return "Decrease Text Size"
        case .find:         return "Find"
        case .findNext:     return "Find Next"
        case .findPrevious: return "Find Previous"
        case .newTab:       return "New Tab"
        }
    }

    /// Factory default binding.
    var defaultShortcut: KeyShortcut {
        switch self {
        case .increaseSize: return KeyShortcut(key: "=", modifiers: [.command])
        case .decreaseSize: return KeyShortcut(key: "-", modifiers: [.command])
        case .find:         return KeyShortcut(key: "f", modifiers: [.command])
        case .findNext:     return KeyShortcut(key: "g", modifiers: [.command])
        case .findPrevious: return KeyShortcut(key: "g", modifiers: [.command, .shift])
        case .newTab:       return KeyShortcut(key: "t", modifiers: [.command])
        }
    }
}

/// A key + modifier-flags combination, matchable against an `NSEvent` and
/// renderable as glyphs (e.g. `⌘⇧F`). Persisted as JSON.
struct KeyShortcut: Codable, Equatable {
    /// `charactersIgnoringModifiers`, lowercased (e.g. "f", "=", "-").
    var key: String
    /// Raw value of the device-independent `NSEvent.ModifierFlags` subset.
    var modifiersRaw: UInt

    /// Modifier flags we consider significant.
    static let relevantModifiers: NSEvent.ModifierFlags = [.command, .shift, .option, .control]

    init(key: String, modifiers: NSEvent.ModifierFlags) {
        self.key = key.lowercased()
        self.modifiersRaw = modifiers.intersection(Self.relevantModifiers).rawValue
    }

    var modifiers: NSEvent.ModifierFlags { NSEvent.ModifierFlags(rawValue: modifiersRaw) }

    /// True when this combo requires at least one modifier (we reject bare keys).
    var isValid: Bool { !modifiers.intersection(Self.relevantModifiers).isEmpty && !key.isEmpty }

    /// Does the given key-down event match this shortcut?
    func matches(_ event: NSEvent) -> Bool {
        let eventMods = event.modifierFlags.intersection(Self.relevantModifiers)
        guard eventMods.rawValue == modifiersRaw else { return false }
        guard let chars = event.charactersIgnoringModifiers?.lowercased() else { return false }
        return chars == key
    }

    /// Build from a captured key-down event (used by the recorder).
    static func from(event: NSEvent) -> KeyShortcut? {
        guard let chars = event.charactersIgnoringModifiers, !chars.isEmpty else { return nil }
        return KeyShortcut(key: chars, modifiers: event.modifierFlags)
    }

    /// Glyph string, e.g. `⌃⌥⇧⌘F`.
    var displayString: String {
        var s = ""
        if modifiers.contains(.control) { s += "⌃" }
        if modifiers.contains(.option)  { s += "⌥" }
        if modifiers.contains(.shift)   { s += "⇧" }
        if modifiers.contains(.command) { s += "⌘" }
        s += Self.displayKey(key)
        return s
    }

    private static func displayKey(_ key: String) -> String {
        switch key {
        case " ":       return "Space"
        case "\u{1b}":  return "⎋"
        case "\r":      return "↩"
        case "\t":      return "⇥"
        case "\u{7f}":  return "⌫"
        default:        return key.uppercased()
        }
    }
}
