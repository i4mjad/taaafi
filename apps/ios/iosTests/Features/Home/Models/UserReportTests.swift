//
//  UserReportTests.swift
//  iosTests
//

import Testing
import Foundation
@testable import ios

@Suite("ReportStatus raw values")
struct ReportStatusTests {

    @Test("All cases round-trip through rawValue")
    func rawValueRoundTrip() {
        for status in ReportStatus.allCases {
            #expect(ReportStatus(rawValue: status.rawValue) == status)
        }
    }

    @Test("inProgress maps to 'in_progress'")
    func inProgressRawValue() {
        #expect(ReportStatus.inProgress.rawValue == "in_progress")
    }

    @Test("waitingForAdminResponse maps to 'waiting_for_admin_response'")
    func waitingRawValue() {
        #expect(ReportStatus.waitingForAdminResponse.rawValue == "waiting_for_admin_response")
    }

    @Test("pending maps to 'pending'")
    func pendingRawValue() {
        #expect(ReportStatus.pending.rawValue == "pending")
    }
}

@Suite("ReportType properties")
struct ReportTypeTests {

    @Test("All cases have non-empty displayName")
    func displayNameNonEmpty() {
        for type in ReportType.allCases {
            #expect(!type.displayName.isEmpty)
        }
    }

    @Test("All cases have non-empty icon")
    func iconNonEmpty() {
        for type in ReportType.allCases {
            #expect(!type.icon.isEmpty)
        }
    }

    @Test("id matches rawValue")
    func idMatchesRawValue() {
        for type in ReportType.allCases {
            #expect(type.id == type.rawValue)
        }
    }

    @Test("dataError raw value is 'data_error'")
    func dataErrorRawValue() {
        #expect(ReportType.dataError.rawValue == "data_error")
    }

    @Test("There are exactly 9 report types")
    func caseCount() {
        #expect(ReportType.allCases.count == 9)
    }
}

@Suite("UserReport")
struct UserReportTests2 {

    private func makeSampleReport() -> UserReport {
        UserReport(
            id: "report-1",
            uid: "user-1",
            time: Date(timeIntervalSince1970: 1700000000),
            reportTypeId: "data_error",
            status: .pending,
            initialMessage: "Something is wrong with my data",
            lastUpdated: Date(timeIntervalSince1970: 1700001000),
            messagesCount: 2
        )
    }

    @Test("Fields are preserved on creation")
    func fieldAccess() {
        let report = makeSampleReport()
        #expect(report.uid == "user-1")
        #expect(report.reportTypeId == "data_error")
        #expect(report.status == .pending)
        #expect(report.initialMessage == "Something is wrong with my data")
        #expect(report.messagesCount == 2)
    }

    @Test("reportType computed property returns matching type")
    func reportTypeComputed() {
        let report = makeSampleReport()
        #expect(report.reportType == .dataError)
    }

    @Test("reportType returns nil for unknown reportTypeId")
    func reportTypeUnknown() {
        var report = makeSampleReport()
        report.reportTypeId = "unknown_type"
        #expect(report.reportType == nil)
    }

    @Test("Equatable compares all fields")
    func equatable() {
        let a = makeSampleReport()
        let b = makeSampleReport()
        #expect(a == b)
    }
}

@Suite("ReportMessage")
struct ReportMessageTests {

    @Test("Fields are preserved on creation")
    func fieldAccess() {
        let msg = ReportMessage(
            id: "msg-1",
            reportId: "report-1",
            senderId: "user-1",
            senderRole: .user,
            message: "Hello admin",
            timestamp: Date(timeIntervalSince1970: 1700000000),
            isRead: false
        )
        #expect(msg.reportId == "report-1")
        #expect(msg.senderId == "user-1")
        #expect(msg.senderRole == .user)
        #expect(msg.message == "Hello admin")
        #expect(msg.isRead == false)
    }

    @Test("SenderRole raw values are correct")
    func senderRoleRawValues() {
        #expect(SenderRole.user.rawValue == "user")
        #expect(SenderRole.admin.rawValue == "admin")
    }
}
