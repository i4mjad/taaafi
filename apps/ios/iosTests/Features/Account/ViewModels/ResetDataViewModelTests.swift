import Testing
import Foundation
@testable import ios

@Suite("ResetDataViewModel")
struct ResetDataViewModelTests {

    @Test("Initial state uses provided date")
    @MainActor
    func initialDate() {
        let date = Date(timeIntervalSince1970: 1000000)
        let vm = ResetDataViewModel(userFirstDate: date, userId: "u1", userDocumentService: MockUserDocumentService())
        #expect(vm.selectedDate == date)
        #expect(vm.resetToToday == false)
        #expect(vm.deleteFollowUps == false)
        #expect(vm.deleteEmotions == false)
    }

    @Test("Confirm updates user document with selected date")
    @MainActor
    func confirmWithDate() async {
        let mock = MockUserDocumentService()
        let vm = ResetDataViewModel(userFirstDate: Date(), userId: "u1", userDocumentService: mock)
        vm.deleteFollowUps = true

        let result = await vm.confirm()

        #expect(result == true)
        #expect(mock.updateCallCount == 1)
        #expect(mock.lastUpdatedFields?["userFirstDate"] != nil)
        #expect(mock.lastUpdatedFields?["userRelapses"] != nil)
    }

    @Test("Confirm with resetToToday ignores selected date")
    @MainActor
    func confirmResetToToday() async {
        let mock = MockUserDocumentService()
        let oldDate = Date(timeIntervalSince1970: 1000)
        let vm = ResetDataViewModel(userFirstDate: oldDate, userId: "u1", userDocumentService: mock)
        vm.resetToToday = true

        let result = await vm.confirm()

        #expect(result == true)
        #expect(mock.updateCallCount == 1)
    }
}
