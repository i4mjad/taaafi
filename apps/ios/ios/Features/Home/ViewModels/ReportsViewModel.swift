//
//  ReportsViewModel.swift
//  ios
//

import Foundation
import FirebaseFirestore

@Observable
@MainActor
final class ReportsViewModel {
    private(set) var reports: [UserReport] = []
    private(set) var isLoading = false
    private(set) var error: Error?

    private let firestoreService: FirestoreService

    init(firestoreService: FirestoreService) {
        self.firestoreService = firestoreService
    }

    func loadReports(userId: String) async {
        isLoading = true
        error = nil
        do {
            let fetched: [UserReport] = try await firestoreService.getDocuments(
                collection: "usersReports",
                filters: [.isEqualTo(field: "uid", value: userId)],
                orderBy: "lastUpdated",
                descending: true
            )
            reports = fetched
        } catch {
            self.error = error
        }
        isLoading = false
    }

    func createReport(userId: String, type: ReportType, message: String) async throws {
        let docRef = firestoreService.firestore.collection("usersReports").document()
        let report = UserReport(
            id: docRef.documentID,
            uid: userId,
            time: Date(),
            reportTypeId: type.rawValue,
            status: .pending,
            initialMessage: message,
            lastUpdated: Date(),
            messagesCount: 1
        )
        try await firestoreService.setDocument(
            collection: "usersReports",
            id: docRef.documentID,
            data: report
        )

        let firstMessage = ReportMessage(
            id: nil,
            reportId: docRef.documentID,
            senderId: userId,
            senderRole: .user,
            message: message,
            timestamp: Date(),
            isRead: true
        )
        try firestoreService.firestore
            .collection("usersReports")
            .document(docRef.documentID)
            .collection("messages")
            .addDocument(from: firstMessage)

        await loadReports(userId: userId)
    }

    func addMessage(reportId: String, senderId: String, message: String) async throws {
        let msg = ReportMessage(
            id: nil,
            reportId: reportId,
            senderId: senderId,
            senderRole: .user,
            message: message,
            timestamp: Date(),
            isRead: true
        )
        try firestoreService.firestore
            .collection("usersReports")
            .document(reportId)
            .collection("messages")
            .addDocument(from: msg)

        try await firestoreService.updateDocument(
            collection: "usersReports",
            id: reportId,
            fields: [
                "lastUpdated": Date(),
                "messagesCount": FieldValue.increment(Int64(1))
            ]
        )
    }

    func getMessages(reportId: String) async throws -> [ReportMessage] {
        let snapshot = try await firestoreService.firestore
            .collection("usersReports")
            .document(reportId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .getDocuments()

        return try snapshot.documents.map { try $0.data(as: ReportMessage.self) }
    }

    func validateMessage(_ message: String) -> String? {
        if message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return String(localized: "report.error.emptyMessage")
        }
        if message.count > 220 {
            return String(localized: "report.error.messageTooLong")
        }
        return nil
    }
}
