import Foundation

@Observable
@MainActor
final class UpdateProfileViewModel {
    private let userDocumentService: UserDocumentServiceProtocol
    private let userId: String

    var name: String
    var dayOfBirth: Date?
    var language: String

    private(set) var isSaving = false
    private(set) var error: Error?

    var nameError: String? {
        name.trimmingCharacters(in: .whitespaces).isEmpty ? Strings.Registration.nameRequired : nil
    }

    var isValid: Bool { nameError == nil }

    init(userDocument: UserDocument?, userId: String, userDocumentService: UserDocumentServiceProtocol) {
        self.userDocumentService = userDocumentService
        self.userId = userId
        self.name = userDocument?.displayName ?? ""
        self.dayOfBirth = userDocument?.dayOfBirth
        self.language = userDocument?.locale ?? "ar"
    }

    func save() async -> Bool {
        guard isValid else { return false }

        isSaving = true
        error = nil

        var fields: [String: Any] = [:]
        fields["displayName"] = name.trimmingCharacters(in: .whitespaces)
        if let dob = dayOfBirth {
            fields["dayOfBirth"] = dob
        }
        fields["locale"] = language

        do {
            try await userDocumentService.updateUserDocument(userId: userId, fields: fields)
            isSaving = false
            return true
        } catch {
            self.error = error
            isSaving = false
            return false
        }
    }
}
