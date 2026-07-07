import Foundation
import SwiftData

@MainActor
final class ProjectService {
    private let modelContext: ModelContext

    enum OpenResult {
        case success(Project)
        case needsConfigCreation(URL)
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func createProject(name: String, folderURL: URL, iconColorHex: String) throws -> Project {
        print("🔵 Criando projeto '\(name)' em: \(folderURL.path)")

        let bookmark = try createBookmark(for: folderURL)
        print("🔵 Bookmark criado: \(bookmark.count) bytes")

        let config = ProjectConfig(name: name, iconColor: iconColorHex)
        let configURL = folderURL.appendingPathComponent(".textide.json")
        print("🔵 Config URL: \(configURL.path)")

        do {
            try withSecurityScopedAccess(to: folderURL) {
                print("🔵 Tentando gravar config...")
                try config.writeTo(url: configURL)
                print("🔵 Config gravada com sucesso!")
            }
        } catch {
            print("🔴 ERRO ao gravar config: \(error)")
            throw error
        }

        let maxSortOrder = getMaxSortOrder()
        let project = Project(
            name: name,
            folderPath: folderURL.path,
            iconColorHex: iconColorHex,
            securityBookmark: bookmark,
            sortOrder: maxSortOrder + 1
        )
        modelContext.insert(project)
        try modelContext.save()
        print("🔵 Projeto salvo no SwiftData")

        try? APMFileManager.shared.addProjectRelation(project)

        return project
    }

    func openExistingProject(folderURL: URL) throws -> OpenResult {
        let configURL = folderURL.appendingPathComponent(".textide.json")

        let hasConfig = try withSecurityScopedAccess(to: folderURL) {
            ProjectConfig.exists(at: configURL)
        }

        if hasConfig {
            let config = try withSecurityScopedAccess(to: folderURL) {
                try ProjectConfig.readFrom(url: configURL)
            }
            let bookmark = try createBookmark(for: folderURL)
            let maxSortOrder = getMaxSortOrder()
            let project = Project(
                name: config.name,
                folderPath: folderURL.path,
                iconColorHex: config.iconColor,
                createdAt: config.createdAt,
                securityBookmark: bookmark,
                sortOrder: maxSortOrder + 1
            )
            modelContext.insert(project)
            try modelContext.save()

            try? APMFileManager.shared.addProjectRelation(project)

            return .success(project)
        } else {
            return .needsConfigCreation(folderURL)
        }
    }

    func createConfigForExistingProject(name: String, folderURL: URL, iconColorHex: String) throws -> Project {
        let bookmark = try createBookmark(for: folderURL)
        let config = ProjectConfig(name: name, iconColor: iconColorHex)
        let configURL = folderURL.appendingPathComponent(".textide.json")

        try withSecurityScopedAccess(to: folderURL) {
            try config.writeTo(url: configURL)
        }

        let maxSortOrder = getMaxSortOrder()
        let project = Project(
            name: name,
            folderPath: folderURL.path,
            iconColorHex: iconColorHex,
            securityBookmark: bookmark,
            sortOrder: maxSortOrder + 1
        )
        modelContext.insert(project)
        try modelContext.save()

        try? APMFileManager.shared.addProjectRelation(project)

        return project
    }

    func removeProject(_ project: Project) throws {
        modelContext.delete(project)
        try modelContext.save()

        try? APMFileManager.shared.removeProjectRelation(id: project.id)
    }

    func updateProject(_ project: Project, name: String, iconColorHex: String) throws {
        let folderURL = try restoreFolderURL(from: project)
        let configURL = folderURL.appendingPathComponent(".textide.json")

        try withSecurityScopedAccess(to: folderURL) {
            let config = ProjectConfig(
                name: name,
                iconColor: iconColorHex,
                createdAt: project.createdAt
            )
            try config.writeTo(url: configURL)
        }

        project.name = name
        project.iconColorHex = iconColorHex
        try modelContext.save()

        try? APMFileManager.shared.updateProjectRelation(project)
    }

    func updateLastOpened(_ project: Project) throws {
        project.lastOpenedAt = Date()
        try modelContext.save()

        try? APMFileManager.shared.updateProjectRelation(project)
    }

    func reorderProjects(_ projects: [Project]) throws {
        for (index, project) in projects.enumerated() {
            project.sortOrder = index
        }
        try modelContext.save()

        try? APMFileManager.shared.saveProjectRelations(projects.map { ProjectRelation(from: $0) })
    }

    private func getMaxSortOrder() -> Int {
        let descriptor = FetchDescriptor<Project>(sortBy: [SortDescriptor(\.sortOrder, order: .reverse)])
        if let lastProject = try? modelContext.fetch(descriptor).first {
            return lastProject.effectiveSortOrder
        }
        return -1
    }

    func readConfig(from project: Project) -> ProjectConfig? {
        do {
            let folderURL = try restoreFolderURL(from: project)
            let configURL = folderURL.appendingPathComponent(".textide.json")
            return try withSecurityScopedAccess(to: folderURL) {
                try ProjectConfig.readFrom(url: configURL)
            }
        } catch {
            print("🔴 Erro ao ler config: \(error)")
            return nil
        }
    }

    func restoreFolderURL(from project: Project) throws -> URL {
        guard let bookmark = project.securityBookmark else {
            return project.folderURL
        }

        var isStale = false
        let url = try URL(
            resolvingBookmarkData: bookmark,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )

        if isStale {
            let newBookmark = try createBookmark(for: url)
            project.securityBookmark = newBookmark
            try modelContext.save()
        }

        return url
    }

    private func withSecurityScopedAccess<T>(to url: URL, block: () throws -> T) throws -> T {
        print("🔵 startAccessingSecurityScopedResource para: \(url.path)")
        guard url.startAccessingSecurityScopedResource() else {
            print("🔴 FALHA ao obter acesso security-scoped!")
            throw NSError(domain: "ProjectService", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Não foi possível obter acesso security-scoped para \(url.path)"
            ])
        }
        print("🔵 Acesso obtido com sucesso")

        defer {
            url.stopAccessingSecurityScopedResource()
            print("🔵 Acesso liberado")
        }
        return try block()
    }

    private func createBookmark(for url: URL) throws -> Data {
        try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    static let defaultColorHex = "#4A90D9"

    static let availableColors: [String] = [
        "#4A90D9",
        "#E74C3C",
        "#2ECC71",
        "#F39C12",
        "#9B59B6",
        "#1ABC9C",
        "#E67E22",
        "#3498DB",
        "#E91E63",
        "#00BCD4"
    ]
}
