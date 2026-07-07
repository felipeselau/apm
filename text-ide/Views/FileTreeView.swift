import SwiftUI
import SwiftData

struct FileTreeView: View {
    let project: Project
    let onFileSelect: (URL) -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var rootItems: [FileBrowserService.FileItem] = []
    @State private var expandedDirs: Set<String> = []

    var body: some View {
        List {
            ForEach(rootItems) { item in
                FileRowView(
                    item: item,
                    project: project,
                    onFileSelect: onFileSelect,
                    expandedDirs: $expandedDirs
                )
            }
        }
        .listStyle(.sidebar)
        .font(.system(size: Typography.bodySize))
        .onAppear { loadRoot() }
    }

    private func loadRoot() {
        let service = FileBrowserService(project: project, modelContext: modelContext)
        guard let rootURL = try? service.projectRootURL() else { return }
        rootItems = service.listDirectory(at: rootURL)
    }
}

struct FileRowView: View {
    let item: FileBrowserService.FileItem
    let project: Project
    let onFileSelect: (URL) -> Void
    @Binding var expandedDirs: Set<String>

    @Environment(\.modelContext) private var modelContext

    @State private var children: [FileBrowserService.FileItem]?
    @State private var hasLoaded = false

    var body: some View {
        if item.isDirectory {
            DisclosureGroup(
                isExpanded: Binding(
                    get: { expandedDirs.contains(item.id) },
                    set: { expanded in
                        if expanded { expandedDirs.insert(item.id) }
                        else { expandedDirs.remove(item.id) }
                    }
                )
            ) {
                if let children = children {
                    ForEach(children) { child in
                        FileRowView(
                            item: child,
                            project: project,
                            onFileSelect: onFileSelect,
                            expandedDirs: $expandedDirs
                        )
                    }
                } else if hasLoaded {
                    Text("Vazio")
                        .font(.system(size: Typography.captionSize))
                        .foregroundStyle(.secondary)
                } else {
                    ProgressView()
                        .scaleEffect(0.5)
                }
            } label: {
                Label(item.name, systemImage: item.icon)
                    .foregroundStyle(.primary)
            }
            .onChange(of: expandedDirs.contains(item.id)) { _, expanded in
                if expanded && !hasLoaded {
                    loadChildren()
                }
            }
        } else {
            Button(action: { onFileSelect(item.url) }) {
                Label(item.name, systemImage: item.icon)
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
        }
    }

    private func loadChildren() {
        hasLoaded = true
        let service = FileBrowserService(project: project, modelContext: modelContext)
        children = service.listDirectory(at: item.url)
    }
}
