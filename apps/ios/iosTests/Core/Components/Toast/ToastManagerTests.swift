import Testing
import Foundation
@testable import ios

@Suite("ToastManager")
struct ToastManagerTests {

    @Test("Show adds toast to queue")
    @MainActor
    func showAddsToast() {
        let manager = ToastManager()
        let toast = ToastMessage(variant: .info, message: "Hello")
        manager.show(toast)
        #expect(manager.toasts.count == 1)
        #expect(manager.toasts.first?.message == "Hello")
    }

    @Test("Show convenience adds toast with variant and message")
    @MainActor
    func showConvenience() {
        let manager = ToastManager()
        manager.show(.error, message: "Failed")
        #expect(manager.toasts.count == 1)
        #expect(manager.toasts.first?.variant == .error)
    }

    @Test("Multiple toasts queue up")
    @MainActor
    func multipleToastsQueue() {
        let manager = ToastManager()
        manager.show(.info, message: "First")
        manager.show(.success, message: "Second")
        manager.show(.error, message: "Third")
        #expect(manager.toasts.count == 3)
    }

    @Test("Dismiss removes specific toast")
    @MainActor
    func dismissRemovesToast() {
        let manager = ToastManager()
        let toast = ToastMessage(variant: .info, message: "Hello")
        manager.show(toast)
        manager.dismiss(toast)
        #expect(manager.toasts.isEmpty)
    }

    @Test("DismissAll clears all toasts")
    @MainActor
    func dismissAllClears() {
        let manager = ToastManager()
        manager.show(.info, message: "First")
        manager.show(.error, message: "Second")
        manager.dismissAll()
        #expect(manager.toasts.isEmpty)
    }
}
