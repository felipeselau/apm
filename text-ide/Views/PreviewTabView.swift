import SwiftUI
import SwiftData
import WebKit

// MARK: - WKWebView Representable

private struct WebView: NSViewRepresentable {
    enum NavigationAction {
        case goBack
        case goForward
        case reload
    }

    let urlText: String
    let previewConfig: PreviewConfig?
    let modelContext: ModelContext
    @Binding var pendingAction: WebView.NavigationAction?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        loadURL(in: webView)
        context.coordinator.lastLoadedURL = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        context.coordinator.isAutoRefreshEnabled = previewConfig?.autoRefresh == true
        context.coordinator.startAutoRefresh(webView: webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        if let action = pendingAction {
            switch action {
            case .goBack: webView.goBack()
            case .goForward: webView.goForward()
            case .reload: webView.reload()
            }
            DispatchQueue.main.async {
                pendingAction = nil
            }
        }

        let urlString = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        if urlString != context.coordinator.lastLoadedURL {
            loadURL(in: webView)
            context.coordinator.lastLoadedURL = urlString
        }

        let shouldAutoRefresh = previewConfig?.autoRefresh == true
        if shouldAutoRefresh != context.coordinator.isAutoRefreshEnabled {
            context.coordinator.isAutoRefreshEnabled = shouldAutoRefresh
            if shouldAutoRefresh {
                context.coordinator.startAutoRefresh(webView: webView)
            } else {
                context.coordinator.stopAutoRefresh()
            }
        }
    }

    private func loadURL(in webView: WKWebView) {
        let urlString = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !urlString.isEmpty,
              let url = URL(string: urlString.hasPrefix("http") ? urlString : "https://" + urlString)
        else { return }
        webView.load(URLRequest(url: url))
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var lastLoadedURL: String?
        var isAutoRefreshEnabled: Bool = false
        private var autoRefreshTimer: Timer?

        func startAutoRefresh(webView: WKWebView) {
            stopAutoRefresh()
            autoRefreshTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak webView] _ in
                webView?.reload()
            }
        }

        func stopAutoRefresh() {
            autoRefreshTimer?.invalidate()
            autoRefreshTimer = nil
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            if let currentURL = webView.url, url.host == currentURL.host {
                decisionHandler(.allow)
                return
            }

            if navigationAction.navigationType == .linkActivated {
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }

        deinit {
            autoRefreshTimer?.invalidate()
        }
    }
}

// MARK: - Preview Tab View

struct PreviewTabView: View {
    let project: Project
    let previewConfig: PreviewConfig?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @State private var urlText: String = ""
    @State private var viewportWidth: CGFloat? = nil
    @State private var projectType: ProjectType = .unknown
    @State private var commands: [ProjectCommand] = []
    @State private var previewRunner = PreviewRunner()
    @State private var pendingNavigationAction: WebView.NavigationAction? = nil
    @State private var terminalExpanded: Bool = true
    @State private var showingRestartAlert: Bool = false
    @State private var pendingCommand: ProjectCommand? = nil

    private let viewportSizes: [String: CGFloat] = [
        "desktop": 0,
        "tablet": 768,
        "mobile": 375
    ]

    var body: some View {
        VStack(spacing: 0) {
            addressBar
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(Color(nsColor: .controlBackgroundColor))

            if !commands.isEmpty || projectType != .unknown {
                controlsBar
            }

            if hasURL {
                webViewContainer
            } else {
                emptyState
            }

            if previewRunner.isRunning || !previewRunner.output.isEmpty {
                terminalSection
            }
        }
        .onAppear {
            urlText = previewConfig?.url ?? ""
            detectProject()
        }
        .onChange(of: previewRunner.detectedURL) { _, newURL in
            if let url = newURL, !url.isEmpty {
                urlText = url
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                previewRunner.stop()
            }
        }
        .alert("Comando em execução", isPresented: $showingRestartAlert) {
            Button("Parar e executar") {
                if let cmd = pendingCommand {
                    previewRunner.stop()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        previewRunner.run(command: cmd.command, in: project.folderURL, commandId: cmd.id)
                    }
                }
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Um comando já está em execução. Deseja pará-lo e executar este?")
        }
    }

    private var hasURL: Bool {
        !urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Project Detection

    private func detectProject() {
        projectType = ProjectDetector.detectType(at: project.folderURL)
        try? ProjectService(modelContext: modelContext).updateProjectType(for: project, type: projectType)
        commands = ProjectDetector.detectCommands(at: project.folderURL, type: projectType)
    }

    // MARK: - Address Bar

    private var addressBar: some View {
        HStack(spacing: Spacing.xs) {
            Button(action: { pendingNavigationAction = .goBack }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: Typography.captionSize))
            }
            .buttonStyle(.plain)
            .help("Voltar")

            Button(action: { pendingNavigationAction = .goForward }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: Typography.captionSize))
            }
            .buttonStyle(.plain)
            .help("Avançar")

            Button(action: { pendingNavigationAction = .reload }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: Typography.captionSize))
            }
            .buttonStyle(.plain)
            .help("Recarregar")

            TextField("http://localhost:5173", text: $urlText)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: Typography.bodySize))
                .onSubmit {
                    loadURL()
                }
        }
    }

    // MARK: - Controls Bar

    private var controlsBar: some View {
        HStack(spacing: Spacing.sm) {
            Text(projectType.rawValue.capitalized)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.2))
                .cornerRadius(Radii.sm)
                .font(.system(size: Typography.captionSize))

            ForEach(commands) { cmd in
                let isRunning = previewRunner.isRunning
                let isCurrentCommand = previewRunner.currentCommand == cmd.id

                Button(action: {
                    if isRunning && isCurrentCommand {
                        previewRunner.stop()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            previewRunner.run(command: cmd.command, in: project.folderURL, commandId: cmd.id)
                        }
                    } else if isRunning {
                        showingRestartAlert = true
                        pendingCommand = cmd
                    } else {
                        previewRunner.run(command: cmd.command, in: project.folderURL, commandId: cmd.id)
                    }
                }) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: isCurrentCommand && isRunning ? "arrow.clockwise" : cmd.icon)
                            .font(.system(size: Typography.captionSize))
                        Text(cmd.name)
                            .font(.system(size: Typography.captionSize))
                    }
                }
                .buttonStyle(.plain)
            }

            if previewRunner.isRunning {
                Button(action: {
                    previewRunner.stop()
                }) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: Typography.captionSize))
                        Text("Parar")
                            .font(.system(size: Typography.captionSize))
                    }
                    .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - Terminal Section

    private var terminalSection: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { terminalExpanded.toggle() }) {
                    Image(systemName: terminalExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: Typography.captionSize))
                }
                .buttonStyle(.plain)

                Text(previewRunner.currentCommand ?? "npm run dev")
                    .font(.system(size: Typography.captionSize, weight: .medium))

                Spacer()

                Circle()
                    .fill(previewRunner.isRunning ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)

                Text(previewRunner.isRunning ? "running" : "stopped")
                    .font(.system(size: Typography.captionSize))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(Color(nsColor: .controlBackgroundColor))
            .onTapGesture { terminalExpanded.toggle() }

            if terminalExpanded {
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(previewRunner.output.enumerated()), id: \.offset) { index, line in
                            Text(line)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(line.contains("error") ? .red : .primary)
                        }
                    }
                    .padding(Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 150)
                .background(Color(nsColor: .textBackgroundColor))
            }
        }
    }

    // MARK: - WebView

    private var webViewContainer: some View {
        GeometryReader { geometry in
            let containerWidth = geometry.size.width
            let wvWidth: CGFloat = {
                guard let viewport = previewConfig?.viewport,
                      let size = viewportSizes[viewport],
                      size > 0
                else { return containerWidth }
                return min(size, containerWidth)
            }()

            HStack {
                Spacer()
                WebView(
                    urlText: urlText,
                    previewConfig: previewConfig,
                    modelContext: modelContext,
                    pendingAction: $pendingNavigationAction
                )
                .frame(width: wvWidth)
                .id("webView")
                Spacer()
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            icon: "safari",
            title: "Preview",
            message: "Configure a URL de preview nas configurações"
        )
    }

    // MARK: - Actions

    private func loadURL() {
        let trimmed = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !trimmed.hasPrefix("http://") && !trimmed.hasPrefix("https://") {
            urlText = "https://" + trimmed
        }
    }
}
