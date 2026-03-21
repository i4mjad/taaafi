import SwiftUI

struct PickerItem<T: Hashable>: Identifiable {
    let id = UUID()
    let value: T
    let label: String
}

enum PickerPresentationStyle {
    case menu
    case wheel
}

struct AppPicker<T: Hashable>: View {
    @Binding var selection: T
    let items: [PickerItem<T>]
    var label: String?
    var style: PickerPresentationStyle = .menu

    @State private var isWheelPresented = false

    var body: some View {
        Group {
            switch style {
            case .menu:
                menuPicker
            case .wheel:
                wheelButton
            }
        }
        .sheet(isPresented: $isWheelPresented) {
            wheelSheet
        }
    }

    private var menuPicker: some View {
        HStack {
            if let label {
                Text(label)
                    .font(Typography.body)
                    .foregroundStyle(AppColors.grey900)
            }

            Spacer()

            Picker("", selection: $selection) {
                ForEach(items) { item in
                    Text(item.label).tag(item.value)
                }
            }
            .tint(AppColors.primary)
        }
    }

    private var wheelButton: some View {
        Button {
            isWheelPresented = true
            HapticService.selectionClick()
        } label: {
            HStack {
                if let label {
                    Text(label)
                        .font(Typography.body)
                        .foregroundStyle(AppColors.grey900)
                }

                Spacer()

                Text(selectedLabel)
                    .font(Typography.body)
                    .foregroundStyle(AppColors.primary)

                Image(systemName: AppIcon.chevronForward.systemName)
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.grey400)
            }
        }
        .buttonStyle(.plain)
    }

    private var wheelSheet: some View {
        NavigationStack {
            Picker("", selection: $selection) {
                ForEach(items) { item in
                    Text(item.label).tag(item.value)
                }
            }
            .pickerStyle(.wheel)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.done) {
                        isWheelPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var selectedLabel: String {
        items.first { $0.value == selection }?.label ?? ""
    }
}
