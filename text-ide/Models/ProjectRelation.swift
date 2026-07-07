import Foundation

struct ProjectRelation: Codable {
    var id: UUID
    var name: String
    var folderPath: String
    var iconColorHex: String
    var createdAt: Date
    var lastOpenedAt: Date
    var sortOrder: Int

    init(
        id: UUID,
        name: String,
        folderPath: String,
        iconColorHex: String,
        createdAt: Date,
        lastOpenedAt: Date,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.folderPath = folderPath
        self.iconColorHex = iconColorHex
        self.createdAt = createdAt
        self.lastOpenedAt = lastOpenedAt
        self.sortOrder = sortOrder
    }

    init(from project: Project) {
        self.id = project.id
        self.name = project.name
        self.folderPath = project.folderPath
        self.iconColorHex = project.iconColorHex
        self.createdAt = project.createdAt
        self.lastOpenedAt = project.lastOpenedAt
        self.sortOrder = project.effectiveSortOrder
    }

    static func readFrom(url: URL) throws -> [ProjectRelation] {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([ProjectRelation].self, from: data)
    }

    static func write(_ relations: [ProjectRelation], to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(relations)
        try data.write(to: url, options: .atomic)
    }
}
