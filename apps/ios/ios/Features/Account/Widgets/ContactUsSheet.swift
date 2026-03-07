import SwiftUI

struct ContactUsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Text(Strings.Profile.contactUs)
            .font(Typography.h4)
            .foregroundStyle(AppColors.grey500)
    }
}
