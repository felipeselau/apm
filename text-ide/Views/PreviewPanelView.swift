import SwiftUI

struct PreviewPanelView: View {
    var body: some View {
        VStack(spacing: Spacing.md) {
            Spacer()
            Image(systemName: "rectangle.dashed")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Preview")
                .font(.system(size: Typography.headingSize, weight: .medium))
            Text("Em breve")
                .font(.system(size: Typography.bodySize))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
    }
}
