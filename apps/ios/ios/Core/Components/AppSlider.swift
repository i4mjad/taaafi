import SwiftUI

enum ValueDisplayPosition {
    case above
    case below
    case inline
}

struct AppSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    var label: String?
    var valueFormatter: ((Double) -> String)?
    var valueDisplay: ValueDisplayPosition = .inline
    var minLabel: String?
    var maxLabel: String?
    var divisions: Int?
    var step: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if let label {
                labelRow(label)
            }

            if valueDisplay == .above {
                formattedValueText
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            sliderView

            if valueDisplay == .below {
                formattedValueText
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            if minLabel != nil || maxLabel != nil {
                HStack {
                    if let minLabel {
                        Text(minLabel)
                            .font(Typography.caption)
                            .foregroundStyle(AppColors.grey500)
                    }
                    Spacer()
                    if let maxLabel {
                        Text(maxLabel)
                            .font(Typography.caption)
                            .foregroundStyle(AppColors.grey500)
                    }
                }
            }
        }
    }

    private func labelRow(_ label: String) -> some View {
        HStack {
            Text(label)
                .font(Typography.body)
                .foregroundStyle(AppColors.grey900)

            if valueDisplay == .inline {
                Spacer()
                formattedValueText
            }
        }
    }

    private var formattedValueText: some View {
        Text(formattedValue)
            .font(Typography.h6)
            .foregroundStyle(AppColors.primary)
    }

    private var sliderView: some View {
        Group {
            if let step {
                Slider(value: $value, in: range, step: step) { _ in
                    HapticService.selectionClick()
                }
            } else {
                Slider(value: $value, in: range) { _ in
                    HapticService.selectionClick()
                }
            }
        }
        .tint(AppColors.primary)
        .onChange(of: value) { _, newValue in
            if let divisions {
                value = snapToDiv(newValue, divisions: divisions)
            }
        }
    }

    var formattedValue: String {
        valueFormatter?(value) ?? String(format: "%.0f", value)
    }

    static func snapToDiv(_ value: Double, in range: ClosedRange<Double> = 0...1, divisions: Int) -> Double {
        guard divisions > 0 else { return value }
        let step = (range.upperBound - range.lowerBound) / Double(divisions)
        let snapped = (((value - range.lowerBound) / step).rounded()) * step + range.lowerBound
        return min(max(snapped, range.lowerBound), range.upperBound)
    }

    private func snapToDiv(_ value: Double, divisions: Int) -> Double {
        Self.snapToDiv(value, in: range, divisions: divisions)
    }
}
