import Foundation

@MainActor
final class ProjectDetector {
    static func detectType(at folderURL: URL) -> ProjectType {
        let fm = FileManager.default

        if fileExists("package.json", in: folderURL, fm: fm) {
            return .web
        }
        if fileExists("Package.swift", in: folderURL, fm: fm) {
            return .swift
        }
        if fileExists("Cargo.toml", in: folderURL, fm: fm) {
            return .rust
        }
        if fileExists("pyproject.toml", in: folderURL, fm: fm) || fileExists("requirements.txt", in: folderURL, fm: fm) {
            return .python
        }

        return .unknown
    }

    static func detectCommands(at folderURL: URL, type: ProjectType) -> [ProjectCommand] {
        switch type {
        case .web:
            return detectWebCommands(at: folderURL)
        default:
            return []
        }
    }

    private static func fileExists(_ name: String, in folderURL: URL, fm: FileManager) -> Bool {
        fm.fileExists(atPath: folderURL.appendingPathComponent(name).path)
    }

    private static func detectWebCommands(at folderURL: URL) -> [ProjectCommand] {
        let packagePath = folderURL.appendingPathComponent("package.json").path
        guard let data = FileManager.default.contents(atPath: packagePath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let scripts = json["scripts"] as? [String: String]
        else {
            return []
        }

        return scripts.map { key, _ in
            ProjectCommand(
                id: key,
                name: key.prefix(1).uppercased() + key.dropFirst(),
                command: "npm run \(key)",
                icon: Self.icon(for: key)
            )
        }
    }

    private static func icon(for scriptKey: String) -> String {
        switch scriptKey.lowercased() {
        case "dev", "start":
            return "play.fill"
        case "build":
            return "hammer"
        case "test":
            return "checkmark"
        default:
            return "terminal"
        }
    }
}
