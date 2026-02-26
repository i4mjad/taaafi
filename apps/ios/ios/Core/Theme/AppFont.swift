import SwiftUI

enum AppFontWeight: CaseIterable {
    case thin       // w100 → Thin
    case extraLight // w200 → ExtraLight
    case light      // w300 → Light
    case regular    // w400 → Regular
    case book       // w500 → Medium
    case medium     // w600 → SemiBold
    case semiBold   // w700 → Bold
    case bold       // w700 → Bold (same file, IBM Plex caps at Bold)
}

enum AppFont {

    static func fontName(for weight: AppFontWeight) -> String {
        switch weight {
        case .thin:       return "IBMPlexSansArabic-Thin"
        case .extraLight: return "IBMPlexSansArabic-ExtraLight"
        case .light:      return "IBMPlexSansArabic-Light"
        case .regular:    return "IBMPlexSansArabic-Regular"
        case .book:       return "IBMPlexSansArabic-Medium"
        case .medium:     return "IBMPlexSansArabic-SemiBold"
        case .semiBold:   return "IBMPlexSansArabic-Bold"
        case .bold:       return "IBMPlexSansArabic-Bold"
        }
    }

    static func custom(size: CGFloat, weight: AppFontWeight) -> Font {
        .custom(fontName(for: weight), size: size)
    }
}
