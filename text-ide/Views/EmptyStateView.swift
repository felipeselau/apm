import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actions: [EmptyStateAction] = []

    struct EmptyStateAction: Identifiable {
        let id = UUID()
        let title: String
        let handler: () -> Void
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.system(size: Typography.headingSize, weight: .medium))
                .foregroundStyle(.secondary)
            Text(message)
                .font(.system(size: Typography.bodySize))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if !actions.isEmpty {
                HStack {
                    ForEach(actions) { action in
                        Button(action.title) { action.handler() }
                    }
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
    }
}
