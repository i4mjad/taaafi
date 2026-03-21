import SwiftUI
import ShadowKit

struct CardShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(AppColors.grey200, lineWidth: 0.75)
            )
            .proShadow(
                color: Color.black.opacity(0.05),
                radius: 4,
                opacity: 0.2,
                x: 0,
                y: 2
            )
    }
}

extension View {
    func cardShadow() -> some View {
        modifier(CardShadow())
    }
}
