import SwiftUI
import SwiftData

struct QuickOpenView: View {
    let project: Project
    let onSelect: (URL) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var query = ""
    @State private var results: [URL] = []

    var body: some View {
        VStack(spacing: 0) {
            TextField("Buscar arquivos...", text: $query)
                .textFieldStyle(.roundedBorder)
                .padding(Spacing.md)
                .onChange(of: query) { _, q in
                    searchFiles(query: q)
                }

            Divider()

            List(results, id: \.path) { url in
                HStack {
                    Image(systemName: "doc")
                    Text(url.lastPathComponent)
                    Spacer()
                    Text(url.deletingLastPathComponent().lastPathComponent)
                        .font(.system(size: Typography.captionSize))
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelect(url)
                    dismiss()
                }
            }
            .listStyle(.plain)
        }
        .frame(width: 500, height: 400)
        .background(.regularMaterial)
        .cornerRadius(Radii.lg)
        .shadow(radius: 20)
    }

    private func searchFiles(query: String) {
        guard !query.isEmpty else {
            results = []
            return
        }
        let fm = FileManager.default
        results = searchDirectory(url: project.folderURL, query: query, fm: fm)
    }

    private func searchDirectory(url: URL, query: String, fm: FileManager) -> [URL] {
        var found: [URL] = []
        guard let contents = try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else { return [] }

        for item in contents {
            let name = item.lastPathComponent
            if name == "node_modules" || name == ".git" { continue }

            if name.localizedCaseInsensitiveContains(query) {
                found.append(item)
            }

            var isDir: ObjCBool = false
            if fm.fileExists(atPath: item.path, isDirectory: &isDir), isDir.boolValue {
                found.append(contentsOf: searchDirectory(url: item, query: query, fm: fm))
            }
        }

        return found
    }
}
