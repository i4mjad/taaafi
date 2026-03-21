import SwiftUI
import FirebaseAuth

struct DataErrorReportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ToastManager.self) private var toastManager
    @State var viewModel: DataErrorReportViewModel

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.md) {
                if viewModel.isLoadingExisting {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.hasExistingReport {
                    existingReportView
                    Spacer()
                } else {
                    reportFormView
                }
            }
            .padding(Spacing.md)
            .background(AppColors.background)
            .navigationTitle(Strings.Vault.reportDataError)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) { dismiss() }
                }
            }
            .task {
                await viewModel.checkExistingReport()
            }
        }
    }

    private var existingReportView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "clock.fill")
                .font(.system(size: 36))
                .foregroundStyle(AppColors.warning)

            Text(Strings.Vault.existingReportFound)
                .font(Typography.h6)
                .foregroundStyle(AppColors.grey700)
                .multilineTextAlignment(.center)

            Text(Strings.Vault.existingReportDesc)
                .font(Typography.footnote)
                .foregroundStyle(AppColors.grey500)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var reportFormView: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(Strings.Vault.describeIssue)
                .font(Typography.footnote)
                .foregroundStyle(AppColors.grey600)

            TextEditor(text: $viewModel.reportText)
                .font(Typography.body)
                .frame(minHeight: 120)
                .padding(Spacing.xs)
                .background(AppColors.grey50)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColors.grey200, lineWidth: 1)
                )

            HStack {
                Text("\(viewModel.reportText.count)/220")
                    .font(Typography.small)
                    .foregroundStyle(viewModel.reportText.count > 220 ? AppColors.error : AppColors.grey400)
                Spacer()
            }

            if let error = viewModel.error {
                Text(error)
                    .font(Typography.small)
                    .foregroundStyle(AppColors.error)
            }

            Spacer()

            Button {
                Task {
                    let success = await viewModel.submitReport()
                    if success {
                        toastManager.show(.success, message: Strings.Vault.reportSubmitted)
                        dismiss()
                    }
                }
            } label: {
                Group {
                    if viewModel.isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Text(Strings.Vault.submitReport)
                    }
                }
                .font(Typography.h6)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(
                    viewModel.canSubmit ? AppColors.primary : AppColors.grey300
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(!viewModel.canSubmit || viewModel.isSubmitting)
        }
    }
}
