import SwiftUI

struct ActionItem: Identifiable {
    let id = UUID()
    var icon: String?
    let title: String
    var subtitle: String?
    var onTap: () -> Void = {}
    var isDestructive: Bool = false
}

struct ActionModal: View {
    let items: [ActionItem]
    var title: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            dragHandle

            if let title {
                Text(title)
                    .font(Typography.h6)
                    .foregroundStyle(AppColors.grey900)
                    .padding(.bottom, Spacing.md)
            }

            ForEach(items) { item in
                Button {
                    dismiss()
                    item.onTap()
                } label: {
                    itemRow(item)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.xl)
    }

    private var dragHandle: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(AppColors.grey300)
            .frame(width: 40, height: 4)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.md)
    }

    private func itemRow(_ item: ActionItem) -> some View {
        HStack(spacing: Spacing.md) {
            if let icon = item.icon {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(item.isDestructive ? AppColors.error50 : AppColors.grey100)
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(item.isDestructive ? AppColors.error600 : AppColors.grey700)
                }
            }

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(item.title)
                    .font(Typography.body)
                    .foregroundStyle(item.isDestructive ? AppColors.error600 : AppColors.grey900)

                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(Typography.caption)
                        .foregroundStyle(AppColors.grey500)
                }
            }

            Spacer()
        }
        .padding(.vertical, Spacing.xs)
    }

    static func show(items: [ActionItem], title: String? = nil) -> some View {
        ActionModal(items: items, title: title)
            .presentationDetents([.medium])
            .presentationDragIndicator(.hidden)
    }
}
