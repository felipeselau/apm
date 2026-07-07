import Foundation

struct ProjectCommand: Identifiable, Codable {
    let id: String
    let name: String
    let command: String
    let icon: String
}
