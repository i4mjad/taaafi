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

    @Test("thin weight maps to ExpoArabic-Light (fallback)")
    func thinMapsToLight() {
        #expect(AppFont.fontName(for: .thin) == "ExpoArabic-Light")
    }

    @Test("extraLight weight maps to ExpoArabic-Light (fallback)")
    func extraLightMapsToLight() {
        #expect(AppFont.fontName(for: .extraLight) == "ExpoArabic-Light")
    }

    @Test("light weight maps to ExpoArabic-Light")
    func lightMapsToLight() {
        #expect(AppFont.fontName(for: .light) == "ExpoArabic-Light")
    }

    @Test("regular weight maps to ExpoArabic-Book")
    func regularMapsToBook() {
        #expect(AppFont.fontName(for: .regular) == "ExpoArabic-Book")
    }

    @Test("book weight maps to ExpoArabic-Medium")
    func bookMapsToMedium() {
        #expect(AppFont.fontName(for: .book) == "ExpoArabic-Medium")
    }

    @Test("medium weight maps to ExpoArabic-SemiBold")
    func mediumMapsToSemiBold() {
        #expect(AppFont.fontName(for: .medium) == "ExpoArabic-SemiBold")
    }

    @Test("semiBold weight maps to ExpoArabic-Bold")
    func semiBoldMapsToBold() {
        #expect(AppFont.fontName(for: .semiBold) == "ExpoArabic-Bold")
    }

    @Test("bold weight maps to ExpoArabic-Bold (capped)")
    func boldMapsToBold() {
        #expect(AppFont.fontName(for: .bold) == "ExpoArabic-Bold")
    }

    // MARK: - Font Creation

    @Test("custom returns a Font for valid weight and size")
    func customReturnsFont() {
        let font = AppFont.custom(size: 16, weight: .book)
        #expect(font != nil)
    }
}
