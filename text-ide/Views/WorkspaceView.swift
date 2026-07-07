import SwiftUI

struct WorkspaceView: View {
    let project: Project

    var body: some View {
        HSplitView {
            panelContainer(title: "Terminal") {
                TerminalView(project: project)
            }
            .frame(minWidth: 300)

            panelContainer(title: "Preview") {
                PreviewPanelView()
            }
            .frame(minWidth: 200)
        }
    }

    @ViewBuilder
    private func panelContainer<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: Typography.captionSize, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color(nsColor: .controlBackgroundColor))

            content()
        }
    }
}
