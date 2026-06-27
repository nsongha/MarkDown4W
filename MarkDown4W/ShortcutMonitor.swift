import AppKit

/// Installs a single app-wide local key-down monitor that dispatches the four
/// customizable actions (`ShortcutAction`). One instance lives for the app's
/// lifetime; the recorder temporarily suspends it via `isSuspended` while it
/// captures a new key combination.
final class ShortcutMonitor {
    /// When true, the global monitor ignores events (set by the recorder while capturing).
    static var isSuspended = false

    private let settings: AppSettings
    private let onNewTab: () -> Void
    private var monitor: Any?

    init(settings: AppSettings, onNewTab: @escaping () -> Void) {
        self.settings = settings
        self.onNewTab = onNewTab
    }

    func start() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, !ShortcutMonitor.isSuspended else { return event }
            let mods = event.modifierFlags.intersection(KeyShortcut.relevantModifiers).rawValue
            let chars = event.charactersIgnoringModifiers?.lowercased() ?? ""
            let like = NSEventLike(charsLower: chars, modifiersRaw: mods)
            guard let action = self.settings.action(matching: like) else { return event }
            switch action {
            case .increaseSize: self.settings.increaseFont()
            case .decreaseSize: self.settings.decreaseFont()
            case .newTab:       self.onNewTab()
            case .find:         NotificationCenter.default.post(name: .mdShowFind, object: nil)
            }
            return nil   // consume matched events
        }
    }

    func stop() {
        if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
    }
}
