import SwiftUI
import SwiftData

struct GitTabView: View {
    let project: Project

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @State private var gitStatus: GitService.GitStatus?
    @State private var recentCommits: [GitService.GitCommit] = []
    @State private var isLoading = false
    @State private var isGitRepo = true
    @State private var commitMessage = ""
    @State private var selectedFile: GitService.FileChange?
    @State private var diffText: String?
    @State private var showingDiff = false

    private var gitService: GitService {
        GitService(project: project, modelContext: modelContext)
    }

    var body: some View {
        Group {
            if isGitRepo {
                mainContent
            } else {
                emptyState
            }
        }
        .onAppear {
            checkAndRefresh()
        }
        .sheet(isPresented: $showingDiff) {
            diffSheet
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            icon: "arrow.triangle.branch",
            title: "Não é um repositório Git",
            message: "Inicialize com `git init` no terminal"
        )
    }

    // MARK: - Diff Sheet

    private var diffSheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(selectedFile?.path ?? "")
                    .font(.system(size: Typography.headingSize, weight: .medium))
                Spacer()
                Button("Fechar") {
                    showingDiff = false
                }
                .keyboardShortcut(.escape)
            }
            .padding(Spacing.md)

            Divider()

            ScrollView(.vertical) {
                Text(diffText ?? "Sem alterações")
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.md)
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                branchHeader
                stagedSection
                unstagedSection
                untrackedSection
                commitSection
                recentCommitsSection
            }
            .padding(Spacing.sm)
        }
        .background(Color(nsColor: .textBackgroundColor))
        .overlay {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(nsColor: .textBackgroundColor).opacity(0.7))
            }
        }
    }

    // MARK: - Branch Header

    private var branchHeader: some View {
        VStack(spacing: Spacing.xs) {
            HStack {
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: Typography.bodySize))
                Text(gitStatus?.currentBranch ?? "—")
                    .font(.system(size: Typography.bodySize, weight: .semibold))
                    .lineLimit(1)
                Spacer()
                Button(action: {
                    refresh()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: Typography.captionSize))
                }
                .buttonStyle(.plain)
                .help("Atualizar")
                .disabled(isLoading)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)

            HStack(spacing: Spacing.sm) {
                Button(action: {
                    Task {
                        try? await gitService.pull()
                        refresh()
                    }
                }) {
                    Label("Pull", systemImage: "arrow.down")
                }
                Button(action: {
                    Task {
                        try? await gitService.push()
                        refresh()
                    }
                }) {
                    Label("Push", systemImage: "arrow.up")
                }
            }
            .buttonStyle(.bordered)
            .padding(.horizontal, Spacing.sm)
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(Radii.sm)
    }

    // MARK: - Staged Section

    @ViewBuilder
    private var stagedSection: some View {
        if let staged = gitStatus?.staged, !staged.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text("Preparados")
                        .font(.system(size: Typography.captionSize))
                        .foregroundStyle(.secondary)
                    countBadge(staged.count)
                    Spacer()
                    Button("Remover todos") {
                        Task {
                            for file in staged {
                                try? await gitService.unstage(file: file.path)
                            }
                            refresh()
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: Typography.captionSize))
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, Spacing.sm)

                ForEach(staged) { change in
                    fileRow(change: change, actionType: .unstage)
                }
            }
        }
    }

    // MARK: - Unstaged Section

    @ViewBuilder
    private var unstagedSection: some View {
        if let unstaged = gitStatus?.unstaged, !unstaged.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text("Alterações")
                        .font(.system(size: Typography.captionSize))
                        .foregroundStyle(.secondary)
                    countBadge(unstaged.count)
                    Spacer()
                    Button("Preparar todos") {
                        Task {
                            try? await gitService.addAll()
                            refresh()
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: Typography.captionSize))
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, Spacing.sm)

                ForEach(unstaged) { change in
                    fileRow(change: change, actionType: .stage)
                }
            }
        }
    }

    // MARK: - Untracked Section

    @ViewBuilder
    private var untrackedSection: some View {
        if let untracked = gitStatus?.untracked, !untracked.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text("Não rastreados")
                        .font(.system(size: Typography.captionSize))
                        .foregroundStyle(.secondary)
                    countBadge(untracked.count)
                }
                .padding(.horizontal, Spacing.sm)

                ForEach(untracked) { change in
                    fileRow(change: change, actionType: .stage)
                }
            }
        }
    }

    // MARK: - File Row

    private enum FileActionType {
        case stage
        case unstage

        var icon: String {
            switch self {
            case .stage: return "plus"
            case .unstage: return "minus"
            }
        }

        var help: String {
            switch self {
            case .stage: return "Preparar"
            case .unstage: return "Remover"
            }
        }
    }

    private func fileRow(change: GitService.FileChange, actionType: FileActionType) -> some View {
        HStack {
            Text(change.status.rawValue)
                .font(.system(size: Typography.captionSize, weight: .bold, design: .monospaced))
                .foregroundStyle(change.status.color)
                .frame(width: 16)
            Text(change.path)
                .font(.system(size: Typography.bodySize))
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            Button(action: {
                Task {
                    switch actionType {
                    case .stage:
                        try? await gitService.add(file: change.path)
                    case .unstage:
                        try? await gitService.unstage(file: change.path)
                    }
                    refresh()
                }
            }) {
                Image(systemName: actionType.icon)
                    .font(.system(size: Typography.captionSize, weight: .bold))
            }
            .buttonStyle(.plain)
            .help(actionType.help)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            showDiff(file: change)
        }
    }

    // MARK: - Commit Section

    private var commitSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            TextField("Mensagem do commit", text: $commitMessage, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: Typography.bodySize))
                .lineLimit(3...6)

            Button("Commit") {
                Task {
                    try? await gitService.commit(message: commitMessage)
                    commitMessage = ""
                    refresh()
                }
            }
            .buttonStyle(.borderedProminent)
            .font(.system(size: Typography.bodySize))
            .disabled(commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (gitStatus?.staged.isEmpty ?? true))
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(Radii.sm)
    }

    // MARK: - Recent Commits

    private var recentCommitsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Commits recentes")
                .font(.system(size: Typography.captionSize))
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.sm)

            ForEach(recentCommits) { commit in
                HStack(spacing: Spacing.sm) {
                    Text(commit.id)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(width: 60, alignment: .leading)
                    Text(commit.message)
                        .font(.system(size: Typography.bodySize))
                        .lineLimit(1)
                    Spacer()
                    Text(commit.author)
                        .font(.system(size: Typography.captionSize))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text(commit.date)
                        .font(.system(size: Typography.captionSize))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Helpers

    private func countBadge(_ count: Int) -> some View {
        Text("\(count)")
            .font(.system(size: Typography.captionSize, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(Color(nsColor: .separatorColor).opacity(0.3))
            .cornerRadius(Radii.sm)
    }

    // MARK: - Actions

    private func checkAndRefresh() {
        Task {
            let repo = await gitService.isGitRepo()
            isGitRepo = repo
            if repo {
                refresh()
            }
        }
    }

    private func refresh() {
        isLoading = true
        Task {
            do {
                gitStatus = try await gitService.status()
                recentCommits = try await gitService.log()
            } catch {
                appState.showToast("Erro Git: \(error.localizedDescription)", type: .error)
            }
            isLoading = false
        }
    }

    private func showDiff(file: GitService.FileChange) {
        selectedFile = file
        Task {
            do {
                let staged = file.status == .added || file.status == .copied || file.status == .renamed
                diffText = try await gitService.diff(file: file.path, staged: staged)
                showingDiff = true
            } catch {
                diffText = "Erro ao carregar diff"
                showingDiff = true
            }
        }
    }
}
