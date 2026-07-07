import SwiftUI
import SwiftData
import CodeEditSourceEditor
import CodeEditLanguages

struct CodeEditorView: View {
    let project: Project
    @Bindable var editorState: EditorState

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @State private var editorText: String = ""
    @State private var sourceEditorState = SourceEditorState()
    @State private var filePendingClose: EditorState.OpenFile?

    var body: some View {
        VStack(spacing: 0) {
            if !editorState.openFiles.isEmpty {
                fileTabBar
                editorContent
            } else {
                emptyState
            }
        }
        .onChange(of: editorState.activeFileId) { _, _ in
            syncEditorText()
        }
        .onChange(of: editorText) { _, newValue in
            if let id = editorState.activeFileId {
                editorState.updateContent(for: id, content: newValue)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .saveFile)) { _ in
            saveCurrentFile()
        }
        .alert("Alterações não salvas", isPresented: Binding(
            get: { filePendingClose != nil },
            set: { if !$0 { filePendingClose = nil } }
        )) {
            Button("Salvar") {
                if let file = filePendingClose {
                    saveFile(file)
                    editorState.closeFile(id: file.id)
                    filePendingClose = nil
                }
            }
            Button("Descartar", role: .destructive) {
                if let file = filePendingClose {
                    editorState.closeFile(id: file.id)
                    filePendingClose = nil
                }
            }
            Button("Cancelar", role: .cancel) {
                filePendingClose = nil
            }
        } message: {
            Text("Deseja salvar as alterações em \(filePendingClose?.name ?? "")?")
        }
    }

    // MARK: - File Tab Bar

    private var fileTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(editorState.openFiles) { file in
                    fileTab(file)
                }
            }
        }
        .frame(height: 28)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func fileTab(_ file: EditorState.OpenFile) -> some View {
        let isActive = file.id == editorState.activeFileId
        return HStack(spacing: Spacing.xs) {
            if file.isDirty {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 6, height: 6)
            }
            Text(file.name)
                .font(.system(size: Typography.captionSize))
                .lineLimit(1)
            Button(action: {
                if file.isDirty {
                    filePendingClose = file
                } else {
                    editorState.closeFile(id: file.id)
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
            }
            .buttonStyle(.plain)
            .opacity(0.5)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 4)
        .background(isActive ? Color(nsColor: .textBackgroundColor) : Color.clear)
        .overlay(alignment: .bottom) {
            if isActive {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(height: 2)
            }
        }
        .onTapGesture {
            editorState.activeFileId = file.id
        }
    }

    // MARK: - Editor Content

    @ViewBuilder
    private var editorContent: some View {
        if let file = editorState.activeFile {
            let language = CodeLanguage.detectLanguageFrom(url: file.url)
            SourceEditor(
                $editorText,
                language: language,
                configuration: SourceEditorConfiguration(
                    appearance: .init(
                        theme: defaultEditorTheme(),
                        font: NSFont.monospacedSystemFont(ofSize: Typography.bodySize, weight: .regular),
                        wrapLines: true
                    ),
                    behavior: .init(indentOption: .spaces(count: 4)),
                    layout: .init(editorOverscroll: 0.1),
                    peripherals: .init(showMinimap: false)
                ),
                state: $sourceEditorState
            )
            .background(
                Button("") {
                    saveCurrentFile()
                }
                .keyboardShortcut("s", modifiers: .command)
                .hidden()
            )
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            icon: "doc.text",
            title: "Editor",
            message: "Selecione um arquivo para editar"
        )
    }

    // MARK: - Actions

    private func syncEditorText() {
        editorText = editorState.activeFile?.content ?? ""
    }

    private func saveCurrentFile() {
        guard let file = editorState.activeFile else { return }
        saveFile(file)
    }

    private func saveFile(_ file: EditorState.OpenFile) {
        let service = FileBrowserService(project: project, modelContext: modelContext)
        do {
            try service.writeFile(at: file.url, content: file.content)
            editorState.markSaved(id: file.id)
        } catch {
            appState.showToast("Erro ao salvar: \(error.localizedDescription)", type: .error)
        }
    }

    private func defaultEditorTheme() -> EditorTheme {
        let isDark = NSApp.effectiveAppearance.name == .darkAqua
        if isDark {
            return EditorTheme(
                text: EditorTheme.Attribute(color: NSColor(hex: "FFFFFF")),
                insertionPoint: NSColor(hex: "007AFF"),
                invisibles: EditorTheme.Attribute(color: NSColor(hex: "53606E")),
                background: NSColor(hex: "292A30"),
                lineHighlight: NSColor(hex: "2F3239"),
                selection: NSColor(hex: "646F83"),
                keywords: EditorTheme.Attribute(color: NSColor(hex: "FF7AB2"), bold: true),
                commands: EditorTheme.Attribute(color: NSColor(hex: "78C2B3")),
                types: EditorTheme.Attribute(color: NSColor(hex: "6BDFFF")),
                attributes: EditorTheme.Attribute(color: NSColor(hex: "CC9768")),
                variables: EditorTheme.Attribute(color: NSColor(hex: "4EB0CC")),
                values: EditorTheme.Attribute(color: NSColor(hex: "B281EB")),
                numbers: EditorTheme.Attribute(color: NSColor(hex: "D9C97C")),
                strings: EditorTheme.Attribute(color: NSColor(hex: "FF8170")),
                characters: EditorTheme.Attribute(color: NSColor(hex: "D9C97C")),
                comments: EditorTheme.Attribute(color: NSColor(hex: "7F8C98"))
            )
        } else {
            return EditorTheme(
                text: EditorTheme.Attribute(color: NSColor(hex: "000000")),
                insertionPoint: NSColor(hex: "000000"),
                invisibles: EditorTheme.Attribute(color: NSColor(hex: "D6D6D6")),
                background: NSColor(hex: "FFFFFF"),
                lineHighlight: NSColor(hex: "ECF5FF"),
                selection: NSColor(hex: "B2D7FF"),
                keywords: EditorTheme.Attribute(color: NSColor(hex: "9B2393"), bold: true),
                commands: EditorTheme.Attribute(color: NSColor(hex: "326D74")),
                types: EditorTheme.Attribute(color: NSColor(hex: "0B4F79")),
                attributes: EditorTheme.Attribute(color: NSColor(hex: "815F03")),
                variables: EditorTheme.Attribute(color: NSColor(hex: "0F68A0")),
                values: EditorTheme.Attribute(color: NSColor(hex: "6C36A9")),
                numbers: EditorTheme.Attribute(color: NSColor(hex: "1C00CF")),
                strings: EditorTheme.Attribute(color: NSColor(hex: "C41A16")),
                characters: EditorTheme.Attribute(color: NSColor(hex: "1C00CF")),
                comments: EditorTheme.Attribute(color: NSColor(hex: "267507"))
            )
        }
    }
}
