import SwiftUI

enum AppFontWeight: CaseIterable {
    case thin       // → ExpoArabic-Light (fallback)
    case extraLight // → ExpoArabic-Light (fallback)
    case light      // → ExpoArabic-Light
    case regular    // → ExpoArabic-Book
    case book       // → ExpoArabic-Medium
    case medium     // → ExpoArabic-SemiBold
    case semiBold   // → ExpoArabic-Bold
    case bold       // → ExpoArabic-Bold (capped)
}

enum AppFont {

    static func fontName(for weight: AppFontWeight) -> String {
        switch weight {
        case .thin:       return "ExpoArabic-Light"
        case .extraLight: return "ExpoArabic-Light"
        case .light:      return "ExpoArabic-Light"
        case .regular:    return "ExpoArabic-Book"
        case .book:       return "ExpoArabic-Medium"
        case .medium:     return "ExpoArabic-SemiBold"
        case .semiBold:   return "ExpoArabic-Bold"
        case .bold:       return "ExpoArabic-Bold"
        }
    }

    static func custom(size: CGFloat, weight: AppFontWeight) -> Font {
        .custom(fontName(for: weight), size: size)
    }
}
