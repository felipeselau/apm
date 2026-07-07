import SwiftUI
import SwiftData

struct TerminalTabView: View {
    let project: Project
    @Environment(\.modelContext) private var modelContext

    @State private var sessionManager = TerminalSessionManager()
    @State private var terminalConfig: TerminalConfig?
    @State private var editingTabId: UUID?
    @State private var editText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            tabBar

            if let session = sessionManager.activeSession {
                SwiftTermView(
                    project: project,
                    sessionId: session.id,
                    terminalConfig: terminalConfig,
                    sessionManager: sessionManager
                )
            }
        }
        .onAppear {
            loadConfig()
            if sessionManager.sessions.isEmpty {
                _ = sessionManager.createSession()
            }
            handleAutoStart()
        }
        .onChange(of: sessionManager.activeSessionId) { _, _ in
            editingTabId = nil
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(sessionManager.sessions) { session in
                        tabButton(for: session)
                    }

                    Button(action: { _ = sessionManager.createSession() }) {
                        Image(systemName: "plus")
                            .font(.system(size: Typography.captionSize, weight: .medium))
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Spacing.xs)
            }

            HStack(spacing: Spacing.xs) {
                scriptsMenu
                aiButton
            }
            .padding(.trailing, Spacing.sm)
        }
        .frame(height: 28)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func tabButton(for session: TerminalSessionManager.TerminalSession) -> some View {
        let isActive = session.id == sessionManager.activeSessionId

        return HStack(spacing: Spacing.xs) {
            if editingTabId == session.id {
                TextField("", text: $editText)
                    .textFieldStyle(.plain)
                    .font(.system(size: Typography.captionSize))
                    .frame(width: 80)
                    .onSubmit {
                        sessionManager.renameSession(id: session.id, title: editText)
                        editingTabId = nil
                    }
            } else {
                Text(session.title)
                    .font(.system(size: Typography.captionSize))
                    .lineLimit(1)
            }

            Button(action: { sessionManager.closeSession(id: session.id) }) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .opacity(isActive ? 1 : 0)
            .help("Fechar aba")
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 4)
        .background(isActive ? Color.accentColor.opacity(0.15) : Color.clear)
        .cornerRadius(Radii.sm)
        .highPriorityGesture(
            TapGesture(count: 2).onEnded {
                editingTabId = session.id
                editText = session.title
            }
        )
        .simultaneousGesture(
            TapGesture().onEnded {
                if editingTabId != nil {
                    editingTabId = nil
                }
                sessionManager.activeSessionId = session.id
            }
        )
    }

    // MARK: - Scripts Menu

    private var scriptsMenu: some View {
        Menu {
            if let scripts = terminalConfig?.scripts, !scripts.isEmpty {
                ForEach(Array(scripts.keys.sorted()), id: \.self) { name in
                    Button(name) {
                        if let command = scripts[name] {
                            sessionManager.feedToActiveSession(text: command + "\n")
                        }
                    }
                }
            } else {
                Text("Nenhum script configurado")
                    .font(.system(size: Typography.captionSize))
            }
        } label: {
            HStack(spacing: 2) {
                Image(systemName: "terminal")
                    .font(.system(size: 10))
                Text("Scripts")
                    .font(.system(size: Typography.captionSize))
            }
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    // MARK: - AI Button

    private var aiButton: some View {
        Button(action: launchAI) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: Typography.bodySize))
        }
        .buttonStyle(.plain)
        .help(terminalConfig?.ai?.command != nil
            ? "Iniciar IA"
            : "Configure IA nas configurações do terminal")
        .disabled(terminalConfig?.ai?.command == nil)
        .opacity(terminalConfig?.ai?.command != nil ? 1 : 0.4)
    }

    private func launchAI() {
        guard let ai = terminalConfig?.ai, let command = ai.command else { return }
        let session = sessionManager.createSession(title: ai.provider ?? "IA")
        let fullCommand: String
        if let args = ai.args, !args.isEmpty {
            fullCommand = command + " " + args.joined(separator: " ") + "\n"
        } else {
            fullCommand = command + "\n"
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak sessionManager] in
            sessionManager?.feedToActiveSession(text: fullCommand)
        }
    }

    // MARK: - Config

    private func loadConfig() {
        let service = ProjectService(modelContext: modelContext)
        terminalConfig = service.readTerminalConfig(from: project)
    }

    private func handleAutoStart() {
        guard let ai = terminalConfig?.ai,
              ai.autoStart,
              let command = ai.command
        else { return }

        let session = sessionManager.createSession(title: ai.provider ?? "IA")
        let fullCommand: String
        if let args = ai.args, !args.isEmpty {
            fullCommand = command + " " + args.joined(separator: " ") + "\n"
        } else {
            fullCommand = command + "\n"
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak sessionManager] in
            sessionManager?.feedToActiveSession(text: fullCommand)
        }
    }
}
