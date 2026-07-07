import Foundation
import SwiftData

@Model
final class Project {
    var id: UUID
    var name: String
    var folderPath: String
    var iconColorHex: String
    var createdAt: Date
    var lastOpenedAt: Date
    var securityBookmark: Data?
    var sortOrder: Int?

    init(
        id: UUID = UUID(),
        name: String,
        folderPath: String,
        iconColorHex: String,
        createdAt: Date = Date(),
        lastOpenedAt: Date = Date(),
        securityBookmark: Data? = nil,
        sortOrder: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.folderPath = folderPath
        self.iconColorHex = iconColorHex
        self.createdAt = createdAt
        self.lastOpenedAt = lastOpenedAt
        self.securityBookmark = securityBookmark
        self.sortOrder = sortOrder
    }

    var effectiveSortOrder: Int {
        sortOrder ?? 0
    }

    var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    var folderURL: URL {
        URL(fileURLWithPath: folderPath)
    }

    var configURL: URL {
        folderURL.appendingPathComponent(".textide.json")
    }
}
