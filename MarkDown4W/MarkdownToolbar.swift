import SwiftUI

/// Toolbar content for the document window: a single gear button at the trailing
/// edge that opens a popover with all display controls. The window keeps its
/// native (system) title.
struct MarkdownToolbar: ToolbarContent {
    @EnvironmentObject private var settings: AppSettings
    @State private var showPopover = false

    var body: some ToolbarContent {
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
