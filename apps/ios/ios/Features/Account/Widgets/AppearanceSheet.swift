import SwiftUI

struct AppearanceSheet: View {
    @State private var selectedTheme: String = UserDefaults.standard.string(forKey: "appTheme") ?? "light"
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Text(Strings.Profile.appearance)
                .font(Typography.h6)
                .foregroundStyle(AppColors.grey900)

            Picker(Strings.Profile.appearance, selection: $selectedTheme) {
                Text(Strings.Profile.lightMode).tag("light")
                Text(Strings.Profile.darkMode).tag("dark")
            }
            .pickerStyle(.segmented)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppColors.grey50)
        .presentationDetents([.height(200)])
        .onChange(of: selectedTheme) { _, newValue in
            UserDefaults.standard.set(newValue, forKey: "appTheme")
            AppAppearance.applyTheme(newValue)
        }
    }
}
