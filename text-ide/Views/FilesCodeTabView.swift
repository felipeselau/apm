import SwiftUI
import SwiftData

struct FilesCodeTabView: View {
    let project: Project

    @State private var editorState = EditorState()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HSplitView {
            FileTreeView(project: project) { fileURL in
                openFile(url: fileURL)
            }
            .frame(minWidth: 150, idealWidth: 200)

            CodeEditorView(project: project, editorState: editorState)
                .frame(minWidth: 250)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openFile)) { notification in
            guard let url = notification.object as? URL,
                  let content = notification.userInfo?["content"] as? String else { return }
            editorState.openFile(url: url, content: content)
        }
    }

    private func openFile(url: URL) {
        let service = FileBrowserService(project: project, modelContext: modelContext)
        guard let content = try? service.readFile(at: url) else { return }
        editorState.openFile(url: url, content: content)
    }
}
