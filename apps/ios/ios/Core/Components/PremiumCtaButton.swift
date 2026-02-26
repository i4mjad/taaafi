import SwiftUI

struct PremiumCtaButton: View {
    let isSubscribed: Bool
    var onTap: () -> Void = {}

    private let goldColor = Color(red: 254/255, green: 186/255, blue: 1/255)

    var body: some View {
        Button {
            onTap()
        } label: {
            Image(AppIcon.plusIconName)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .foregroundStyle(isSubscribed ? AppColors.success600 : goldColor)
        }
    }
}
