import Testing
import Foundation
@testable import ios

@Suite("ToastVariant")
struct ToastVariantTests {

    @Test("Info variant uses info icon")
    func infoIcon() {
        #expect(ToastVariant.info.icon == "info.circle")
    }

    @Test("Error variant uses alert circle icon")
    func errorIcon() {
        #expect(ToastVariant.error.icon == "exclamationmark.circle")
    }

    @Test("Success variant uses check icon")
    func successIcon() {
        #expect(ToastVariant.success.icon == "checkmark")
    }

    @Test("System variant uses info icon")
    func systemIcon() {
        #expect(ToastVariant.system.icon == "info.circle")
    }

    @Test("Ban variant uses shield off icon")
    func banIcon() {
        #expect(ToastVariant.ban.icon == "shield.slash")
    }

    @Test("Ban auto-dismiss is 5 seconds")
    func banAutoDismiss() {
        #expect(ToastVariant.ban.autoDismissSeconds == 5)
    }

    @Test("Non-ban variants auto-dismiss in 3 seconds")
    func defaultAutoDismiss() {
        let nonBan: [ToastVariant] = [.info, .error, .success, .system]
        for variant in nonBan {
            #expect(variant.autoDismissSeconds == 3)
        }
    }
}

@Suite("ToastMessage")
struct ToastMessageTests {

    @Test("Equatable compares by id")
    func equalityById() {
        let id = UUID()
        let a = ToastMessage(id: id, variant: .info, message: "Hello")
        let b = ToastMessage(id: id, variant: .error, message: "Different")
        #expect(a == b)
    }

    @Test("Different ids are not equal")
    func differentIds() {
        let a = ToastMessage(variant: .info, message: "Hello")
        let b = ToastMessage(variant: .info, message: "Hello")
        #expect(a != b)
    }
}
