import SwiftUI

struct UserProfileScreen: View {
    var body: some View {
        Text(Strings.Profile.profileDetails)
            .font(Typography.h4)
            .foregroundStyle(AppColors.grey500)
            .navigationTitle(Strings.Profile.profileDetails)
            .navigationBarTitleDisplayMode(.inline)
    }
}
