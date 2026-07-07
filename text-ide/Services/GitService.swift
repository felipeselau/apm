import SwiftUI
import Foundation
import SwiftData

@MainActor
final class GitService {
    private let project: Project
    private let modelContext: ModelContext

    init(project: Project, modelContext: ModelContext) {
        self.project = project
        self.modelContext = modelContext
    }

    // MARK: - Models

    struct GitStatus {
        var currentBranch: String
        var staged: [FileChange]
        var unstaged: [FileChange]
        var untracked: [FileChange]
    }

    struct FileChange: Identifiable, Hashable {
        var id: String { path }
        let path: String
        let status: ChangeType

        enum ChangeType: String {
            case modified = "M"
            case added = "A"
            case deleted = "D"
            case renamed = "R"
            case untracked = "?"
            case copied = "C"

            var label: String {
                switch self {
                case .modified: return "Modificado"
                case .added: return "Adicionado"
                case .deleted: return "Removido"
                case .renamed: return "Renomeado"
                case .untracked: return "Não rastreado"
                case .copied: return "Copiado"
                }
            }

            var color: Color {
                switch self {
                case .modified: return .orange
                case .added: return .green
                case .deleted: return .red
                case .renamed: return .blue
                case .untracked: return .secondary
                case .copied: return .cyan
                }
            }
        }
    }

    struct GitCommit: Identifiable {
        let id: String  // short hash
        let message: String
        let author: String
        let date: String
    }

    // MARK: - Operations

    func isGitRepo() async -> Bool {
        let result = await runGit(["rev-parse", "--is-inside-work-tree"])
        return result.exitCode == 0
    }

    func status() async throws -> GitStatus {
        // Get current branch
        let branchResult = await runGit(["branch", "--show-current"])
        let branch = branchResult.output.trimmingCharacters(in: .whitespacesAndNewlines)

        // Get porcelain status
        let statusResult = await runGit(["status", "--porcelain=v1", "-u"])
        guard statusResult.exitCode == 0 else {
            throw GitError.commandFailed(statusResult.output)
        }

        var staged: [FileChange] = []
        var unstaged: [FileChange] = []
        var untracked: [FileChange] = []

        let lines = statusResult.output.components(separatedBy: "\n").filter { !$0.isEmpty }
        for line in lines {
            guard line.count >= 3 else { continue }
            let indexStatus = line[line.startIndex]
            let workTreeStatus = line[line.index(after: line.startIndex)]
            let path = String(line.dropFirst(3))

            // Staged changes (index column)
            if indexStatus != " " && indexStatus != "?" {
                if let type = FileChange.ChangeType(rawValue: String(indexStatus)) {
                    staged.append(FileChange(path: path, status: type))
                }
            }

            // Unstaged changes (work-tree column)
            if workTreeStatus != " " && workTreeStatus != "?" {
                if let type = FileChange.ChangeType(rawValue: String(workTreeStatus)) {
                    unstaged.append(FileChange(path: path, status: type))
                }
            }

            // Untracked
            if indexStatus == "?" && workTreeStatus == "?" {
                untracked.append(FileChange(path: path, status: .untracked))
            }
        }

        return GitStatus(currentBranch: branch, staged: staged, unstaged: unstaged, untracked: untracked)
    }

    func diff(file: String? = nil, staged: Bool = false) async throws -> String {
        var args = ["diff"]
        if staged { args.append("--cached") }
        if let file = file { args.append("--"); args.append(file) }
        let result = await runGit(args)
        guard result.exitCode == 0 else { throw GitError.commandFailed(result.output) }
        return result.output
    }

    func log(count: Int = 20) async throws -> [GitCommit] {
        let result = await runGit(["log", "--oneline", "--format=%h|%s|%an|%ar", "-\(count)"])
        guard result.exitCode == 0 else { throw GitError.commandFailed(result.output) }

        return result.output
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .compactMap { line in
                let parts = line.components(separatedBy: "|")
                guard parts.count >= 4 else { return nil }
                return GitCommit(
                    id: parts[0],
                    message: parts[1],
                    author: parts[2],
                    date: parts[3]
                )
            }
    }

    func add(file: String) async throws {
        let result = await runGit(["add", file])
        guard result.exitCode == 0 else { throw GitError.commandFailed(result.output) }
    }

    func addAll() async throws {
        let result = await runGit(["add", "-A"])
        guard result.exitCode == 0 else { throw GitError.commandFailed(result.output) }
    }

    func unstage(file: String) async throws {
        let result = await runGit(["reset", "HEAD", file])
        guard result.exitCode == 0 else { throw GitError.commandFailed(result.output) }
    }

    func commit(message: String) async throws {
        let result = await runGit(["commit", "-m", message])
        guard result.exitCode == 0 else { throw GitError.commandFailed(result.output) }
    }

    func branches() async throws -> [String] {
        let result = await runGit(["branch", "--list", "--format=%(refname:short)"])
        guard result.exitCode == 0 else { throw GitError.commandFailed(result.output) }
        return result.output.components(separatedBy: "\n").filter { !$0.isEmpty }
    }

    func checkout(branch: String) async throws {
        let result = await runGit(["checkout", branch])
        guard result.exitCode == 0 else { throw GitError.commandFailed(result.output) }
    }

    func pull() async throws {
        let result = await runGit(["pull"])
        guard result.exitCode == 0 else { throw GitError.commandFailed(result.output) }
    }

    func push() async throws {
        let result = await runGit(["push"])
        guard result.exitCode == 0 else { throw GitError.commandFailed(result.output) }
    }

    // MARK: - Private

    private struct GitResult {
        let output: String
        let exitCode: Int32
    }

    enum GitError: Error, LocalizedError {
        case commandFailed(String)
        case folderAccessFailed

        var errorDescription: String? {
            switch self {
            case .commandFailed(let msg): return "Git: \(msg)"
            case .folderAccessFailed: return "Não foi possível acessar a pasta do projeto"
            }
        }
    }

    private func runGit(_ arguments: [String]) async -> GitResult {
        let service = ProjectService(modelContext: modelContext)
        guard let folderURL = try? service.restoreFolderURL(from: project) else {
            return GitResult(output: "folder access failed", exitCode: -1)
        }

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
                process.arguments = arguments
                process.currentDirectoryURL = folderURL

                let stdout = Pipe()
                let stderr = Pipe()
                process.standardOutput = stdout
                process.standardError = stderr

                do {
                    try process.run()
                    process.waitUntilExit()

                    let stdoutData = stdout.fileHandleForReading.readDataToEndOfFile()
                    let stderrData = stderr.fileHandleForReading.readDataToEndOfFile()

                    let output = (String(data: stdoutData, encoding: .utf8) ?? "") +
                                 (String(data: stderrData, encoding: .utf8) ?? "")

                    continuation.resume(returning: GitResult(output: output, exitCode: process.terminationStatus))
                } catch {
                    continuation.resume(returning: GitResult(output: error.localizedDescription, exitCode: -1))
                }
            }
        }
    }
}
