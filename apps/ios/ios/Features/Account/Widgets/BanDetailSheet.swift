import SwiftUI

struct BanDetailSheet: View {
    let ban: Ban
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                dragHandle

                headerSection

                detailsSection

                if ban.scope == .feature_specific, let features = ban.restrictedFeatures, !features.isEmpty {
                    restrictedFeaturesSection(features)
                }

                if let related = ban.relatedContent {
                    relatedContentSection(related)
                }

                appealInfo
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xl)
        }
    }

    private var dragHandle: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(AppColors.grey300)
            .frame(width: 40, height: 4)
            .padding(.top, Spacing.sm)
    }

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(AppColors.error50)
                    .frame(width: 64, height: 64)

                Image(systemName: AppIcon.shieldExclamation.systemName)
                    .font(.system(size: 28))
                    .foregroundStyle(AppColors.error600)
            }

            Text(Strings.Profile.banDetail)
                .font(Typography.h5)
                .foregroundStyle(AppColors.grey900)

            HStack(spacing: Spacing.xs) {
                badgeCapsule(
                    text: ban.scope == .app_wide ? Strings.Ban.scopeAppWide : Strings.Ban.scopeFeature,
                    color: ban.scope == .app_wide ? AppColors.error600 : AppColors.warning600
                )
                badgeCapsule(
                    text: banTypeLabel,
                    color: AppColors.grey600
                )
            }
        }
    }

    private func badgeCapsule(text: String, color: Color) -> some View {
        Text(text)
            .font(Typography.small)
            .fontWeight(.semibold)
            .foregroundStyle(color)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxs)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }

    private var detailsSection: some View {
        VStack(spacing: Spacing.sm) {
            detailRow(label: Strings.Ban.reason, value: ban.reason)
            if let desc = ban.description {
                detailRow(label: Strings.Ban.description, value: desc)
            }
            detailRow(label: Strings.Ban.duration, value: durationText)
            detailRow(label: Strings.Ban.issuedDate, value: ban.issuedAt.formatted(date: .abbreviated, time: .omitted))
            if let expiresAt = ban.expiresAt {
                detailRow(label: Strings.Ban.expiresOn, value: expiresAt.formatted(date: .abbreviated, time: .omitted))
            }
            detailRow(label: Strings.Ban.banId, value: ban.id)
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Typography.footnote)
                .foregroundStyle(AppColors.grey500)
            Spacer()
            Text(value)
                .font(Typography.footnote)
                .foregroundStyle(AppColors.grey800)
                .multilineTextAlignment(.trailing)
        }
    }

    private func restrictedFeaturesSection(_ features: [String]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(Strings.Profile.restrictedFeatures)
                .font(Typography.h6)
                .foregroundStyle(AppColors.grey900)

            FlowLayout(spacing: Spacing.xs) {
                ForEach(features, id: \.self) { feature in
                    Text(feature)
                        .font(Typography.small)
                        .foregroundStyle(AppColors.error600)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, Spacing.xxs)
                        .background(AppColors.error50)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private func relatedContentSection(_ content: RelatedContent) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(Strings.Profile.relatedContent)
                .font(Typography.h6)
                .foregroundStyle(AppColors.grey900)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                if let title = content.title {
                    Text(title)
                        .font(Typography.footnote)
                        .foregroundStyle(AppColors.grey800)
                }
                Text("Type: \(content.type)")
                    .font(Typography.small)
                    .foregroundStyle(AppColors.grey600)
            }
            .padding(Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.primary50)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private var appealInfo: some View {
        Text(Strings.Ban.appealInfo)
            .font(Typography.small)
            .foregroundStyle(AppColors.grey500)
            .multilineTextAlignment(.center)
            .padding(.top, Spacing.sm)
    }

    // MARK: - Computed

    private var banTypeLabel: String {
        switch ban.type {
        case .user_ban: Strings.Ban.typeUser
        case .device_ban: Strings.Ban.typeDevice
        case .feature_ban: Strings.Ban.typeFeature
        }
    }

    private var durationText: String {
        guard let expiresAt = ban.expiresAt else { return Strings.Ban.permanent }
        if ban.isExpired { return Strings.Ban.expired }
        let components = Calendar.current.dateComponents([.day, .hour], from: Date(), to: expiresAt)
        if let days = components.day, days > 0 {
            return "\(days) \(days == 1 ? Strings.Ban.day : Strings.Ban.days)"
        }
        if let hours = components.hour, hours > 0 {
            return "\(hours) \(hours == 1 ? Strings.Ban.hour : Strings.Ban.hours)"
        }
        return Strings.Ban.expired
    }
}

// MARK: - FlowLayout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            totalHeight = y + rowHeight
        }

        return (positions, CGSize(width: maxWidth, height: totalHeight))
    }
}
