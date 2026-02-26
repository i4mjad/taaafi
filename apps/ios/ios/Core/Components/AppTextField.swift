import SwiftUI

struct AppTextField: View {
    @Binding var text: String
    let label: String
    var icon: String?
    var isSecure: Bool = false
    var maxLength: Int = 100
    var validator: ((String) -> String?)?
    var keyboardType: UIKeyboardType = .default
    var textCapitalization: TextInputAutocapitalization = .sentences

    @State private var errorMessage: String?
    @State private var isObscured: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(Typography.caption)
                .foregroundStyle(AppColors.grey600)

            HStack(spacing: Spacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(AppColors.grey900)
                }

                fieldView

                if isSecure {
                    Button {
                        isObscured.toggle()
                    } label: {
                        Image(systemName: isObscured ? AppIcon.eye.systemName : AppIcon.eyeOff.systemName)
                            .font(.system(size: 16))
                            .foregroundStyle(AppColors.grey500)
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
            .background(AppColors.background)
            .clipShape(RoundedRectangle(cornerRadius: 10.5, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10.5, style: .continuous)
                    .stroke(errorMessage != nil ? AppColors.error : AppColors.grey300, lineWidth: 1)
            )

            if let errorMessage {
                Text(errorMessage)
                    .font(Typography.small)
                    .foregroundStyle(AppColors.error)
            }
        }
        .onChange(of: text) { _, newValue in
            if newValue.count > maxLength {
                text = String(newValue.prefix(maxLength))
            }
            errorMessage = validator?(text)
        }
    }

    @ViewBuilder
    private var fieldView: some View {
        if isSecure && isObscured {
            SecureField("", text: $text)
                .font(Typography.body)
                .textInputAutocapitalization(textCapitalization)
        } else {
            TextField("", text: $text)
                .font(Typography.body)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(textCapitalization)
        }
    }

    var isOverLimit: Bool {
        text.count > maxLength
    }

    var characterCount: Int {
        text.count
    }
}
