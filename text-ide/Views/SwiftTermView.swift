import SwiftUI
import SwiftTerm
import SwiftData

struct SwiftTermView: NSViewRepresentable {
    let project: Project
    let sessionId: UUID
    let terminalConfig: TerminalConfig?
    let sessionManager: TerminalSessionManager?
    @Environment(\.modelContext) private var modelContext

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let terminal = LocalProcessTerminalView(frame: .zero)
        terminal.processDelegate = context.coordinator
        terminal.font = resolveFont()

        guard let resolvedURL = try? ProjectService(modelContext: modelContext).restoreFolderURL(from: project) else {
            startProcess(terminal: terminal, url: project.folderURL)
            registerTerminal(terminal)
            return terminal
        }

        context.coordinator.resolvedURL = resolvedURL
        context.coordinator.didStartAccessing = resolvedURL.startAccessingSecurityScopedResource()
        startProcess(terminal: terminal, url: resolvedURL)
        registerTerminal(terminal)

        return terminal
    }

    func updateNSView(_ nsView: LocalProcessTerminalView, context: Context) {}

    static func dismantleNSView(_ nsView: LocalProcessTerminalView, coordinator: Coordinator) {
        coordinator.parent.sessionManager?.unregisterTerminal(for: coordinator.parent.sessionId)
        nsView.terminate()

        if coordinator.didStartAccessing, let url = coordinator.resolvedURL {
            url.stopAccessingSecurityScopedResource()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    private func registerTerminal(_ terminal: LocalProcessTerminalView) {
        sessionManager?.registerTerminal(terminal, for: sessionId)
        feedInitCommands(to: terminal)
    }

    private func feedInitCommands(to terminal: LocalProcessTerminalView) {
        guard let commands = terminalConfig?.initCommands, !commands.isEmpty else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            for cmd in commands {
                terminal.terminal.feed(text: cmd + "\n")
            }
        }
    }

    private func resolveFont() -> NSFont {
        let size = Typography.bodySize

        if let family = terminalConfig?.fontFamily,
           let font = NSFont(name: family, size: size) {
            return font
        }

        let nerdFontNames = [
            "JetBrainsMonoNFM-Regular",
            "JetBrainsMonoNerdFontMono-Regular",
            "JetBrainsMono Nerd Font Mono",
            "JetBrainsMono Nerd Font"
        ]
        for name in nerdFontNames {
            if let font = NSFont(name: name, size: size) {
                return font
            }
        }

        return NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
    }

    private func startProcess(terminal: LocalProcessTerminalView, url: URL) {
        let env = EnvLoader.buildEnvironment(config: terminalConfig, projectFolder: url)
        let shell = terminalConfig?.shell ?? "/bin/zsh"
        terminal.startProcess(
            executable: shell,
            args: ["-l", "-i"],
            environment: env,
            currentDirectory: url.path
        )
    }

    final class Coordinator: NSObject, LocalProcessTerminalViewDelegate {
        let parent: SwiftTermView
        var resolvedURL: URL?
        var didStartAccessing = false

        init(parent: SwiftTermView) {
            self.parent = parent
        }

        func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}

        func setTerminalTitle(source: LocalProcessTerminalView, title: String) {}

        func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}

        func processTerminated(source: TerminalView, exitCode: Int32?) {
            source.terminal.feed(text: "\r\n[Processo encerrado]\r\n")
        }
    }
}
