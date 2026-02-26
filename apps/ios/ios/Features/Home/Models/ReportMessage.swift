//
//  ReportMessage.swift
//  ios
//

import Foundation
import FirebaseFirestore

enum SenderRole: String, Codable {
    case user
    case admin
}

struct ReportMessage: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var reportId: String
    var senderId: String
    var senderRole: SenderRole
    var message: String
    var timestamp: Date
    var isRead: Bool
}
