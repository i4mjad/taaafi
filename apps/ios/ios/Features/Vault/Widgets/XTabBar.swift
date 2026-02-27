import SwiftUI

struct XTabBar<Tab: Hashable & Identifiable>: View {
    let tabs: [Tab]
    @Binding var selectedTab: Tab
    let label: (Tab) -> String
    let icon: (Tab) -> String
    let color: (Tab) -> Color

    @Namespace private var underline

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.lg) {
                ForEach(tabs) { tab in
                    tabButton(for: tab)
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .padding(.vertical, Spacing.xs)
        .background(AppColors.background)
    }

    private func tabButton(for tab: Tab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: Spacing.xs) {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: icon(tab))
                        .font(.system(size: 14))
                    Text(label(tab))
                        .font(Typography.footnote)
                }
                .foregroundStyle(isSelected ? color(tab) : AppColors.grey500)

                if isSelected {
                    Capsule()
                        .fill(color(tab))
                        .frame(height: 3)
                        .matchedGeometryEffect(id: "underline", in: underline)
                } else {
                    Capsule()
                        .fill(Color.clear)
                        .frame(height: 3)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
