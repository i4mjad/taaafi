import UIKit

@MainActor
enum AppAppearance {

    static func configure() {
        configureNavigationBar()
        configureTabBar()
    }

    static func configureNavigationBar() {
        let navBackground = UIColor(named: "Background") ?? UIColor.systemBackground

        let largeTitleFont = UIFont(name: AppFont.fontName(for: .regular), size: 34)
            ?? .systemFont(ofSize: 34)
        let inlineTitleFont = UIFont(name: AppFont.fontName(for: .medium), size: 17)
            ?? .boldSystemFont(ofSize: 17)
        let buttonFont = UIFont(name: AppFont.fontName(for: .regular), size: 17)
            ?? .systemFont(ofSize: 17)

        let buttonAppearance = UIBarButtonItemAppearance()
        buttonAppearance.normal.titleTextAttributes = [.font: buttonFont]

        // Standard appearance: shown when scrolled (inline title, with separator)
        let standard = UINavigationBarAppearance()
        standard.configureWithOpaqueBackground()
        standard.backgroundColor = navBackground
        standard.largeTitleTextAttributes = [.font: largeTitleFont]
        standard.titleTextAttributes = [.font: inlineTitleFont]
        standard.backButtonAppearance = buttonAppearance
        standard.buttonAppearance = buttonAppearance

        // Scroll-edge appearance: shown at top (large title, no separator)
        let scrollEdge = UINavigationBarAppearance()
        scrollEdge.configureWithOpaqueBackground()
        scrollEdge.backgroundColor = navBackground
        scrollEdge.shadowColor = .clear
        scrollEdge.largeTitleTextAttributes = [.font: largeTitleFont]
        scrollEdge.titleTextAttributes = [.font: inlineTitleFont]
        scrollEdge.backButtonAppearance = buttonAppearance
        scrollEdge.buttonAppearance = buttonAppearance

        UINavigationBar.appearance().standardAppearance = standard
        UINavigationBar.appearance().compactAppearance = standard
        UINavigationBar.appearance().scrollEdgeAppearance = scrollEdge
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
