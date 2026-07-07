import SwiftUI

struct ToastView: View {
    let toast: AppState.ToastMessage
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: iconName)
            Text(toast.message)
                .font(.system(size: Typography.bodySize))
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: Typography.captionSize))
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.md)
        .background(backgroundColor)
        .cornerRadius(Radii.md)
        .shadow(radius: 8)
        .padding(Spacing.md)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                onDismiss()
            }
        }
    }

    private var iconName: String {
        switch toast.type {
        case .error: return "exclamationmark.triangle.fill"
        case .success: return "checkmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }

    private var backgroundColor: Color {
        switch toast.type {
        case .error: return .red.opacity(0.9)
        case .success: return .green.opacity(0.9)
        case .info: return .blue.opacity(0.9)
        }
    }
}
