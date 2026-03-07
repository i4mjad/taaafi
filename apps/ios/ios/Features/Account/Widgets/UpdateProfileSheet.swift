import SwiftUI

struct UpdateProfileSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Text(Strings.Profile.updateProfile)
            .font(Typography.h4)
            .foregroundStyle(AppColors.grey500)
    }
}
