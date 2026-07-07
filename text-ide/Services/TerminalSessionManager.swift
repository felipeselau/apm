import Foundation
import SwiftTerm

@MainActor
@Observable
final class TerminalSessionManager {
    var sessions: [TerminalSession] = []
    var activeSessionId: UUID?

    private var terminalRefs: [UUID: LocalProcessTerminalView] = [:]

    struct TerminalSession: Identifiable {
        public let id: UUID
        public var title: String

        public init(id: UUID = UUID(), title: String) {
            self.id = id
            self.title = title
        }
    }

    func createSession(title: String = "Terminal") -> TerminalSession {
        let session = TerminalSession(title: title)
        sessions.append(session)
        activeSessionId = session.id
        return session
    }

    func closeSession(id: UUID) {
        terminalRefs.removeValue(forKey: id)
        sessions.removeAll { $0.id == id }

        if sessions.isEmpty {
            _ = createSession()
        }

        if activeSessionId == id || activeSessionId == nil {
            activeSessionId = sessions.last?.id
        }
    }

    func renameSession(id: UUID, title: String) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[index].title = title
    }

    func registerTerminal(_ terminal: LocalProcessTerminalView, for sessionId: UUID) {
        terminalRefs[sessionId] = terminal
    }

    func unregisterTerminal(for sessionId: UUID) {
        terminalRefs.removeValue(forKey: sessionId)
    }

    func feedToActiveSession(text: String) {
        guard let id = activeSessionId, let terminal = terminalRefs[id] else { return }
        terminal.terminal.feed(text: text)
    }

    var activeSession: TerminalSession? {
        guard let id = activeSessionId else { return nil }
        return sessions.first { $0.id == id }
    }
}
