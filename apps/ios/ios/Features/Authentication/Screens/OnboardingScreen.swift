import SwiftUI

/// 5-step onboarding carousel shown to first-time users
struct OnboardingScreen: View {
    @Environment(AnalyticsFacade.self) private var analytics

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentStep = 0

    private let steps: [(icon: String, titleKey: String, descriptionKey: String)] = [
        ("lock.fill", "onboarding.step1Title", "onboarding.step1Description"),
        ("dumbbell.fill", "onboarding.step2Title", "onboarding.step2Description"),
        ("list.bullet.clipboard", "onboarding.step3Title", "onboarding.step3Description"),
        ("bell.fill", "onboarding.step4Title", "onboarding.step4Description"),
        ("shield.lefthalf.filled", "onboarding.step5Title", "onboarding.step5Description"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentStep) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    stepView(icon: step.icon, titleKey: step.titleKey, descriptionKey: step.descriptionKey)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            bottomSection
        }
        .background(AppColors.background)
        .task {
            analytics.trackOnboardingStart()
        }
    }

    // MARK: - Step View

    private func stepView(icon: String, titleKey: String, descriptionKey: String) -> some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(AppColors.primary)

            Text(String(localized: String.LocalizationValue(titleKey)))
                .font(Typography.h4)
                .multilineTextAlignment(.center)

            Text(String(localized: String.LocalizationValue(descriptionKey)))
                .font(Typography.body)
                .foregroundStyle(AppColors.grey500)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxl)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Bottom Section

    private var bottomSection: some View {
        VStack(spacing: Spacing.md) {
            Button {
                HapticService.lightImpact()
                hasCompletedOnboarding = true
                analytics.trackOnboardingFinish()
            } label: {
                Text(String(localized: "onboarding.getStarted"))
                    .font(Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(AppColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10.5, style: .continuous))
            }

            Button {
                HapticService.lightImpact()
                hasCompletedOnboarding = true
            } label: {
                Text(String(localized: "onboarding.signIn"))
                    .font(Typography.footnote)
                    .foregroundStyle(AppColors.primary)
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.bottom, Spacing.xxl)
    }
}
