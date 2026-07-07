import Foundation

struct AppSettings: Codable {
    var theme: String
    var fontSize: Int
    var showLineNumbers: Bool

    init(
        theme: String = "system",
        fontSize: Int = 14,
        showLineNumbers: Bool = true
    ) {
        self.theme = theme
        self.fontSize = fontSize
        self.showLineNumbers = showLineNumbers
    }

    func writeTo(url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(self)
        try data.write(to: url, options: .atomic)
    }

    static func readFrom(url: URL) throws -> AppSettings {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(AppSettings.self, from: data)
    }

    static func exists(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }
}
