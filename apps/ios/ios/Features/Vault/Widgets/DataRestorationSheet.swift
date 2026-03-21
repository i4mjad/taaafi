import SwiftUI

struct DataRestorationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: DataRestorationViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.md) {
                if viewModel.isAnalyzing {
                    Spacer()
                    ProgressView()
                    Text(Strings.Vault.analyzingData)
                        .font(Typography.footnote)
                        .foregroundStyle(AppColors.grey500)
                    Spacer()
                } else if viewModel.needsRestoration {
                    statusView
                    Spacer()
                    restoreButton
                } else {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(AppColors.success)
                    Text(Strings.Vault.dataUpToDate)
                        .font(Typography.h6)
                        .foregroundStyle(AppColors.grey700)
                    Spacer()
                }
            }
            .padding(Spacing.md)
            .background(AppColors.background)
            .navigationTitle(Strings.Vault.dataRestoration)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) { dismiss() }
                }
            }
            .task {
                await viewModel.analyzeMigrationStatus()
            }
        }
    }

    private var statusView: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(AppColors.warning)
                Text(Strings.Vault.migrationNeeded)
                    .font(Typography.h6)
                    .foregroundStyle(AppColors.grey800)
            }

            if let status = viewModel.migrationStatus {
                Text(status)
                    .font(Typography.footnote)
                    .foregroundStyle(AppColors.grey600)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(AppColors.warning.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var restoreButton: some View {
        Button {
            Task {
                await viewModel.performRestoration()
                if viewModel.error == nil {
                    dismiss()
                }
            }
        } label: {
            Group {
                if viewModel.isRestoring {
                    ProgressView().tint(.white)
                } else {
                    Text(Strings.Vault.restoreData)
                }
            }
            .font(Typography.h6)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(AppColors.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .disabled(viewModel.isRestoring)
    }
}
