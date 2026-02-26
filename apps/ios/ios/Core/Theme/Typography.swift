import SwiftUI

enum Typography {

    // MARK: - Headings

    static let h1Size: CGFloat = 40
    static let h1Weight: AppFontWeight = .semiBold
    static var h1: Font { AppFont.custom(size: h1Size, weight: h1Weight) }

    static let h2Size: CGFloat = 30
    static let h2Weight: AppFontWeight = .semiBold
    static var h2: Font { AppFont.custom(size: h2Size, weight: h2Weight) }

    static let h3Size: CGFloat = 28
    static let h3Weight: AppFontWeight = .semiBold
    static var h3: Font { AppFont.custom(size: h3Size, weight: h3Weight) }

    static let h4Size: CGFloat = 24
    static let h4Weight: AppFontWeight = .semiBold
    static var h4: Font { AppFont.custom(size: h4Size, weight: h4Weight) }

    static let h5Size: CGFloat = 21
    static let h5Weight: AppFontWeight = .semiBold
    static var h5: Font { AppFont.custom(size: h5Size, weight: h5Weight) }

    static let h6Size: CGFloat = 16
    static let h6Weight: AppFontWeight = .semiBold
    static var h6: Font { AppFont.custom(size: h6Size, weight: h6Weight) }

    // MARK: - Body

    static let bodyLargeSize: CGFloat = 18
    static let bodyLargeWeight: AppFontWeight = .book
    static var bodyLarge: Font { AppFont.custom(size: bodyLargeSize, weight: bodyLargeWeight) }

    static let bodySize: CGFloat = 16
    static let bodyWeight: AppFontWeight = .book
    static var body: Font { AppFont.custom(size: bodySize, weight: bodyWeight) }

    // MARK: - Small Styles

    static let footnoteSize: CGFloat = 14
    static let footnoteWeight: AppFontWeight = .book
    static var footnote: Font { AppFont.custom(size: footnoteSize, weight: footnoteWeight) }

    static let captionSize: CGFloat = 13
    static let captionWeight: AppFontWeight = .book
    static var caption: Font { AppFont.custom(size: captionSize, weight: captionWeight) }

    static let smallSize: CGFloat = 12
    static let smallWeight: AppFontWeight = .book
    static var small: Font { AppFont.custom(size: smallSize, weight: smallWeight) }

    static let bodyTinySize: CGFloat = 10
    static let bodyTinyWeight: AppFontWeight = .medium
    static var bodyTiny: Font { AppFont.custom(size: bodyTinySize, weight: bodyTinyWeight) }

    // MARK: - Screen Heading

    static let screenHeadingSize: CGFloat = 28
    static let screenHeadingWeight: AppFontWeight = .bold
    static var screenHeading: Font { AppFont.custom(size: screenHeadingSize, weight: screenHeadingWeight) }
}
