import SwiftUI

struct WorkspaceView: View {
    let project: Project

    var body: some View {
        HSplitView {
            TerminalTabView(project: project)
                .frame(minWidth: 300)

            RightPanelView(project: project)
                .frame(minWidth: 200, idealWidth: 350)
        }
    }
}
