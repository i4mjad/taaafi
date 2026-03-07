import SwiftUI

struct ResetDataSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Text(Strings.Profile.resetData)
            .font(Typography.h4)
            .foregroundStyle(AppColors.grey500)
    }
}
