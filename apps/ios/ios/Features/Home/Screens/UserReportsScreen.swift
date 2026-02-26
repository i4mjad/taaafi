//
//  UserReportsScreen.swift
//  ios
//

import SwiftUI
import FirebaseAuth

struct UserReportsScreen: View {
    @Environment(ToastManager.self) private var toastManager
    @State private var viewModel: ReportsViewModel
    @State private var showNewReportSheet = false

    init(firestoreService: FirestoreService) {
        _viewModel = State(initialValue: ReportsViewModel(firestoreService: firestoreService))
    }

    private var userId: String? {
        Auth.auth().currentUser?.uid
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.reports.isEmpty {
                    loadingView
                } else if let error = viewModel.error, viewModel.reports.isEmpty {
                    errorView(error)
                } else if viewModel.reports.isEmpty {
                    emptyStateView
                } else {
                    reportsList
                }
            }
            .navigationTitle(String(localized: "reports.title"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewReportSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(AppColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showNewReportSheet) {
                NewReportSheet(viewModel: viewModel)
            }
            .refreshable {
                if let uid = userId {
                    await viewModel.loadReports(userId: uid)
                }
            }
            .task {
                if let uid = userId {
                    await viewModel.loadReports(userId: uid)
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            AppSpinner()
            Text(String(localized: "common.loading"))
                .font(Typography.footnote)
                .foregroundStyle(AppColors.grey500)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ error: Error) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: AppIcon.alertCircle.systemName)
                .font(.system(size: 40))
                .foregroundStyle(AppColors.error)

            Text(String(localized: "reports.errorLoading"))
                .font(Typography.body)
                .foregroundStyle(AppColors.grey700)

            Button {
                Task {
                    if let uid = userId {
                        await viewModel.loadReports(userId: uid)
                    }
                }
            } label: {
                Text(String(localized: "common.retry"))
                    .font(Typography.footnote)
                    .foregroundStyle(AppColors.primary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(AppColors.grey300)

            Text(String(localized: "reports.empty"))
                .font(Typography.body)
                .foregroundStyle(AppColors.grey500)

            Text(String(localized: "reports.emptySubtitle"))
                .font(Typography.footnote)
                .foregroundStyle(AppColors.grey400)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var reportsList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.sm) {
                ForEach(viewModel.reports) { report in
                    NavigationLink {
                        ReportConversationScreen(
                            report: report,
                            viewModel: viewModel
                        )
                    } label: {
                        reportCard(report)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
    }

    private func reportCard(_ report: UserReport) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                if let type = report.reportType {
                    Image(systemName: type.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.primary)
                }

                Text(report.reportType?.displayName ?? report.reportTypeId)
                    .font(Typography.footnote)
                    .foregroundStyle(AppColors.grey800)

                Spacer()

                statusBadge(report.status)
            }

            Text(report.initialMessage)
                .font(Typography.caption)
                .foregroundStyle(AppColors.grey600)
                .lineLimit(2)

            HStack {
                Text(report.lastUpdated, style: .relative)
                    .font(Typography.small)
                    .foregroundStyle(AppColors.grey400)

                Spacer()

                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "message")
                        .font(.system(size: 11))
                    Text("\(report.messagesCount)")
                        .font(Typography.small)
                }
                .foregroundStyle(AppColors.grey400)
            }
        }
        .padding(Spacing.md)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(AppColors.grey200, lineWidth: 1)
        )
    }

    private func statusBadge(_ status: ReportStatus) -> some View {
        Text(statusLabel(status))
            .font(Typography.bodyTiny)
            .foregroundStyle(statusForeground(status))
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, 2)
            .background(statusBackground(status))
            .clipShape(Capsule())
    }

    private func statusLabel(_ status: ReportStatus) -> String {
        switch status {
        case .pending: return String(localized: "report.status.pending")
        case .inProgress: return String(localized: "report.status.inProgress")
        case .waitingForAdminResponse: return String(localized: "report.status.waiting")
        case .closed: return String(localized: "report.status.closed")
        case .finalized: return String(localized: "report.status.finalized")
        }
    }

    private func statusForeground(_ status: ReportStatus) -> Color {
        switch status {
        case .pending: return AppColors.warning700
        case .inProgress: return AppColors.primary700
        case .waitingForAdminResponse: return AppColors.tint700
        case .closed: return AppColors.grey600
        case .finalized: return AppColors.success700
        }
    }

    private func statusBackground(_ status: ReportStatus) -> Color {
        switch status {
        case .pending: return AppColors.warning50
        case .inProgress: return AppColors.primary50
        case .waitingForAdminResponse: return AppColors.tint50
        case .closed: return AppColors.grey100
        case .finalized: return AppColors.success50
        }
    }
}

// MARK: - New Report Sheet

private struct NewReportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ToastManager.self) private var toastManager
    let viewModel: ReportsViewModel

    @State private var selectedType: ReportType?
    @State private var message = ""
    @State private var isSubmitting = false

    private var userId: String? {
        Auth.auth().currentUser?.uid
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "report.new.typeSection")) {
                    ForEach(ReportType.allCases) { type in
                        Button {
                            selectedType = type
                        } label: {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: type.icon)
                                    .font(.system(size: 16))
                                    .foregroundStyle(AppColors.primary)
                                    .frame(width: 28)

                                Text(type.displayName)
                                    .font(Typography.body)
                                    .foregroundStyle(AppColors.grey800)

                                Spacer()

                                if selectedType == type {
                                    Image(systemName: AppIcon.check.systemName)
                                        .foregroundStyle(AppColors.primary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section(String(localized: "report.new.messageSection")) {
                    AppTextArea(
                        text: $message,
                        label: String(localized: "report.new.messagePlaceholder"),
                        validator: { viewModel.validateMessage($0) }
                    )
                }
            }
            .navigationTitle(String(localized: "report.new.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        submitReport()
                    } label: {
                        if isSubmitting {
                            AppSpinner()
                        } else {
                            Text(String(localized: "report.new.submit"))
                                .font(Typography.footnote)
                        }
                    }
                    .disabled(selectedType == nil || message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                }
            }
        }
    }

    private func submitReport() {
        guard let type = selectedType, let uid = userId else { return }
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard viewModel.validateMessage(trimmedMessage) == nil else { return }

        isSubmitting = true
        Task {
            do {
                try await viewModel.createReport(userId: uid, type: type, message: trimmedMessage)
                toastManager.show(.success, message: String(localized: "report.new.success"))
                dismiss()
            } catch {
                toastManager.show(.error, message: String(localized: "report.new.error"))
            }
            isSubmitting = false
        }
    }
}
