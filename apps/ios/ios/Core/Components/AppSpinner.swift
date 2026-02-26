import SwiftUI

struct AppSpinner: View {
    var tint: Color?

    var body: some View {
        ProgressView()
            .tint(tint)
    }
}
