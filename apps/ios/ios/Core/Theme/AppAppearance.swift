import UIKit

@MainActor
enum AppAppearance {

    static func configure() {
        configureNavigationTitleFonts()
        configureTabBar()
    }

    static func configureNavigationTitleFonts() {
        let largeTitleFont = UIFont(name: AppFont.fontName(for: .regular), size: 34)
            ?? .systemFont(ofSize: 34)
        let inlineTitleFont = UIFont(name: AppFont.fontName(for: .medium), size: 17)
            ?? .boldSystemFont(ofSize: 17)
        let buttonFont = UIFont(name: AppFont.fontName(for: .regular), size: 17)
            ?? .systemFont(ofSize: 17)

        let navBar = UINavigationBar.appearance()

        let buttonAppearance = UIBarButtonItemAppearance()
        buttonAppearance.normal.titleTextAttributes = [.font: buttonFont]
        buttonAppearance.highlighted.titleTextAttributes = [.font: buttonFont]

        let standard = (navBar.standardAppearance.copy() as? UINavigationBarAppearance) ?? UINavigationBarAppearance()
        standard.largeTitleTextAttributes[.font] = largeTitleFont
        standard.titleTextAttributes[.font] = inlineTitleFont
        standard.buttonAppearance = buttonAppearance
        standard.doneButtonAppearance = buttonAppearance

        let compact = (navBar.compactAppearance?.copy() as? UINavigationBarAppearance) ?? standard
        compact.largeTitleTextAttributes[.font] = largeTitleFont
        compact.titleTextAttributes[.font] = inlineTitleFont
        compact.buttonAppearance = buttonAppearance
        compact.doneButtonAppearance = buttonAppearance

        let scrollEdge = (navBar.scrollEdgeAppearance?.copy() as? UINavigationBarAppearance) ?? standard
        scrollEdge.largeTitleTextAttributes[.font] = largeTitleFont
        scrollEdge.titleTextAttributes[.font] = inlineTitleFont
        scrollEdge.buttonAppearance = buttonAppearance
        scrollEdge.doneButtonAppearance = buttonAppearance

        navBar.standardAppearance = standard
        navBar.compactAppearance = compact
        navBar.scrollEdgeAppearance = scrollEdge
    }

    static func applySavedTheme() {
        let theme = UserDefaults.standard.string(forKey: "appTheme") ?? "light"
        applyTheme(theme)
    }

    static func applyTheme(_ theme: String) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        let style: UIUserInterfaceStyle = switch theme {
        case "dark": .dark
        case "light": .light
        default: .unspecified
        }
        for window in scene.windows {
            window.overrideUserInterfaceStyle = style
        }
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
