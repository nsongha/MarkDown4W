import SwiftUI

@main
struct MarkDown4WApp: App {
    /// Single shared settings instance, injected into both the document
    /// windows and the Preferences pane.
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        DocumentGroup(viewing: MarkdownDocument.self) { file in
            ContentView(document: file.document)
                .environmentObject(settings)
        }

        // ⌘, Preferences window with the same controls as the toolbar.
        Settings {
            PreferencesView()
                .environmentObject(settings)
        }
    }
}

/// Preferences pane (⌘,). Edits the same shared `AppSettings` as the toolbar.
struct PreferencesView: View {
    @EnvironmentObject private var settings: AppSettings

    private static let fontDisplayNames: [(id: String, name: String)] = [
        ("system", "System"),
        ("newyork", "New York"),
        ("georgia", "Georgia"),
        ("helvetica", "Helvetica Neue"),
    ]

    var body: some View {
        Form {
            Picker("Theme", selection: $settings.themeMode) {
                Text("Light").tag("light")
                Text("Dark").tag("dark")
                Text("Auto").tag("auto")
            }

            Picker("Body Font", selection: $settings.bodyFont) {
                ForEach(Self.fontDisplayNames, id: \.id) { font in
                    Text(font.name).tag(font.id)
                }
            }

            Stepper(value: $settings.fontSizePx,
                    in: AppSettings.minFontSize...AppSettings.maxFontSize,
                    step: AppSettings.fontStep) {
                Text("Text Size: \(settings.fontSizePx) px")
            }
        }
        .padding(20)
        .frame(width: 320)
    }
}
