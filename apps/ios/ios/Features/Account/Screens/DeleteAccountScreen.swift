import SwiftUI

struct DeleteAccountScreen: View {
    var body: some View {
        Text(Strings.Profile.deleteAccount)
            .font(Typography.h4)
            .foregroundStyle(AppColors.grey500)
            .navigationTitle(Strings.Profile.deleteAccountTitle)
            .navigationBarTitleDisplayMode(.inline)
    }
}
