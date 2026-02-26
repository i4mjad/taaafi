//
//  ReportsViewModelTests.swift
//  iosTests
//

import Testing
import Foundation
@testable import ios

@Suite("ReportsViewModel.validateMessage")
@MainActor
struct ReportsViewModelValidateMessageTests {

    private func makeViewModel() -> ReportsViewModel {
        ReportsViewModel(firestoreService: FirestoreService())
    }

    @Test("Empty string returns error")
    @MainActor
    func emptyString() {
        let vm = makeViewModel()
        let result = vm.validateMessage("")
        #expect(result != nil)
    }

    @Test("Whitespace-only string returns error")
    @MainActor
    func whitespaceOnly() {
        let vm = makeViewModel()
        let result = vm.validateMessage("   \n  ")
        #expect(result != nil)
    }

    @Test("String over 220 characters returns error")
    @MainActor
    func tooLong() {
        let vm = makeViewModel()
        let longMessage = String(repeating: "a", count: 221)
        let result = vm.validateMessage(longMessage)
        #expect(result != nil)
    }

    @Test("String of exactly 220 characters returns nil")
    @MainActor
    func exactlyMaxLength() {
        let vm = makeViewModel()
        let message = String(repeating: "a", count: 220)
        let result = vm.validateMessage(message)
        #expect(result == nil)
    }

    @Test("Valid message returns nil")
    @MainActor
    func validMessage() {
        let vm = makeViewModel()
        let result = vm.validateMessage("This is a normal report message")
        #expect(result == nil)
    }

    @Test("Single character message returns nil")
    @MainActor
    func singleCharacter() {
        let vm = makeViewModel()
        let result = vm.validateMessage("a")
        #expect(result == nil)
    }
}
