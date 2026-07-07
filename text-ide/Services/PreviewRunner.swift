import Foundation

@Observable
final class PreviewRunner {
    var isRunning: Bool = false
    var output: [String] = []
    var detectedURL: String? = nil
    var currentCommand: String? = nil

    private var shellService = ShellService()
    private var urlDetectionRegex = /https?:\/\/localhost:\d+|https?:\/\/127\.0\.0\.1:\d+/
    private var lastProcessedIndex = 0

    func run(command: String, in folderURL: URL, commandId: String? = nil) {
        output = []
        detectedURL = nil
        currentCommand = commandId
        isRunning = true
        lastProcessedIndex = 0

        shellService.run(command: command, in: folderURL)

        Task { [weak self] in
            guard let self else { return }
            while await self.shellService.isRunning {
                let allOutput = await self.shellService.output
                guard lastProcessedIndex < allOutput.count else {
                    try? await Task.sleep(for: .milliseconds(100))
                    continue
                }
                for line in allOutput[lastProcessedIndex...] {
                    let cleaned = self.stripANSI(line.text)
                    await MainActor.run {
                        self.output.append(cleaned)
                        self.detectURL(in: cleaned)
                    }
                }
                lastProcessedIndex = allOutput.count
                try? await Task.sleep(for: .milliseconds(100))
            }
            await MainActor.run {
                self.isRunning = false
            }
        }
    }

    func stop() {
        shellService.stop()
        isRunning = false
    }

    private func stripANSI(_ text: String) -> String {
        text.replacing(/\u{1B}\[[0-9;]*[a-zA-Z]/, with: "")
            .replacing(/\u{1B}\].*?\u{0007}/, with: "")
    }

    private func detectURL(in line: String) {
        if let match = line.firstMatch(of: urlDetectionRegex) {
            detectedURL = String(match.0)
        }
    }
}
