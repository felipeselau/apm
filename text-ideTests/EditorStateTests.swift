import Testing
@testable import text_ide

struct EditorStateTests {

    @Test func openFile() {
        let state = EditorState()
        let url = URL(fileURLWithPath: "/test.swift")
        state.openFile(url: url, content: "test")
        #expect(state.openFiles.count == 1)
        #expect(state.activeFileId == url.path)
    }

    @Test func closeFile() {
        let state = EditorState()
        let url = URL(fileURLWithPath: "/test.swift")
        state.openFile(url: url, content: "test")
        state.closeFile(id: url.path)
        #expect(state.openFiles.count == 0)
    }

    @Test func dirtyTracking() {
        let state = EditorState()
        let url = URL(fileURLWithPath: "/test.swift")
        state.openFile(url: url, content: "original")
        #expect(state.activeFile?.isDirty == false)

        state.updateContent(for: url.path, content: "modified")
        #expect(state.activeFile?.isDirty == true)

        state.markSaved(id: url.path)
        #expect(state.activeFile?.isDirty == false)
    }

    @Test func reopenFileNoDuplicate() {
        let state = EditorState()
        let url = URL(fileURLWithPath: "/test.swift")
        state.openFile(url: url, content: "first")
        state.openFile(url: url, content: "second")
        #expect(state.openFiles.count == 1)
    }
}
