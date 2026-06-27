import SwiftUI

/// The shared display-controls panel, embedded both in the toolbar gear popover
/// and in the ⌘, Settings window. The caller injects the shared `AppSettings`
/// via `.environmentObject(settings)`.
struct DisplaySettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // MARK: Appearance
            section("Appearance") {
                Picker("", selection: $settings.themeMode) {
                    Text("Light").tag("light")
                    Text("Sepia").tag("sepia")
                    Text("Dark").tag("dark")
                    Text("Auto").tag("auto")
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }

            Divider()

            // MARK: Font
            section("Font") {
                Menu {
                    ForEach(AppSettings.bodyFontNames, id: \.id) { entry in
                        Button {
                            settings.bodyFont = entry.id
                        } label: {
                            HStack {
                                Text(entry.name).font(fontPreview(for: entry.id))
                                if settings.bodyFont == entry.id {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Text(currentFontName)
                        .font(fontPreview(for: settings.bodyFont, size: 13))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }

            Divider()

            // MARK: Text Size
            section("Text Size") {
                Slider(
                    value: Binding(
                        get: { Double(settings.fontLevel) },
                        set: { settings.fontLevel = Int($0.rounded()) }
                    ),
                    in: 0...4,
                    step: 1,
                    minimumValueLabel: Image(systemName: "textformat.size.smaller"),
                    maximumValueLabel: Image(systemName: "textformat.size.larger")
                ) {
                    Text("Text Size")
                }
                Text("\(settings.fontSizePx) px")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // MARK: Keyboard Shortcuts
            section("Keyboard Shortcuts") {
                VStack(spacing: 6) {
                    ForEach(ShortcutAction.allCases) { action in
                        HStack {
                            Text(action.title)
                            Spacer()
                            ShortcutRecorderView(action: action)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(width: 300)
    }

    // MARK: Helpers

    private var currentFontName: String {
        AppSettings.bodyFontNames.first(where: { $0.id == settings.bodyFont })?.name ?? "System"
    }

    /// A small titled section with a header above its content.
    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func fontPreview(for id: String, size: CGFloat = 14) -> Font {
        switch id {
        case "newyork":   return .system(size: size, design: .serif)
        case "georgia":   return .custom("Georgia", size: size)
        case "helvetica": return .custom("Helvetica Neue", size: size)
        default:          return .system(size: size)
        }
    }
}
