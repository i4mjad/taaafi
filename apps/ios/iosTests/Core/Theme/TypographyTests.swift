import Testing
import SwiftUI
@testable import ios

@Suite("Typography")
struct TypographyTests {

    // MARK: - Heading Styles

    @Test("h1 uses size 40 and semiBold weight")
    func h1() {
        #expect(Typography.h1Size == 40)
        #expect(Typography.h1Weight == .semiBold)
    }

    @Test("h2 uses size 30 and semiBold weight")
    func h2() {
        #expect(Typography.h2Size == 30)
        #expect(Typography.h2Weight == .semiBold)
    }

    @Test("h3 uses size 28 and semiBold weight")
    func h3() {
        #expect(Typography.h3Size == 28)
        #expect(Typography.h3Weight == .semiBold)
    }

    @Test("h4 uses size 24 and semiBold weight")
    func h4() {
        #expect(Typography.h4Size == 24)
        #expect(Typography.h4Weight == .semiBold)
    }

    @Test("h5 uses size 21 and semiBold weight")
    func h5() {
        #expect(Typography.h5Size == 21)
        #expect(Typography.h5Weight == .semiBold)
    }

    @Test("h6 uses size 16 and semiBold weight")
    func h6() {
        #expect(Typography.h6Size == 16)
        #expect(Typography.h6Weight == .semiBold)
    }

    // MARK: - Body Styles

    @Test("bodyLarge uses size 18 and book weight")
    func bodyLarge() {
        #expect(Typography.bodyLargeSize == 18)
        #expect(Typography.bodyLargeWeight == .book)
    }

    @Test("body uses size 16 and book weight")
    func body() {
        #expect(Typography.bodySize == 16)
        #expect(Typography.bodyWeight == .book)
    }

    @Test("footnote uses size 14 and book weight")
    func footnote() {
        #expect(Typography.footnoteSize == 14)
        #expect(Typography.footnoteWeight == .book)
    }

    @Test("caption uses size 13 and book weight")
    func caption() {
        #expect(Typography.captionSize == 13)
        #expect(Typography.captionWeight == .book)
    }

    @Test("small uses size 12 and book weight")
    func small() {
        #expect(Typography.smallSize == 12)
        #expect(Typography.smallWeight == .book)
    }

    @Test("bodyTiny uses size 10 and medium weight")
    func bodyTiny() {
        #expect(Typography.bodyTinySize == 10)
        #expect(Typography.bodyTinyWeight == .medium)
    }

    @Test("screenHeading uses size 28 and bold weight")
    func screenHeading() {
        #expect(Typography.screenHeadingSize == 28)
        #expect(Typography.screenHeadingWeight == .bold)
    }

    // MARK: - Font Creation

    @Test("all styles return a Font")
    func allStylesReturnFont() {
        let fonts: [Font] = [
            Typography.h1, Typography.h2, Typography.h3,
            Typography.h4, Typography.h5, Typography.h6,
            Typography.bodyLarge, Typography.body,
            Typography.footnote, Typography.caption,
            Typography.small, Typography.bodyTiny,
            Typography.screenHeading
        ]
        #expect(fonts.count == 13)
    }
}
