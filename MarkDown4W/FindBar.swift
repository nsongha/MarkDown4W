import SwiftUI

/// A native-style find bar: a full-width strip below the title bar (like the
/// find bar in TextEdit/Pages), with a rounded search field, a result count,
/// prev/next navigation, and a Done button. Drives the in-page find engine
/// which highlights and boxes all matches.
struct FindBar: View {
    @ObservedObject var proxy: WebViewProxy
    @Binding var isPresented: Bool
    /// Theme background so the bar matches the current shade (not a fixed material).
    var barColor: Color
    /// Whether the current shade is dark (drives field color + control contrast).
    var isDark: Bool

    @State private var query = ""
    @State private var result = FindResult.none
    @FocusState private var fieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                searchField

                countLabel
                    .frame(minWidth: 64, alignment: .leading)

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

                Spacer()

                Button("Done") { close() }
                    .controlSize(.small)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .background(barColor)

            Divider()
        }
        // Resolve SwiftUI control colors against the chosen shade, not the
        // system appearance (the window may be light while macOS is dark).
        .environment(\.colorScheme, isDark ? .dark : .light)
        .onExitCommand { close() }
        .onAppear {
            // Focus the field immediately so the user can type right after ⌘F.
            fieldFocused = true
            DispatchQueue.main.async { fieldFocused = true }
        }
        // Next/previous come from the customizable shortcuts (via the monitor).
        .onReceive(NotificationCenter.default.publisher(for: .mdFindNext)) { _ in
            step(forward: true)
        }
        .onReceive(NotificationCenter.default.publisher(for: .mdFindPrevious)) { _ in
            step(forward: false)
        }
    }

    private var searchField: some View {
        HStack(spacing: 5) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            TextField("Search", text: $query)
                .textFieldStyle(.plain)
                .focused($fieldFocused)
                .onSubmit { step(forward: true) }
                .onChange(of: query) { _, _ in runFind() }
            if !query.isEmpty {
                Button { query = "" } label: {
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
                .fill(isDark ? Color(white: 0.18) : .white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.primary.opacity(0.12))
        )
        .frame(width: 220)
    }

    @ViewBuilder
    private var countLabel: some View {
        if query.isEmpty {
            EmptyView()
        } else if result.total == 0 {
            Text("No results")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        } else {
            Text("\(result.current) of \(result.total)")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private func navButton(systemImage: String, forward: Bool) -> some View {
        Button { step(forward: forward) } label: {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .medium))
                .frame(width: 24, height: 20)
        }
        .buttonStyle(.plain)
        .disabled(result.total == 0)
    }

    private func runFind() {
        guard !query.isEmpty else { result = .none; proxy.clearFind(); return }
        proxy.find(query) { result = $0 }
    }

    private func step(forward: Bool) {
        guard result.total > 0 else { runFind(); return }
        proxy.findStep(forward: forward) { result = $0 }
    }

    private func close() {
        query = ""
        result = .none
        proxy.clearFind()
        // Animate so the bar slides back up (paired with its .transition).
        withAnimation(.easeIn(duration: 0.2)) { isPresented = false }
    }
}
