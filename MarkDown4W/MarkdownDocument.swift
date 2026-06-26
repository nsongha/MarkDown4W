import SwiftUI
import UniformTypeIdentifiers

/// A read-only, document-based wrapper around a markdown file's text.
///
/// Used with `DocumentGroup(viewing:)`. Decoding is intentionally tolerant:
/// it prefers strict UTF-8 but falls back to a lossy decode so opening a file
/// with odd bytes never fails.
struct MarkdownDocument: FileDocument {

    /// Types this document can read. Markdown UTType when available, plus
    /// plain text so `.md`, `.markdown`, `.txt`, etc. all open.
    static var readableContentTypes: [UTType] {
        var types: [UTType] = []
        if let markdown = UTType("net.daringfireball.markdown") {
            types.append(markdown)
        }
        types.append(.plainText)
        // Some files declare only the generic text type.
        types.append(.text)
        return types
    }

    /// The full markdown source text.
    var text: String

    init(text: String = "") {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        let data = configuration.file.regularFileContents ?? Data()
        if let decoded = String(data: data, encoding: .utf8) {
            self.text = decoded
        } else {
            // Lossy fallback so we never throw on unexpected byte sequences.
            self.text = String(decoding: data, as: UTF8.self)
        }
    }

    /// Required by `FileDocument`. The app is view-only and never invokes a
    /// save, but the protocol still requires an implementation, so we simply
    /// round-trip the text back out as UTF-8.
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}
