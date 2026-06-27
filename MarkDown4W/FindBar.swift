import SwiftUI

/// A compact find bar overlaid on the document. Drives the web view's native
/// incremental find via `WebViewProxy`.
struct FindBar: View {
    @ObservedObject var proxy: WebViewProxy
    @Binding var isPresented: Bool

    @State private var query = ""
    @State private var found = true
    @FocusState private var fieldFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 12))

            TextField("Find", text: $query)
                .textFieldStyle(.plain)
                .frame(width: 160)
                .focused($fieldFocused)
                .onSubmit { runFind(forward: true) }
                .onChange(of: query) { _ in runFind(forward: true) }

            if !query.isEmpty && !found {
                Text("Not found")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Divider().frame(height: 16)

            Button { runFind(forward: false) } label: {
                Image(systemName: "chevron.up")
            }
            .buttonStyle(.borderless)
            .disabled(query.isEmpty)
            .help("Previous (⇧↩)")

            Button { runFind(forward: true) } label: {
                Image(systemName: "chevron.down")
            }
            .buttonStyle(.borderless)
            .disabled(query.isEmpty)
            .help("Next (↩)")

            Button { close() } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
            .help("Close (⎋)")
        }
        .font(.system(size: 12))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.12))
        )
        .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
        .onExitCommand { close() }
        .onAppear { fieldFocused = true }
    }

    private func runFind(forward: Bool) {
        guard !query.isEmpty else { found = true; return }
        proxy.find(query, forward: forward) { matched in
            found = matched
        }
    }

    private func close() {
        isPresented = false
        query = ""
        found = true
        proxy.clearSelection()
    }
}
