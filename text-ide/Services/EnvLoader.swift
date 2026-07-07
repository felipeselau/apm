import Foundation
import SwiftTerm

enum EnvLoader {
    static func parseEnvFile(at url: URL) -> [String: String] {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            return [:]
        }

        var env: [String: String] = [:]
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }

            guard let equalsIndex = trimmed.firstIndex(of: "=") else { continue }

            let key = trimmed[..<equalsIndex].trimmingCharacters(in: .whitespaces)
            var value = String(trimmed[trimmed.index(after: equalsIndex)...]).trimmingCharacters(in: .whitespaces)

            if (value.hasPrefix("\"") && value.hasSuffix("\"")) ||
                (value.hasPrefix("'") && value.hasSuffix("'")) {
                value = String(value.dropFirst().dropLast())
            }

            env[key] = value
        }

        return env
    }

    static func buildEnvironment(
        config: TerminalConfig?,
        projectFolder: URL
    ) -> [String] {
        var env = Terminal.getEnvironmentVariables(termName: "xterm-256color", trueColor: true)

        guard let config else { return env }

        if let envFiles = config.envFiles {
            for file in envFiles {
                let fileURL = projectFolder.appendingPathComponent(file)
                let parsed = parseEnvFile(at: fileURL)
                merge(envDict: &env, with: parsed)
            }
        }

        if let configEnv = config.env {
            merge(envDict: &env, with: configEnv)
        }

        return env
    }

    private static func merge(envDict: inout [String], with newValues: [String: String]) {
        var current: [String: String] = [:]
        for entry in envDict {
            if let equalsIndex = entry.firstIndex(of: "=") {
                let key = String(entry[..<equalsIndex])
                let value = String(entry[entry.index(after: equalsIndex)...])
                current[key] = value
            }
        }

        for (key, value) in newValues {
            current[key] = value
        }

        envDict = current.map { "\($0.key)=\($0.value)" }
    }
}
