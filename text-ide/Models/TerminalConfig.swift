import Foundation

struct TerminalConfig: Codable, Equatable {
    var shell: String?
    var env: [String: String]?
    var envFiles: [String]?
    var scripts: [String: String]?
    var ai: AIConfig?
    var initCommands: [String]?
    var fontFamily: String?

    struct AIConfig: Codable, Equatable {
        var provider: String?
        var command: String?
        var args: [String]?
        var autoStart: Bool = false
    }
}
