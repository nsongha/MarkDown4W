import SwiftUI
import AppKit

/// An inline, click-to-record shortcut cell. One per `ShortcutAction` row in the
/// settings panel. Displays the current binding as glyphs (or "Add" when unset),
/// reveals a reset control on hover, and captures a new combination in place when
/// clicked.
struct ShortcutRecorderView: View {
    @EnvironmentObject var settings: AppSettings
    let action: ShortcutAction

    @State private var recording = false
    @State private var hovering = false
    @State private var captureMonitor: Any?

    private var current: KeyShortcut? { settings.shortcut(for: action) }

    private var label: String {
        if recording { return "Press keys…" }
        if let sc = current, sc.isValid { return sc.displayString }
        return "Add"
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(textColor)
                .lineLimit(1)
                .frame(width: 84, height: 22)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(background)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.primary.opacity(recording ? 0.35 : 0.0), lineWidth: 1)
                )
                .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .onTapGesture { beginRecording() }

            if hovering && !recording {
                Button {
                    settings.resetShortcut(for: action)
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .padding(3)
                        .background(Circle().fill(Color(nsColor: .controlBackgroundColor)))
                }
                .buttonStyle(.plain)
                .help("Reset to default")
                .offset(x: 6)
            }
        }
        .onHover { hovering = $0 }
        .onDisappear { endRecording(restoreSuspend: true) }
    }

    private var textColor: Color {
        if recording { return .primary }
        if current?.isValid == true { return .primary }
        return .secondary
    }

    private var background: Color {
        if recording { return Color.accentColor.opacity(0.15) }
        if hovering { return Color.primary.opacity(0.08) }
        return Color.primary.opacity(0.04)
    }

    // MARK: Recording

    private func beginRecording() {
        guard !recording else { return }
        recording = true
        ShortcutMonitor.isSuspended = true

        captureMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Escape cancels with no change.
            if event.keyCode == 53 {
                self.endRecording(restoreSuspend: true)
                return nil
            }
            if let sc = KeyShortcut.from(event: event), sc.isValid {
                self.settings.setShortcut(sc, for: self.action)
                self.endRecording(restoreSuspend: true)
                return nil
            }
            // Bare key (no modifier) / invalid — cancel.
            self.endRecording(restoreSuspend: true)
            return nil
        }
    }

    private func endRecording(restoreSuspend: Bool) {
        if let m = captureMonitor {
            NSEvent.removeMonitor(m)
            captureMonitor = nil
        }
        if recording {
            recording = false
        }
        if restoreSuspend {
            ShortcutMonitor.isSuspended = false
        }
    }
}
