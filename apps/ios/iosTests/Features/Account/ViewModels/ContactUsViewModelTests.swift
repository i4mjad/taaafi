import Testing
import Foundation
@testable import ios

@Suite("ContactUsViewModel")
struct ContactUsViewModelTests {

    @Test("Validation fails when message is empty")
    @MainActor
    func emptyMessageInvalid() {
        let vm = ContactUsViewModel(
            firestoreService: MockFirestoreService(),
            userId: "u1",
            userEmail: "test@test.com"
        )
        vm.messageText = ""
        #expect(vm.isValid == false)
    }

    @Test("Validation fails when message exceeds 220 chars")
    @MainActor
    func tooLongMessage() {
        let vm = ContactUsViewModel(
            firestoreService: MockFirestoreService(),
            userId: "u1",
            userEmail: "test@test.com"
        )
        vm.messageText = String(repeating: "a", count: 221)
        #expect(vm.isValid == false)
    }

    @Test("Validation passes with valid message")
    @MainActor
    func validMessage() {
        let vm = ContactUsViewModel(
            firestoreService: MockFirestoreService(),
            userId: "u1",
            userEmail: "test@test.com"
        )
        vm.messageText = "I need help with something"
        #expect(vm.isValid == true)
    }

    @Test("Submit creates report document")
    @MainActor
    func submitCreatesDoc() async {
        let mock = MockFirestoreService()
        let vm = ContactUsViewModel(
            firestoreService: mock,
            userId: "u1",
            userEmail: "test@test.com"
        )
        vm.messageText = "Hello"

        let result = await vm.submit()

        #expect(result == true)
        #expect(mock.addDocumentCallCount == 1)
        #expect(mock.lastAddedCollection == "reports")
    }

    @Test("Submit returns false when invalid")
    @MainActor
    func submitFailsWhenInvalid() async {
        let vm = ContactUsViewModel(
            firestoreService: MockFirestoreService(),
            userId: "u1",
            userEmail: "test@test.com"
        )
        vm.messageText = ""
        let result = await vm.submit()
        #expect(result == false)
    }
}
