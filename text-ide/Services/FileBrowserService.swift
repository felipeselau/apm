import Foundation
import SwiftData

@MainActor
final class FileBrowserService {
    private let project: Project
    private let modelContext: ModelContext

    init(project: Project, modelContext: ModelContext) {
        self.project = project
        self.modelContext = modelContext
    }

    struct FileItem: Identifiable, Hashable {
        let id: String
        let name: String
        let url: URL
        let isDirectory: Bool
        let children: [FileItem]?

        var icon: String {
            if isDirectory { return "folder.fill" }
            let ext = url.pathExtension.lowercased()
            switch ext {
            case "swift": return "swift"
            case "js", "jsx", "ts", "tsx": return "doc.text"
            case "json": return "curlybraces"
            case "md", "txt": return "doc.plaintext"
            case "py": return "doc.text"
            case "html": return "globe"
            case "css", "scss": return "paintbrush"
            case "yml", "yaml": return "list.bullet"
            case "sh", "bash", "zsh": return "terminal"
            case "png", "jpg", "jpeg", "gif", "svg": return "photo"
            default: return "doc"
            }
        }
    }

    func listDirectory(at url: URL) -> [FileItem] {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .isHiddenKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return contents
            .filter { url in
                let name = url.lastPathComponent
                return !name.hasPrefix(".") && name != "node_modules" && name != "__pycache__" && name != ".build" && name != "DerivedData"
            }
            .sorted { a, b in
                let aIsDir = (try? a.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                let bIsDir = (try? b.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                if aIsDir != bIsDir { return aIsDir }
                return a.lastPathComponent.localizedCaseInsensitiveCompare(b.lastPathComponent) == .orderedAscending
            }
            .map { url in
                let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                return FileItem(
                    id: url.path,
                    name: url.lastPathComponent,
                    url: url,
                    isDirectory: isDir,
                    children: isDir ? [] : nil
                )
            }
    }

    func readFile(at url: URL) throws -> String {
        try String(contentsOf: url, encoding: .utf8)
    }

    func writeFile(at url: URL, content: String) throws {
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    func projectRootURL() throws -> URL {
        let service = ProjectService(modelContext: modelContext)
        return try service.restoreFolderURL(from: project)
    }
}
