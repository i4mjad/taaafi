import Foundation

/// ViewModel for the ConfirmUserDetailsScreen — loads existing user data and saves updates
@Observable
@MainActor
final class ConfirmDetailsViewModel {

    var displayName = ""
    var email = ""
    var gender = "male"
    var locale = "en"
    var dayOfBirth: Date?

    var isLoading = true
    var isSaving = false
    var isEmailDisabled = false

    // MARK: - Load

    func loadFromDocument(_ doc: UserDocument?) {
        guard let doc else {
            isLoading = false
            return
        }

        displayName = doc.displayName ?? ""
        email = doc.email ?? ""
        gender = doc.gender ?? "male"
        locale = doc.locale ?? "en"
        dayOfBirth = doc.dayOfBirth

        // Disable email if already set
        isEmailDisabled = doc.email != nil && !doc.email!.isEmpty

        isLoading = false
    }

    // MARK: - Validation

    func validate() -> Bool {
        guard !displayName.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        guard let dob = dayOfBirth else { return false }

        // Legacy users may have very old DOBs, use a generous cutoff
        let maxDate = makeDate(year: 2015, month: 12, day: 31)
        return dob <= maxDate
    }

    var nameError: String? {
        if displayName.isEmpty { return nil }
        return displayName.trimmingCharacters(in: .whitespaces).isEmpty
            ? String(localized: "registration.nameRequired")
            : nil
    }

    // MARK: - Save

    func save(userId: String, userDocumentService: UserDocumentService) async throws {
        isSaving = true
        defer { isSaving = false }

        var fields: [String: Any] = [
            "displayName": displayName.trimmingCharacters(in: .whitespaces),
            "gender": gender,
            "locale": locale,
        ]

        if let dayOfBirth {
            fields["dayOfBirth"] = dayOfBirth
        }

        if !isEmailDisabled, !email.isEmpty {
            fields["email"] = email
        }

        // If this is a legacy document, set userFirstDate to now
        fields["userFirstDate"] = Date()

        try await userDocumentService.updateUserDocument(userId: userId, fields: fields)
    }

    // MARK: - Helpers

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components) ?? Date()
    }
}
