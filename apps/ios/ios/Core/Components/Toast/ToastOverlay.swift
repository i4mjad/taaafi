import SwiftUI

struct ToastOverlay: ViewModifier {
    @Environment(ToastManager.self) private var toastManager

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            VStack(spacing: Spacing.xs) {
                ForEach(toastManager.toasts) { toast in
                    toastView(for: toast)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.top, Spacing.xl)
            .padding(.horizontal, Spacing.md)
            .animation(.spring(duration: 0.3), value: toastManager.toasts.map(\.id))
        }
    }

    private func toastView(for toast: ToastMessage) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: toast.variant.icon)
                .font(.system(size: 18))
                .foregroundStyle(toast.variant.iconColor)

            Text(toast.message)
                .font(Typography.caption)
                .foregroundStyle(toast.variant.textColor)
                .lineLimit(2)

            Spacer(minLength: 0)

            if let actionLabel = toast.actionLabel {
                Button(actionLabel) {
                    toast.action?()
                    toastManager.dismiss(toast)
                }
                .font(Typography.caption)
                .fontWeight(.semibold)
                .foregroundStyle(toast.variant.iconColor)
            }

            Button {
                toastManager.dismiss(toast)
            } label: {
                Image(systemName: AppIcon.xmark.systemName)
                    .font(.system(size: 12))
                    .foregroundStyle(toast.variant.textColor.opacity(0.6))
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(toast.variant.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(toast.variant.borderColor, lineWidth: 2)
        )
    }
}

extension View {
    func toastOverlay() -> some View {
        modifier(ToastOverlay())
    }
}
