import SwiftUI
import Charts

struct StreakPeriodsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: StreakPeriodsViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented control
                Picker("", selection: $viewModel.displayMode) {
                    Text(Strings.Vault.periodSummary).tag(StreakPeriodsDisplayMode.summary)
                    Text(Strings.Vault.periodDetails).tag(StreakPeriodsDisplayMode.detailed)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)

                Divider()

                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: Spacing.md) {
                            chartSection
                            statsRow
                            periodsList
                        }
                        .padding(Spacing.md)
                    }
                }
            }
            .background(AppColors.background)
            .navigationTitle(Strings.Vault.streakPeriods)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppColors.grey600)
                    }
                }
            }
            .task {
                await viewModel.loadPeriods()
            }
        }
    }

    // MARK: - Chart

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(Strings.Vault.streakPeriodsDesc)
                .font(Typography.caption)
                .foregroundStyle(AppColors.grey600)

            if viewModel.chartPoints.isEmpty {
                Text(Strings.Vault.noFollowUps)
                    .font(Typography.footnote)
                    .foregroundStyle(AppColors.grey400)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                Chart {
                    ForEach(viewModel.chartPoints, id: \.index) { point in
                        LineMark(
                            x: .value("Period", point.index),
                            y: .value("Days", point.duration)
                        )
                        .foregroundStyle(colorForType(viewModel.followUpType))
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Period", point.index),
                            y: .value("Days", point.duration)
                        )
                        .foregroundStyle(
                            .linearGradient(
                                colors: [colorForType(viewModel.followUpType).opacity(0.3), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Period", point.index),
                            y: .value("Days", point.duration)
                        )
                        .foregroundStyle(colorForType(viewModel.followUpType))
                        .symbolSize(30)
                    }

                    // Average line
                    if viewModel.averageDuration > 0 {
                        RuleMark(y: .value("Average", viewModel.averageDuration))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                            .foregroundStyle(AppColors.grey400)
                            .annotation(position: .top, alignment: .trailing) {
                                Text(String(format: "%.0f", viewModel.averageDuration))
                                    .font(Typography.small)
                                    .foregroundStyle(AppColors.grey500)
                            }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5))
                }
                .frame(height: 200)
            }
        }
        .padding(Spacing.md)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppColors.grey200, lineWidth: 0.5)
        )
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: Spacing.sm) {
            statCard(
                label: Strings.Vault.totalPeriods,
                value: "\(viewModel.totalPeriods)",
                color: colorForType(viewModel.followUpType)
            )
            statCard(
                label: Strings.Vault.averageDuration,
                value: String(format: "%.1f", viewModel.averageDuration),
                color: AppColors.primary
            )
            statCard(
                label: Strings.Vault.longestStreak,
                value: "\(viewModel.maxDuration)",
                color: AppColors.success
            )
        }
    }

    private func statCard(label: String, value: String, color: Color) -> some View {
        VStack(spacing: Spacing.xxs) {
            Text(value)
                .font(Typography.h5)
                .foregroundStyle(color)
            Text(label)
                .font(Typography.small)
                .foregroundStyle(AppColors.grey500)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Periods List

    private var periodsList: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(viewModel.displayMode == .summary ? Strings.Vault.periodSummary : Strings.Vault.periodDetails)
                .font(Typography.h6)
                .foregroundStyle(AppColors.grey700)

            ForEach(viewModel.periods.reversed()) { period in
                periodRow(period)
            }
        }
    }

    private func periodRow(_ period: StreakPeriod) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                if viewModel.displayMode == .detailed {
                    Text("\(period.startDate.formatted(date: .abbreviated, time: .omitted)) - \(period.endDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(Typography.caption)
                        .foregroundStyle(AppColors.grey700)
                } else {
                    Text(period.startDate.formatted(date: .abbreviated, time: .omitted))
                        .font(Typography.caption)
                        .foregroundStyle(AppColors.grey700)
                }
            }

            Spacer()

            Text("\(period.durationDays) \(Strings.Vault.days)")
                .font(Typography.caption)
                .fontWeight(.semibold)
                .foregroundStyle(colorForType(period.followUpType))
        }
        .padding(Spacing.sm)
        .background(AppColors.grey50)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Helpers

    private func colorForType(_ type: FollowUpType) -> Color {
        switch type {
        case .relapse: return AppColors.success
        case .pornOnly: return .purple
        case .mastOnly: return .orange
        case .slipUp: return AppColors.error
        case .none: return AppColors.grey500
        }
    }
}
