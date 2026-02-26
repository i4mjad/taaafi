import Testing
import Foundation
@testable import ios

@Suite("AppDatePicker date constraint validation")
struct DatePickerLogicTests {

    private let past = Date(timeIntervalSince1970: 1_000_000)
    private let future = Date(timeIntervalSince1970: 2_000_000_000)
    private let mid = Date(timeIntervalSince1970: 1_000_000_000)

    @Test("Returns current date when within range")
    func withinRange() {
        let result = AppDatePicker.getValidInitialDate(
            first: past,
            last: future,
            current: mid
        )
        #expect(result == mid)
    }

    @Test("Clamps to first date when current is before range")
    func beforeRange() {
        let result = AppDatePicker.getValidInitialDate(
            first: mid,
            last: future,
            current: past
        )
        #expect(result == mid)
    }

    @Test("Clamps to last date when current is after range")
    func afterRange() {
        let result = AppDatePicker.getValidInitialDate(
            first: past,
            last: mid,
            current: future
        )
        #expect(result == mid)
    }

    @Test("Returns now when current is nil and no constraints")
    func nilCurrentNoConstraints() {
        let before = Date()
        let result = AppDatePicker.getValidInitialDate(
            first: nil,
            last: nil,
            current: nil
        )
        let after = Date()
        #expect(result >= before && result <= after)
    }

    @Test("Returns current when no constraints specified")
    func noConstraints() {
        let result = AppDatePicker.getValidInitialDate(
            first: nil,
            last: nil,
            current: mid
        )
        #expect(result == mid)
    }
}
