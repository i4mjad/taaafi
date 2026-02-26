import Testing
import Foundation
@testable import ios

@Suite("ConfirmDetailsViewModel")
@MainActor
struct ConfirmDetailsViewModelTests {

    // MARK: - Loading from Document

    @Test("loadFromDocument populates fields from document")
    func loadFromDocument() {
        let vm = ConfirmDetailsViewModel()
        let date = makeDate(year: 1995, month: 3, day: 15)
        let doc = UserDocument(
            displayName: "Ahmed",
            email: "ahmed@example.com",
            gender: "male",
            locale: "ar",
            dayOfBirth: date
        )

        vm.loadFromDocument(doc)

        #expect(vm.displayName == "Ahmed")
        #expect(vm.email == "ahmed@example.com")
        #expect(vm.gender == "male")
        #expect(vm.locale == "ar")
        #expect(vm.dayOfBirth == date)
        #expect(vm.isEmailDisabled)
        #expect(!vm.isLoading)
    }

    @Test("loadFromDocument sets defaults when fields are nil")
    func loadFromDocumentNilFields() {
        let vm = ConfirmDetailsViewModel()
        let doc = UserDocument()

        vm.loadFromDocument(doc)

        #expect(vm.displayName == "")
        #expect(vm.email == "")
        #expect(vm.gender == "male")
        #expect(vm.locale == "en")
        #expect(vm.dayOfBirth == nil)
        #expect(!vm.isEmailDisabled) // empty email means editable
        #expect(!vm.isLoading)
    }

    @Test("loadFromDocument with nil document stops loading")
    func loadFromNilDocument() {
        let vm = ConfirmDetailsViewModel()

        vm.loadFromDocument(nil)

        #expect(!vm.isLoading)
    }

    @Test("email is disabled when document has non-empty email")
    func emailDisabledWhenSet() {
        let vm = ConfirmDetailsViewModel()
        let doc = UserDocument(email: "test@example.com")

        vm.loadFromDocument(doc)

        #expect(vm.isEmailDisabled)
    }

    @Test("email is editable when document email is empty")
    func emailEditableWhenEmpty() {
        let vm = ConfirmDetailsViewModel()
        let doc = UserDocument(email: "")

        vm.loadFromDocument(doc)

        #expect(!vm.isEmailDisabled)
    }

    // MARK: - Validation

    @Test("validate returns true with valid name and DOB")
    func validateValid() {
        let vm = ConfirmDetailsViewModel()
        vm.displayName = "Ahmed"
        vm.dayOfBirth = makeDate(year: 2000, month: 1, day: 1)

        #expect(vm.validate())
    }

    @Test("validate returns false with empty name")
    func validateEmptyName() {
        let vm = ConfirmDetailsViewModel()
        vm.displayName = ""
        vm.dayOfBirth = makeDate(year: 2000, month: 1, day: 1)

        #expect(!vm.validate())
    }

    @Test("validate returns false with whitespace-only name")
    func validateWhitespaceName() {
        let vm = ConfirmDetailsViewModel()
        vm.displayName = "   "
        vm.dayOfBirth = makeDate(year: 2000, month: 1, day: 1)

        #expect(!vm.validate())
    }

    @Test("validate returns false with nil DOB")
    func validateNilDob() {
        let vm = ConfirmDetailsViewModel()
        vm.displayName = "Ahmed"
        vm.dayOfBirth = nil

        #expect(!vm.validate())
    }

    @Test("validate returns false with DOB after 2015-12-31")
    func validateDobTooRecent() {
        let vm = ConfirmDetailsViewModel()
        vm.displayName = "Ahmed"
        vm.dayOfBirth = makeDate(year: 2020, month: 1, day: 1)

        #expect(!vm.validate())
    }

    @Test("validate accepts DOB on 2015-12-31 boundary")
    func validateDobBoundary() {
        let vm = ConfirmDetailsViewModel()
        vm.displayName = "Ahmed"
        vm.dayOfBirth = makeDate(year: 2015, month: 12, day: 31)

        #expect(vm.validate())
    }

    // MARK: - Name Error

    @Test("nameError returns nil for empty name")
    func nameErrorEmpty() {
        let vm = ConfirmDetailsViewModel()
        vm.displayName = ""
        #expect(vm.nameError == nil)
    }

    @Test("nameError returns message for whitespace-only name")
    func nameErrorWhitespace() {
        let vm = ConfirmDetailsViewModel()
        vm.displayName = "   "
        #expect(vm.nameError != nil)
    }

    @Test("nameError returns nil for valid name")
    func nameErrorValid() {
        let vm = ConfirmDetailsViewModel()
        vm.displayName = "Ahmed"
        #expect(vm.nameError == nil)
    }
}

private func makeDate(year: Int, month: Int, day: Int) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    return Calendar.current.date(from: components) ?? Date()
}
