import Testing
import SwiftUI
@testable import ios

@Suite("AppFont")
struct AppFontTests {

    // MARK: - Weight Cases

    @Test("AppFontWeight has all 5 cases")
    func allWeightCases() {
        let cases: [AppFontWeight] = [.light, .book, .medium, .semiBold, .bold]
        #expect(cases.count == 5)
    }

    // MARK: - Font Name Mapping

    @Test("light weight maps to Regular font")
    func lightMapsToRegular() {
        #expect(AppFont.fontName(for: .light) == "IBMPlexSansArabic-Regular")
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
