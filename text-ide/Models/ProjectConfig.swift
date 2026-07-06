import Foundation

struct ProjectConfig: Codable {
    var name: String
    var iconColor: String
    var createdAt: Date
    var recentFiles: [String]

    init(name: String, iconColor: String, createdAt: Date = Date(), recentFiles: [String] = []) {
        self.name = name
        self.iconColor = iconColor
        self.createdAt = createdAt
        self.recentFiles = recentFiles
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
