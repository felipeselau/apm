import Foundation

struct ProjectConfig: Codable {
    var name: String
    var iconColor: String
    var createdAt: Date
    var recentFiles: [String]
    var terminal: TerminalConfig?
    var preview: PreviewConfig?
    var projectType: String?

    init(name: String, iconColor: String, createdAt: Date = Date(), recentFiles: [String] = [], terminal: TerminalConfig? = nil, preview: PreviewConfig? = nil, projectType: String? = nil) {
        self.name = name
        self.iconColor = iconColor
        self.createdAt = createdAt
        self.recentFiles = recentFiles
        self.terminal = terminal
        self.preview = preview
        self.projectType = projectType
    }

    func writeTo(url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(self)
        try data.write(to: url, options: .atomic)
    }

    static func readFrom(url: URL) throws -> ProjectConfig {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ProjectConfig.self, from: data)
    }

    static func exists(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }
}
