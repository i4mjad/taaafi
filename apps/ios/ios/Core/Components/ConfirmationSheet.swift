import SwiftUI

struct ConfirmationSheet: View {
    let icon: String
    let title: String
    let message: String
    var confirmLabel: String?
    var cancelLabel: String?
    var isDestructive: Bool = false
    var onConfirm: () -> Void = {}
    var onCancel: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Spacing.lg) {
            dragHandle

            iconBadge

            Text(title)
                .font(Typography.h5)
                .foregroundStyle(AppColors.grey900)
                .multilineTextAlignment(.center)

            Text(message)
                .font(Typography.body)
                .foregroundStyle(AppColors.grey500)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.md)

            VStack(spacing: Spacing.sm) {
                Button {
                    onConfirm()
                    dismiss()
                } label: {
                    Text(confirmLabel ?? Strings.Common.confirm)
                        .font(Typography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(isDestructive ? AppColors.error : AppColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Button {
                    onCancel()
                    dismiss()
                } label: {
                    Text(cancelLabel ?? Strings.Common.cancel)
                        .font(Typography.body)
                        .foregroundStyle(AppColors.grey600)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(AppColors.grey100)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.bottom, Spacing.xl)
    }

    private var dragHandle: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(AppColors.grey300)
            .frame(width: 40, height: 4)
            .padding(.top, Spacing.sm)
    }

    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(isDestructive ? AppColors.error50 : AppColors.primary50)
                .frame(width: 64, height: 64)

            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(isDestructive ? AppColors.error600 : AppColors.primary600)
        }
    }
}

struct ConfirmationModifier: ViewModifier {
    @Binding var isPresented: Bool
    let icon: String
    let title: String
    let message: String
    var confirmLabel: String?
    var cancelLabel: String?
    var isDestructive: Bool = false
    var onResult: (Bool) -> Void = { _ in }

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            ConfirmationSheet(
                icon: icon,
                title: title,
                message: message,
                confirmLabel: confirmLabel,
                cancelLabel: cancelLabel,
                isDestructive: isDestructive,
                onConfirm: { onResult(true) },
                onCancel: { onResult(false) }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.hidden)
        }
    }
}

extension View {
    func confirmationSheet(
        isPresented: Binding<Bool>,
        icon: String,
        title: String,
        message: String,
        confirmLabel: String? = nil,
        cancelLabel: String? = nil,
        isDestructive: Bool = false,
        onResult: @escaping (Bool) -> Void = { _ in }
    ) -> some View {
        modifier(ConfirmationModifier(
            isPresented: isPresented,
            icon: icon,
            title: title,
            message: message,
            confirmLabel: confirmLabel,
            cancelLabel: cancelLabel,
            isDestructive: isDestructive,
            onResult: onResult
        ))
    }
}
