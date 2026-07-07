import SwiftUI
import SwiftData

enum RightPanelTab: String, CaseIterable, Identifiable {
    case preview
    case files
    case git

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .preview: return "safari"
        case .files: return "folder"
        case .git: return "arrow.triangle.branch"
        }
    }

    var label: String {
        switch self {
        case .preview: return "Preview"
        case .files: return "Arquivos"
        case .git: return "Git"
        }
    }
}

struct RightPanelView: View {
    let project: Project

    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @State private var activeTab: RightPanelTab = .preview
    @State private var previewConfig: PreviewConfig?
    @State private var hoveredTab: RightPanelTab?

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            tabContent
        }
        .onAppear {
            loadConfig()
        }
        .onChange(of: project.id) { _, _ in
            activeTab = .preview
            loadConfig()
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(RightPanelTab.allCases) { tab in
                let isActive = tab == activeTab
                HStack(spacing: Spacing.xs) {
                    Image(systemName: tab.icon)
                        .font(.system(size: Typography.captionSize))
                    Text(tab.label)
                        .font(.system(size: Typography.captionSize))
                        .lineLimit(1)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 4)
                .background(isActive
                    ? Color.accentColor.opacity(0.15)
                    : hoveredTab == tab ? Color.primary.opacity(0.06) : Color.clear)
                .cornerRadius(Radii.sm)
                .onTapGesture {
                    activeTab = tab
                }
                .onHover { hovering in
                    hoveredTab = hovering ? tab : nil
                }
            }

            Spacer()

            Button(action: {
                appState.showingPreviewSettingsSheet = true
            }) {
                Image(systemName: "gearshape")
                    .font(.system(size: Typography.captionSize))
            }
            .buttonStyle(.plain)
            .padding(.trailing, Spacing.sm)
            .help("Configurações do Preview")
        }
        .frame(height: 28)
        .background(Color(nsColor: .controlBackgroundColor))
        .padding(.horizontal, Spacing.xs)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch activeTab {
        case .preview:
            PreviewTabView(project: project, previewConfig: previewConfig)
        case .files:
            FilesCodeTabView(project: project)
        case .git:
            GitTabView(project: project)
        }
    }

    // MARK: - Config

    private func loadConfig() {
        let service = ProjectService(modelContext: modelContext)
        previewConfig = service.readPreviewConfig(from: project)
    }
}
