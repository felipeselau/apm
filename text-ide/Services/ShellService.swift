import Foundation

struct OutputLine: Identifiable {
    let id = UUID()
    let text: String
    let type: LineType

    enum LineType {
        case command
        case output
        case error
    }
}

@Observable
final class ShellService {
    var output: [OutputLine] = []
    var isRunning: Bool = false

    private var currentProcess: Process?
    private var securityScopedURL: URL?
    private static let maxOutputLines = 10_000

    func run(command: String, in directory: URL) {
        guard !isRunning else { return }
        isRunning = true

        appendLine(.init(text: "$ \(command)", type: .command))

        let process = Process()
        currentProcess = process
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        var accessGranted = false
        if directory.startAccessingSecurityScopedResource() {
            accessGranted = true
            securityScopedURL = directory
        }

        process.currentDirectoryURL = directory

        do {
            try process.run()
        } catch {
            appendLine(.init(text: "Erro ao executar comando: \(error.localizedDescription)", type: .error))
            isRunning = false
            if accessGranted {
                directory.stopAccessingSecurityScopedResource()
                securityScopedURL = nil
            }
            return
        }

        stdoutPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
            let data = fileHandle.availableData
            guard !data.isEmpty, let string = String(data: data, encoding: .utf8) else { return }
            let lines = string.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
            Task { @MainActor in
                for line in lines {
                    self?.appendLine(.init(text: line, type: .output))
                }
            }
        }

        stderrPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
            let data = fileHandle.availableData
            guard !data.isEmpty, let string = String(data: data, encoding: .utf8) else { return }
            let lines = string.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
            Task { @MainActor in
                for line in lines {
                    self?.appendLine(.init(text: line, type: .error))
                }
            }
        }

        process.terminationHandler = { [weak self] _ in
            stdoutPipe.fileHandleForReading.readabilityHandler = nil
            stderrPipe.fileHandleForReading.readabilityHandler = nil
            Task { @MainActor in
                self?.isRunning = false
                self?.currentProcess = nil
                if accessGranted {
                    directory.stopAccessingSecurityScopedResource()
                    self?.securityScopedURL = nil
                }
            }
        }
    }

    func stop() {
        guard let process = currentProcess, process.isRunning else {
            isRunning = false
            currentProcess = nil
            return
        }
        process.terminate()
    }

    func clearOutput() {
        output.removeAll()
    }

    deinit {
        if let url = securityScopedURL {
            url.stopAccessingSecurityScopedResource()
        }
        currentProcess?.terminate()
    }

    private func appendLine(_ line: OutputLine) {
        output.append(line)
        if output.count > Self.maxOutputLines {
            output.removeFirst(output.count - Self.maxOutputLines)
        }
    }
}
