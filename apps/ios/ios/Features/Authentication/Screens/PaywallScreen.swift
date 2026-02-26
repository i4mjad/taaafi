import SwiftUI

/// Simple paywall screen shown after registration, before entering the main app
struct PaywallScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showComingSoon = false

    private let features: [(icon: String, titleKey: String)] = [
        ("star.fill", "paywall.feature1"),
        ("chart.bar.fill", "paywall.feature2"),
        ("bell.badge.fill", "paywall.feature3"),
        ("lock.shield.fill", "paywall.feature4"),
        ("person.2.fill", "paywall.feature5"),
    ]

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Branding
            VStack(spacing: Spacing.md) {
                Image(AppIcon.plusIconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)

                Text(String(localized: "paywall.title"))
                    .font(Typography.h4)

                Text(String(localized: "paywall.subtitle"))
                    .font(Typography.body)
                    .foregroundStyle(AppColors.grey500)
                    .multilineTextAlignment(.center)
            }

            // Feature list
            VStack(alignment: .leading, spacing: Spacing.md) {
                ForEach(features, id: \.icon) { feature in
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: feature.icon)
                            .font(.system(size: 16))
                            .foregroundStyle(AppColors.primary)
                            .frame(width: 24)

                        Text(String(localized: String.LocalizationValue(feature.titleKey)))
                            .font(Typography.body)
                    }
                }
            }
            .padding(.horizontal, Spacing.xl)

            Spacer()

            // Subscribe button
            Button {
                HapticService.lightImpact()
                showComingSoon = true
            } label: {
                Text(String(localized: "paywall.subscribe"))
                    .font(Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(AppColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10.5, style: .continuous))
            }

            // Maybe later
            Button {
                HapticService.lightImpact()
                dismiss()
            } label: {
                Text(String(localized: "paywall.maybeLater"))
                    .font(Typography.footnote)
                    .foregroundStyle(AppColors.grey500)
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.bottom, Spacing.xxl)
        .background(AppColors.background)
        .navigationBarBackButtonHidden(true)
        .alert(String(localized: "paywall.comingSoon"), isPresented: $showComingSoon) {
            Button(String(localized: "common.ok"), role: .cancel) {}
        } message: {
            Text(String(localized: "paywall.comingSoonMessage"))
        }
    }
}
