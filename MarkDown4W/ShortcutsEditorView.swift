import SwiftUI

/// A small editor window for customizing keyboard shortcuts, opened from the
/// menu bar (⌥⌘K). Each row shows an action and an inline, click-to-record
/// shortcut cell.
struct ShortcutsEditorView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Keyboard Shortcuts")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(ShortcutAction.allCases) { action in
                    HStack {
                        Text(action.title)
                        Spacer(minLength: 24)
                        ShortcutRecorderView(action: action)
                    }
                }
            }

            Text("Click a shortcut to record a new one. Press ⎋ to cancel.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 360)
        .fixedSize(horizontal: false, vertical: true)
    }
}
