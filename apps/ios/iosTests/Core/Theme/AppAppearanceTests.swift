import Testing
import UIKit
@testable import ios

@Suite("AppAppearance")
@MainActor
struct AppAppearanceTests {

    // MARK: - Navigation Bar

    @Test("configureNavigationBar sets large title font to 34pt Regular")
    func largeTitleFont() {
        AppAppearance.configureNavigationTitleFonts()

        let appearance = UINavigationBar.appearance().standardAppearance
        let attrs = appearance.largeTitleTextAttributes
        let font = attrs[.font] as? UIFont

        #expect(font != nil)
        #expect(font?.pointSize == 34)
        #expect(font?.fontName == AppFont.fontName(for: .regular))
    }

    @Test("configureNavigationBar sets inline title font to 17pt SemiBold")
    func inlineTitleFont() {
        AppAppearance.configureNavigationTitleFonts()

        let appearance = UINavigationBar.appearance().standardAppearance
        let attrs = appearance.titleTextAttributes
        let font = attrs[.font] as? UIFont

        #expect(font != nil)
        #expect(font?.pointSize == 17)
        #expect(font?.fontName == AppFont.fontName(for: .medium))
    }

    @Test("configureNavigationBar sets back button font to 17pt Regular")
    func backButtonFont() {
        AppAppearance.configureNavigationTitleFonts()

        let appearance = UINavigationBar.appearance().standardAppearance
        let attrs = appearance.backButtonAppearance.normal.titleTextAttributes
        let font = attrs[.font] as? UIFont

        #expect(font != nil)
        #expect(font?.pointSize == 17)
        #expect(font?.fontName == AppFont.fontName(for: .regular))
    }

    @Test("configureNavigationBar sets scroll edge appearance")
    func scrollEdgeAppearance() {
        AppAppearance.configureNavigationTitleFonts()

        let scrollEdge = UINavigationBar.appearance().scrollEdgeAppearance
        #expect(scrollEdge != nil)

        let font = scrollEdge?.largeTitleTextAttributes[.font] as? UIFont
        #expect(font?.pointSize == 34)
    }

    // MARK: - Tab Bar

    @Test("configureTabBar sets normal item font to 10pt Regular")
    func tabBarNormalFont() {
        AppAppearance.configureTabBar()

        let appearance = UITabBar.appearance().standardAppearance
        let attrs = appearance.stackedLayoutAppearance.normal.titleTextAttributes
        let font = attrs[.font] as? UIFont

        #expect(font != nil)
        #expect(font?.pointSize == 10)
        #expect(font?.fontName == AppFont.fontName(for: .regular))
    }

    @Test("configureTabBar sets selected item font to 10pt Regular")
    func tabBarSelectedFont() {
        AppAppearance.configureTabBar()

        let appearance = UITabBar.appearance().standardAppearance
        let attrs = appearance.stackedLayoutAppearance.selected.titleTextAttributes
        let font = attrs[.font] as? UIFont

        #expect(font != nil)
        #expect(font?.pointSize == 10)
        #expect(font?.fontName == AppFont.fontName(for: .regular))
    }

    @Test("configureTabBar sets scroll edge appearance")
    func tabBarScrollEdge() {
        AppAppearance.configureTabBar()

        let scrollEdge = UITabBar.appearance().scrollEdgeAppearance
        #expect(scrollEdge != nil)
    }

    // MARK: - Configure All

    @Test("configure sets both navigation bar and tab bar appearances")
    func configureAll() {
        AppAppearance.configure()

        // Navigation bar was configured
        let navAppearance = UINavigationBar.appearance().standardAppearance
        let navFont = navAppearance.largeTitleTextAttributes[.font] as? UIFont
        #expect(navFont != nil)

        // Tab bar was configured
        let tabAppearance = UITabBar.appearance().standardAppearance
        let tabFont = tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes[.font] as? UIFont
        #expect(tabFont != nil)
    }
}
