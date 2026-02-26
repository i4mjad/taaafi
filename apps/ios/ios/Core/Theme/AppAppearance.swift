import UIKit

@MainActor
enum AppAppearance {

    static func configure() {
        configureNavigationBar()
        configureTabBar()
    }

    static func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()

        // Large title: 34pt Regular (Apple HIG default)
        appearance.largeTitleTextAttributes = [
            .font: UIFont(name: AppFont.fontName(for: .regular), size: 34)
                   ?? .systemFont(ofSize: 34)
        ]

        // Inline title: 17pt SemiBold (Apple HIG default)
        appearance.titleTextAttributes = [
            .font: UIFont(name: AppFont.fontName(for: .medium), size: 17)
                   ?? .boldSystemFont(ofSize: 17)
        ]

        // Back button: 17pt Regular
        let buttonAppearance = UIBarButtonItemAppearance()
        buttonAppearance.normal.titleTextAttributes = [
            .font: UIFont(name: AppFont.fontName(for: .regular), size: 17)
                   ?? .systemFont(ofSize: 17)
        ]
        appearance.backButtonAppearance = buttonAppearance
        appearance.buttonAppearance = buttonAppearance

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    static func configureTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()

        let itemAppearance = UITabBarItemAppearance()

        // Tab bar label: 10pt Regular (Apple HIG iPhone default)
        let font = UIFont(name: AppFont.fontName(for: .regular), size: 10)
                   ?? .systemFont(ofSize: 10)

        itemAppearance.normal.titleTextAttributes = [.font: font]
        itemAppearance.selected.titleTextAttributes = [.font: font]

        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
