import SwiftUI

/// Toolbar content for the document window: a single gear button at the trailing
/// edge that opens a popover with all display controls. Keeping just one item
/// lets the document title center in the unified title bar.
struct MarkdownToolbar: ToolbarContent {
    @EnvironmentObject private var settings: AppSettings
    @State private var showPopover = false

    /// Document name shown centered in the title bar.
    let title: String

    var body: some ToolbarContent {
        // The centered filename is plain text, not a control — hide the glass
        // capsule that macOS 26 draws behind toolbar items.
        if #available(macOS 26.0, *) {
            ToolbarItem(placement: .principal) {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
            }
            .sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: .principal) {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
            }
        }

        ToolbarItem(placement: .primaryAction) {
            Button {
                showPopover.toggle()
            } label: {
                Label("Display Settings", systemImage: "gearshape")
            }
            .help("Display settings")
            .popover(isPresented: $showPopover, arrowEdge: .bottom) {
                DisplaySettingsView()
                    .environmentObject(settings)
            }
        }
    }
}
