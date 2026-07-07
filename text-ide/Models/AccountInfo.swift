import Foundation

struct AccountInfo: Codable {
    var name: String
    var email: String
    var createdAt: Date

    init(name: String, email: String, createdAt: Date = Date()) {
        self.name = name
        self.email = email
        self.createdAt = createdAt
    }

    func writeTo(url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(self)
        try data.write(to: url, options: .atomic)
    }

    static func readFrom(url: URL) throws -> AccountInfo {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(AccountInfo.self, from: data)
    }

    static func exists(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }
}
