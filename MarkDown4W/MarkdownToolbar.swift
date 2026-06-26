import SwiftUI

/// Toolbar content for the document window. All controls edit the single
/// shared `AppSettings` instance, so changes are reflected immediately in the
/// web view and persist across launches.
struct MarkdownToolbar: ToolbarContent {
    @EnvironmentObject private var settings: AppSettings

    /// Display names for the selectable body fonts, keyed by their identifier.
    private static let fontDisplayNames: [(id: String, name: String)] = [
        ("system", "System"),
        ("newyork", "New York"),
        ("georgia", "Georgia"),
        ("helvetica", "Helvetica Neue"),
    ]

    var body: some ToolbarContent {
        ToolbarItemGroup {
            Button {
                settings.decreaseFont()
            } label: {
                Label("Decrease Text Size", systemImage: "textformat.size.smaller")
            }
            .help("Decrease text size")
            .disabled(settings.fontSizePx <= AppSettings.minFontSize)

            Button {
                settings.increaseFont()
            } label: {
                Label("Increase Text Size", systemImage: "textformat.size.larger")
            }
            .help("Increase text size")
            .disabled(settings.fontSizePx >= AppSettings.maxFontSize)

            // Theme picker
            Menu {
                Picker("Theme", selection: $settings.themeMode) {
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                    Text("Auto").tag("auto")
                }
                .pickerStyle(.inline)
            } label: {
                Label("Theme", systemImage: "circle.lefthalf.filled")
            }
            .help("Appearance")

            // Font picker
            Menu {
                Picker("Body Font", selection: $settings.bodyFont) {
                    ForEach(Self.fontDisplayNames, id: \.id) { font in
                        Text(font.name).tag(font.id)
                    }
                }
                .pickerStyle(.inline)
            } label: {
                Label("Body Font", systemImage: "textformat")
            }
            .help("Body font")
        }
    }
}
