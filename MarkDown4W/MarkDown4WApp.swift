import SwiftUI
import AppKit
import UniformTypeIdentifiers

@main
struct MarkDown4WApp: App {
    /// Single shared settings instance, injected into document windows and the
    /// Settings pane, and used by the app delegate's shortcut monitor.
    @StateObject private var settings = AppSettings.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    static let shortcutsWindowID = "shortcuts"

    var body: some Scene {
        DocumentGroup(viewing: MarkdownDocument.self) { file in
            ContentView(document: file.document)
                .environmentObject(settings)
        }
        .commands {
            // The viewer has no untitled document, so "New Tab" opens a file
            // picker; the chosen file opens as a tab (shared tabbingIdentifier).
            // No static keyboardShortcut here — the customizable ⌘T is handled
            // by ShortcutMonitor to avoid double-dispatch.
            CommandGroup(replacing: .newItem) {
                Button("New Tab…") { MarkDown4WApp.presentOpenPanel() }
            }
            // Remove the default Find menu items: their ⌘F key-equivalent made
            // the Edit menu flash before our shortcut monitor handled the key.
            // Find is driven entirely by ShortcutMonitor → the find bar.
            CommandGroup(replacing: .textEditing) { }
            // Keyboard-shortcut editor, reached from the menu bar like other apps.
            ShortcutEditorCommand()
        }

        // ⌘, Settings window — same controls as the toolbar popover.
        Settings {
            DisplaySettingsView()
                .environmentObject(settings)
        }

        // Editor window for customizing shortcuts (opened via the menu command).
        Window("Keyboard Shortcuts", id: Self.shortcutsWindowID) {
            ShortcutsEditorView()
                .environmentObject(settings)
        }
        .windowResizability(.contentSize)
    }

    /// Open one or more markdown files; each opens within the app (as a tab when
    /// a document window is already frontmost).
    static func presentOpenPanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        var types: [UTType] = [.plainText, .text]
        if let md = UTType("net.daringfireball.markdown") { types.append(md) }
        if let mdExt = UTType(filenameExtension: "md") { types.append(mdExt) }
        panel.allowedContentTypes = types

        panel.begin { response in
            guard response == .OK else { return }
            for url in panel.urls {
                NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, _ in }
            }
        }
    }
}

/// Adds a "Keyboard Shortcuts…" item to the app menu (⌥⌘K) that opens the
/// editor window — kept as its own `Commands` type so it can use `openWindow`.
struct ShortcutEditorCommand: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(after: .appSettings) {
            Button("Keyboard Shortcuts…") {
                openWindow(id: MarkDown4WApp.shortcutsWindowID)
            }
            .keyboardShortcut("k", modifiers: [.command, .option])
        }
    }
}

/// Installs the app-wide customizable-shortcut monitor once at launch.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var shortcutMonitor: ShortcutMonitor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let monitor = ShortcutMonitor(settings: .shared) {
            MarkDown4WApp.presentOpenPanel()
        }
        monitor.start()
        shortcutMonitor = monitor
    }
}
