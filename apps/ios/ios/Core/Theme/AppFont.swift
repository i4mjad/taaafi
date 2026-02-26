import SwiftUI

enum AppFontWeight: CaseIterable {
    case light    // w400 → Regular
    case book     // w500 → Medium
    case medium   // w600 → SemiBold
    case semiBold // w700 → Bold
    case bold     // w800 → Bold (capped)
}

enum AppFont {

    static func fontName(for weight: AppFontWeight) -> String {
        switch weight {
        case .light:    return "IBMPlexSansArabic-Regular"
        case .book:     return "IBMPlexSansArabic-Medium"
        case .medium:   return "IBMPlexSansArabic-SemiBold"
        case .semiBold: return "IBMPlexSansArabic-Bold"
        case .bold:     return "IBMPlexSansArabic-Bold"
        }
    }

    static func custom(size: CGFloat, weight: AppFontWeight) -> Font {
        .custom(fontName(for: weight), size: size)
    }
}
