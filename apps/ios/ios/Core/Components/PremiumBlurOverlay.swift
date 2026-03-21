import SwiftUI

struct PremiumBlurOverlay<Content: View>: View {
    let content: Content
    var customTitle: String?
    var customSubtitle: String?
    var onTap: () -> Void = {}

    init(
        customTitle: String? = nil,
        customSubtitle: String? = nil,
        onTap: @escaping () -> Void = {},
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.customTitle = customTitle
        self.customSubtitle = customSubtitle
        self.onTap = onTap
    }

    @Environment(\.colorScheme) private var colorScheme

    private let goldColor = Color(red: 254/255, green: 186/255, blue: 1/255)

    var body: some View {
        ZStack {
            content
                .blur(radius: 4)

            overlayGradient

            upgradePrompt
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .frame(minHeight: 120, maxHeight: 280)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }

    private var overlayGradient: some View {
        LinearGradient(
            stops: [
                .init(color: overlayBase.opacity(0.25), location: 0),
                .init(color: overlayBase.opacity(0.55), location: 0.35),
                .init(color: overlayBase.opacity(0.85), location: 0.65),
                .init(color: overlayBase.opacity(0.65), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var overlayBase: Color {
        colorScheme == .dark ? .black : .white
    }

    private var upgradePrompt: some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                Circle()
                    .fill(goldColor)
                    .frame(width: 50, height: 50)

                Image(AppIcon.plusIconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.white)
            }

            Text(customTitle ?? Strings.Premium.upgradeToPlus)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(goldColor)

            Text(customSubtitle ?? Strings.Premium.unlockAnalytics)
                .font(Typography.caption)
                .foregroundStyle(AppColors.grey500)
        }
    }
}
