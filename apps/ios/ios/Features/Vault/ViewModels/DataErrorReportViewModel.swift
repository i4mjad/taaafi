import Foundation
import FirebaseAuth
import FirebaseFirestore

@Observable
@MainActor
final class DataErrorReportViewModel {
    var reportText = ""
    var isLoadingExisting = true
    var isSubmitting = false
    var hasExistingReport = false
    var error: String?

    private let firestoreService: FirestoreService

    init(firestoreService: FirestoreService) {
        self.firestoreService = firestoreService
    }

    var canSubmit: Bool {
        let trimmed = reportText.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 220
    }

    func checkExistingReport() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            isLoadingExisting = false
            return
        }
        isLoadingExisting = true

        do {
            // Check for recent data error reports in last 7 days
            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
            let reports: [DataErrorReport] = try await firestoreService.getDocuments(
                collection: "users/\(userId)/reports",
                filters: [
                    .isEqualTo(field: "type", value: "dataIssue"),
                    .isGreaterThan(field: "createdAt", value: Timestamp(date: sevenDaysAgo))
                ],
                orderBy: "createdAt",
                descending: true
            )
            hasExistingReport = !reports.isEmpty
            isLoadingExisting = false
        } catch {
            isLoadingExisting = false
        }
    }

    func submitReport() async -> Bool {
        guard let userId = Auth.auth().currentUser?.uid, canSubmit else { return false }
        isSubmitting = true
        error = nil

        do {
            let report = DataErrorReport(
                type: "dataIssue",
                description: reportText.trimmingCharacters(in: .whitespacesAndNewlines),
                createdAt: Date()
            )
            _ = try await firestoreService.addDocument(
                collection: "users/\(userId)/reports",
                data: report
            )
            isSubmitting = false
            return true
        } catch {
            self.error = error.localizedDescription
            isSubmitting = false
            return false
        }
    }
}

// MARK: - Report Model

struct DataErrorReport: Codable, Identifiable {
    @DocumentID var id: String?
    let type: String
    let description: String
    let createdAt: Date
}
