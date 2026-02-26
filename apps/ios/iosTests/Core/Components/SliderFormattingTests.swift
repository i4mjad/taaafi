import Testing
@testable import ios

@Suite("AppSlider formatting and snapping")
struct SliderFormattingTests {

    @Test("Default formatter shows integer")
    @MainActor
    func defaultFormatter() {
        var value = 5.0
        let slider = AppSlider(value: .constant(value), range: 0...10)
        #expect(slider.formattedValue == "5")
    }

    @Test("Custom formatter is used")
    @MainActor
    func customFormatter() {
        let slider = AppSlider(
            value: .constant(0.5),
            range: 0...1,
            valueFormatter: { "\(Int($0 * 100))%" }
        )
        #expect(slider.formattedValue == "50%")
    }

    @Test("Snap to divisions rounds to nearest step")
    func snapToNearest() {
        // 10 divisions in 0...1 means steps of 0.1
        let snapped = AppSlider.snapToDiv(0.34, in: 0...1, divisions: 10)
        #expect(abs(snapped - 0.3) < 0.001)
    }

    @Test("Snap clamps to range bounds")
    func snapClamps() {
        let snapped = AppSlider.snapToDiv(1.5, in: 0...1, divisions: 4)
        #expect(snapped == 1.0)
    }

    @Test("Snap with zero divisions returns original value")
    func snapZeroDivisions() {
        let snapped = AppSlider.snapToDiv(0.37, in: 0...1, divisions: 0)
        #expect(snapped == 0.37)
    }

    @Test("Snap in custom range")
    func snapCustomRange() {
        // 5 divisions in 0...100 means steps of 20
        let snapped = AppSlider.snapToDiv(47.0, in: 0...100, divisions: 5)
        #expect(abs(snapped - 40.0) < 0.001)
    }
}
