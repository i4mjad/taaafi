import Testing
import Foundation
@testable import ios

@Suite("UpdateProfileViewModel")
struct UpdateProfileViewModelTests {

    @Test("Validation fails when name is empty")
    @MainActor
    func emptyNameInvalid() {
        let vm = UpdateProfileViewModel(
            userDocument: nil,
            userId: "u1",
            userDocumentService: MockUserDocumentService()
        )
        vm.name = ""
        #expect(vm.isValid == false)
        #expect(vm.nameError != nil)
    }

    @Test("Validation passes with valid name")
    @MainActor
    func validName() {
        let vm = UpdateProfileViewModel(
            userDocument: nil,
            userId: "u1",
            userDocumentService: MockUserDocumentService()
        )
        vm.name = "Test User"
        #expect(vm.isValid == true)
        #expect(vm.nameError == nil)
    }

    @Test("Save calls updateUserDocument with correct fields")
    @MainActor
    func saveCallsUpdate() async {
        let mock = MockUserDocumentService()
        let vm = UpdateProfileViewModel(
            userDocument: nil,
            userId: "u1",
            userDocumentService: mock
        )
        vm.name = "New Name"
        vm.language = "en"

        let result = await vm.save()

        #expect(result == true)
        #expect(mock.updateCallCount == 1)
        #expect(mock.lastUpdatedFields?["displayName"] as? String == "New Name")
        #expect(mock.lastUpdatedFields?["locale"] as? String == "en")
    }

    @Test("Save returns false when validation fails")
    @MainActor
    func saveFailsValidation() async {
        let vm = UpdateProfileViewModel(
            userDocument: nil,
            userId: "u1",
            userDocumentService: MockUserDocumentService()
        )
        vm.name = "  "
        let result = await vm.save()
        #expect(result == false)
    }
}
