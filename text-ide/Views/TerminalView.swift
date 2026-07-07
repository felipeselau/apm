import SwiftUI
import SwiftData

struct TerminalView: View {
    let project: Project
    @Environment(\.modelContext) private var modelContext
    @State private var shellService = ShellService()
    @State private var commandInput = ""
    @State private var commandHistory: [String] = []
    @State private var historyIndex: Int = -1
    @State private var resolvedFolderURL: URL?
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(shellService.output.enumerated()), id: \.element.id) { index, line in
                            Text(line.text)
                                .font(.system(size: Typography.bodySize, design: .monospaced))
                                .foregroundStyle(lineColor(for: line.type))
                                .textSelection(.enabled)
                                .id(index)
                        }
                    }
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .onChange(of: shellService.output.count) { _, _ in
                    if let lastIndex = shellService.output.indices.last {
                        withAnimation(.easeOut(duration: 0.1)) {
                            proxy.scrollTo(lastIndex, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            HStack(spacing: Spacing.sm) {
                Text("$")
                    .font(.system(size: Typography.bodySize, design: .monospaced))
                    .foregroundStyle(.secondary)

                TextField("", text: $commandInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: Typography.bodySize, design: .monospaced))
                    .focused($isInputFocused)
                    .onSubmit {
                        submitCommand()
                    }
                    .onKeyPress(.upArrow) {
                        navigateHistory(forward: false)
                        return .handled
                    }
                    .onKeyPress(.downArrow) {
                        navigateHistory(forward: true)
                        return .handled
                    }

                if shellService.isRunning {
                    Button(action: { shellService.stop() }) {
                        Image(systemName: "stop.circle")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .help("Stop running command")
                }
            }
            .padding(Spacing.md)
        }
        .background(Color(nsColor: .textBackgroundColor))
        .onAppear {
            resolvedFolderURL = try? ProjectService(modelContext: modelContext).restoreFolderURL(from: project) ?? project.folderURL
            isInputFocused = true
        }
    }

    private func submitCommand() {
        let trimmed = commandInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        commandHistory.append(trimmed)
        historyIndex = -1
        commandInput = ""

        let url = resolvedFolderURL ?? project.folderURL
        shellService.run(command: trimmed, in: url)
    }

    private func navigateHistory(forward: Bool) {
        guard !commandHistory.isEmpty else { return }

        if forward {
            if historyIndex > 0 {
                historyIndex -= 1
                commandInput = commandHistory[commandHistory.count - 1 - historyIndex]
            } else if historyIndex == 0 {
                historyIndex = -1
                commandInput = ""
            }
        } else {
            if historyIndex < commandHistory.count - 1 {
                historyIndex += 1
                commandInput = commandHistory[commandHistory.count - 1 - historyIndex]
            }
        }
    }

    private func lineColor(for type: OutputLine.LineType) -> Color {
        switch type {
        case .command:
            return .accentColor
        case .error:
            return .red
        case .output:
            return .primary
        }
    }
}
