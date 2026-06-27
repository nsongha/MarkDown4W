import SwiftUI

/// A native-style find bar: a full-width strip below the title bar (like the
/// find bar in TextEdit/Pages), with a rounded search field, prev/next
/// navigation, and a Done button. Drives the web view's native find.
struct FindBar: View {
    @ObservedObject var proxy: WebViewProxy
    @Binding var isPresented: Bool

    @State private var query = ""
    @State private var found = true
    @FocusState private var fieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                searchField

                // Prev / next segmented navigation.
                HStack(spacing: 0) {
                    navButton(systemImage: "chevron.left", forward: false)
                    Divider().frame(height: 14)
                    navButton(systemImage: "chevron.right", forward: true)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.primary.opacity(0.12))
                )

                if !query.isEmpty && !found {
                    Text("Not found")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Done") { close() }
                    .controlSize(.small)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .background(.bar)

            Divider()
        }
        .onExitCommand { close() }
        .onAppear { fieldFocused = true }
    }

    private var searchField: some View {
        HStack(spacing: 5) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            TextField("Search", text: $query)
                .textFieldStyle(.plain)
                .focused($fieldFocused)
                .onSubmit { runFind(forward: true) }
                .onChange(of: query) { _, _ in runFind(forward: true) }
            if !query.isEmpty {
                Button { query = ""; proxy.clearSelection() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .font(.system(size: 12))
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(nsColor: .textBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.primary.opacity(0.12))
        )
        .frame(width: 240)
    }

    private func navButton(systemImage: String, forward: Bool) -> some View {
        Button { runFind(forward: forward) } label: {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .medium))
                .frame(width: 24, height: 20)
        }
        .buttonStyle(.plain)
        .disabled(query.isEmpty)
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
