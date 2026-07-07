import Foundation
import SwiftUI

@Observable
final class EditorState {
    struct OpenFile: Identifiable, Hashable {
        let id: String
        let url: URL
        var content: String
        var originalContent: String

        var isDirty: Bool { content != originalContent }
        var name: String { url.lastPathComponent }

        init(id: String, url: URL, content: String, originalContent: String) {
            self.id = id
            self.url = url
            self.content = content
            self.originalContent = originalContent
        }
    }

    var openFiles: [OpenFile] = []
    var activeFileId: String?

    var activeFile: OpenFile? {
        openFiles.first { $0.id == activeFileId }
    }

    func openFile(url: URL, content: String) {
        let id = url.path
        if let index = openFiles.firstIndex(where: { $0.id == id }) {
            activeFileId = id
            return
        }
        let file = OpenFile(id: id, url: url, content: content, originalContent: content)
        openFiles.append(file)
        activeFileId = id
    }

    func closeFile(id: String) {
        guard let index = openFiles.firstIndex(where: { $0.id == id }) else { return }
        let wasActive = activeFileId == id
        openFiles.remove(at: index)
        if wasActive {
            activeFileId = openFiles.last?.id
        }
    }

    func updateContent(for id: String, content: String) {
        guard let index = openFiles.firstIndex(where: { $0.id == id }) else { return }
        openFiles[index].content = content
    }

    func markSaved(id: String) {
        guard let index = openFiles.firstIndex(where: { $0.id == id }) else { return }
        openFiles[index].originalContent = openFiles[index].content
    }
}
