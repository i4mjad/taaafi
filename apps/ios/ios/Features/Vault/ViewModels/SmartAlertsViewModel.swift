import Foundation
import FirebaseAuth

@Observable
@MainActor
final class SmartAlertsViewModel {
    var settings = SmartAlertSettings.empty
    var isLoading = true
    var isSaving = false
    var error: String?

    private let smartAlertService: SmartAlertService
    private let followUpService: FollowUpService
    private let userFirstDate: Date

    init(smartAlertService: SmartAlertService, followUpService: FollowUpService, userFirstDate: Date) {
        self.smartAlertService = smartAlertService
        self.followUpService = followUpService
        self.userFirstDate = userFirstDate
    }

    func loadSettings() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        do {
            settings = try await smartAlertService.getSettings(userId: userId)

            // Check eligibility
            let followUps = try await followUpService.getFollowUps(
                userId: userId,
                startDate: userFirstDate,
                endDate: Date()
            )
            let eligibility = smartAlertService.checkEligibility(userId: userId, followUps: followUps)
            settings.isEligible = eligibility.isEligible
            settings.eligibilityReason = eligibility.reason

            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    func toggleEnabled() {
        settings.isEnabled.toggle()
    }

    func setAlertTime(_ time: Date) {
        settings.alertTime = time
    }

    func save() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isSaving = true

        do {
            try await smartAlertService.saveSettings(userId: userId, settings: settings)
            isSaving = false
        } catch {
            self.error = error.localizedDescription
            isSaving = false
        }
    }

    var eligibilityReasonText: String? {
        guard let reason = settings.eligibilityReason else { return nil }
        if reason.starts(with: "need-followups-for-risk-hour:") {
            let count = reason.split(separator: ":").last.map(String.init) ?? ""
            return String(localized: "vault.smartAlerts.needFollowups \(count)")
        } else if reason.starts(with: "need-weeks-for-vulnerability:") {
            let weeks = reason.split(separator: ":").last.map(String.init) ?? ""
            return String(localized: "vault.smartAlerts.needWeeks \(weeks)")
        }
        return reason
    }
}
