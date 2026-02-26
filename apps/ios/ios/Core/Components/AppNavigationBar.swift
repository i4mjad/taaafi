import SwiftUI

struct AppNavigationBar: ViewModifier {
    let title: LocalizedStringKey
    var showLocaleToggle: Bool = false
    var trailing: (() -> AnyView)?

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .toolbar {
                if let trailing {
                    ToolbarItem(placement: .topBarTrailing) {
                        trailing()
                    }
                }
            }
    }
}

extension View {
    func appNavigationBar(
        title: LocalizedStringKey,
        showLocaleToggle: Bool = false,
        trailing: (() -> AnyView)? = nil
    ) -> some View {
        modifier(AppNavigationBar(
            title: title,
            showLocaleToggle: showLocaleToggle,
            trailing: trailing
        ))
    }
}
