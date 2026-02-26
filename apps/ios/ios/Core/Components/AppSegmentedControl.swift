import SwiftUI

struct SegmentOption<T: Hashable>: Identifiable {
    let id = UUID()
    let value: T
    let label: String
}

struct AppSegmentedControl<T: Hashable>: View {
    @Binding var selection: T
    let options: [SegmentOption<T>]
    var label: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if let label {
                Text(label)
                    .font(Typography.caption)
                    .foregroundStyle(AppColors.grey600)
            }

            Picker("", selection: $selection) {
                ForEach(options) { option in
                    Text(option.label).tag(option.value)
                }
            }
            .pickerStyle(.segmented)
            .tint(AppColors.primary)
        }
    }
}
