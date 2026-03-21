import SwiftUI

struct ProfileChangesConfirmationSheet: View {
    let originalName: String
    let newName: String
    let originalDayOfBirth: Date
    let newDayOfBirth: Date
    let originalLanguage: String
    let newLanguage: String
    var onConfirm: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    private var nameChanged: Bool {
        newName.trimmingCharacters(in: .whitespaces) != originalName.trimmingCharacters(in: .whitespaces)
    }

    private var dobChanged: Bool {
        !Calendar.current.isDate(newDayOfBirth, inSameDayAs: originalDayOfBirth)
    }

    private var languageChanged: Bool {
        newLanguage != originalLanguage
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            dragHandle

            iconBadge

            Text(Strings.Profile.confirmUpdateTitle)
                .font(Typography.h5)
                .foregroundStyle(AppColors.grey900)
                .multilineTextAlignment(.center)

            changesGrid

            VStack(spacing: Spacing.sm) {
                Button {
                    onConfirm()
                    dismiss()
                } label: {
                    Text(Strings.Profile.saveChanges)
                        .font(Typography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(AppColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Button {
                    dismiss()
                } label: {
                    Text(Strings.Common.cancel)
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

    // MARK: - Subviews

    private var dragHandle: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(AppColors.grey300)
            .frame(width: 40, height: 4)
            .padding(.top, Spacing.sm)
    }

    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(AppColors.primary50)
                .frame(width: 64, height: 64)

            Image(systemName: AppIcon.pencil.systemName)
                .font(.system(size: 28))
                .foregroundStyle(AppColors.primary600)
        }
    }

    private var changesGrid: some View {
        VStack(spacing: 0) {
            fieldRow(
                label: Strings.Profile.name,
                oldValue: originalName,
                newValue: newName,
                changed: nameChanged
            )

            Divider()

            fieldRow(
                label: Strings.Profile.dateOfBirth,
                oldValue: originalDayOfBirth.formatted(date: .abbreviated, time: .omitted),
                newValue: newDayOfBirth.formatted(date: .abbreviated, time: .omitted),
                changed: dobChanged
            )

            Divider()

            fieldRow(
                label: Strings.Profile.language,
                oldValue: displayLanguage(originalLanguage),
                newValue: displayLanguage(newLanguage),
                changed: languageChanged
            )
        }
        .background(AppColors.grey50)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func fieldRow(label: String, oldValue: String, newValue: String, changed: Bool) -> some View {
        HStack {
            Text(label)
                .font(Typography.caption)
                .foregroundStyle(AppColors.grey500)
                .frame(width: 80, alignment: .trailing)

            if changed {
                HStack(spacing: Spacing.xs) {
                    Text(oldValue)
                        .font(Typography.footnote)
                        .foregroundStyle(AppColors.error)
                        .strikethrough()

                    Image(systemName: "arrow.left")
                        .font(.system(size: 10))
                        .foregroundStyle(AppColors.grey400)

                    Text(newValue)
                        .font(Typography.footnote)
                        .foregroundStyle(AppColors.success)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
            } else {
                Text(oldValue)
                    .font(Typography.footnote)
                    .foregroundStyle(AppColors.grey700)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    private func displayLanguage(_ code: String) -> String {
        code == "ar" ? Strings.Profile.arabic : Strings.Profile.english
    }
}
