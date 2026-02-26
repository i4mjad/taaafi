import SwiftUI

struct AppTextArea: View {
    @Binding var text: String
    let label: String
    var icon: String?
    var maxLength: Int = 220
    var maxLines: Int = 6
    var validator: ((String) -> String?)?

    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(Typography.caption)
                .foregroundStyle(AppColors.grey600)

            HStack(alignment: .top, spacing: Spacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(AppColors.grey900)
                        .padding(.top, Spacing.xs)
                }

                TextField("", text: $text, axis: .vertical)
                    .font(Typography.body)
                    .lineLimit(1...maxLines)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
            .background(AppColors.background)
            .clipShape(RoundedRectangle(cornerRadius: 10.5, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10.5, style: .continuous)
                    .stroke(errorMessage != nil ? AppColors.error : AppColors.grey300, lineWidth: 1)
            )

            HStack {
                if let errorMessage {
                    Text(errorMessage)
                        .font(Typography.small)
                        .foregroundStyle(AppColors.error)
                }

                Spacer()

                Text("\(text.count)/\(maxLength)")
                    .font(Typography.small)
                    .foregroundStyle(isOverLimit ? AppColors.error : AppColors.grey500)
            }
        }
        .onChange(of: text) { _, newValue in
            if newValue.count > maxLength {
                text = String(newValue.prefix(maxLength))
            }
            errorMessage = validator?(text)
        }
    }

    var isOverLimit: Bool {
        text.count > maxLength
    }

    var characterCount: Int {
        text.count
    }
}
