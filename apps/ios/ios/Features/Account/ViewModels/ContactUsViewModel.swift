import Foundation

@Observable
@MainActor
final class ContactUsViewModel {
    private let firestoreService: FirestoreServiceProtocol
    private let userId: String
    private let userEmail: String

    var messageText: String = ""
    private(set) var isSubmitting = false
    private(set) var error: Error?

    var isValid: Bool {
        !messageText.trimmingCharacters(in: .whitespaces).isEmpty && messageText.count <= 220
    }

    init(firestoreService: FirestoreServiceProtocol, userId: String, userEmail: String) {
        self.firestoreService = firestoreService
        self.userId = userId
        self.userEmail = userEmail
    }

    func submit() async -> Bool {
        guard isValid else { return false }

        isSubmitting = true
        error = nil

        let report = ContactReport(
            userId: userId,
            userEmail: userEmail,
            message: messageText.trimmingCharacters(in: .whitespaces),
            type: "contact",
            createdAt: Date()
        )

        do {
            _ = try await firestoreService.addDocument(collection: "reports", data: report)
            isSubmitting = false
            return true
        } catch {
            self.error = error
            isSubmitting = false
            return false
        }
    }
}

private struct ContactReport: Codable {
    let userId: String
    let userEmail: String
    let message: String
    let type: String
    let createdAt: Date
}
