import Testing
import SwiftUI
@testable import ios

@Suite("AppFont")
struct AppFontTests {

    // MARK: - Weight Cases

    @Test("AppFontWeight has all 8 cases")
    func allWeightCases() {
        let cases = AppFontWeight.allCases
        #expect(cases.count == 8)
    }

    // MARK: - Font Name Mapping

    @Test("thin weight maps to Thin font")
    func thinMapToThin() {
        #expect(AppFont.fontName(for: .thin) == "IBMPlexSansArabic-Thin")
    }

    @Test("extraLight weight maps to ExtraLight font")
    func extraLightMapsToExtraLight() {
        #expect(AppFont.fontName(for: .extraLight) == "IBMPlexSansArabic-ExtraLight")
    }

    @Test("light weight maps to Light font")
    func lightMapsToLight() {
        #expect(AppFont.fontName(for: .light) == "IBMPlexSansArabic-Light")
    }

    @Test("regular weight maps to Regular font")
    func regularMapsToRegular() {
        #expect(AppFont.fontName(for: .regular) == "IBMPlexSansArabic-Regular")
    }

    @Test("book weight maps to Medium font")
    func bookMapsToMedium() {
        #expect(AppFont.fontName(for: .book) == "IBMPlexSansArabic-Medium")
    }

    @Test("medium weight maps to SemiBold font")
    func mediumMapsToSemiBold() {
        #expect(AppFont.fontName(for: .medium) == "IBMPlexSansArabic-SemiBold")
    }

    @Test("semiBold weight maps to Bold font")
    func semiBoldMapsToBold() {
        #expect(AppFont.fontName(for: .semiBold) == "IBMPlexSansArabic-Bold")
    }

    @Test("bold weight maps to Bold font (capped)")
    func boldMapsToBold() {
        #expect(AppFont.fontName(for: .bold) == "IBMPlexSansArabic-Bold")
    }

    // MARK: - Font Creation

    @Test("custom returns a Font for valid weight and size")
    func customReturnsFont() {
        let font = AppFont.custom(size: 16, weight: .book)
        #expect(font != nil)
    }
}
