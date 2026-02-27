import SwiftUI
import FirebaseAuth
import FirebaseFirestore

enum FollowUpStep: Int, CaseIterable {
    case selectType
    case selectTriggers
    case selectEmotions
    case notes
}

@Observable
@MainActor
final class FollowUpSheetViewModel {
    var currentStep: FollowUpStep = .selectType
    var selectedDate = Date()
    var selectedTypes: Set<FollowUpType> = []
    var isFreeDay = false
    var addAllFollowUps = false
    var selectedTriggers: Set<String> = []
    var selectedEmotions: Set<String> = []
    var notes = ""
    var isSaving = false
    var error: String?

    private let followUpService: FollowUpService
    private let emotionService: EmotionService

    init(followUpService: FollowUpService, emotionService: EmotionService) {
        self.followUpService = followUpService
        self.emotionService = emotionService
    }

    var canProceed: Bool {
        switch currentStep {
        case .selectType:
            return isFreeDay || !selectedTypes.isEmpty
        case .selectTriggers, .selectEmotions, .notes:
            return true
        }
    }

    var showTriggerStep: Bool {
        selectedTypes.contains(where: { $0.isRelapseRelated })
    }

    var nextStep: FollowUpStep? {
        switch currentStep {
        case .selectType:
            if isFreeDay { return nil }
            return showTriggerStep ? .selectTriggers : .selectEmotions
        case .selectTriggers:
            return .selectEmotions
        case .selectEmotions:
            return .notes
        case .notes:
            return nil
        }
    }

    var isLastStep: Bool {
        nextStep == nil
    }

    func selectFreeDay() {
        isFreeDay = true
        selectedTypes.removeAll()
    }

    func selectType(_ type: FollowUpType) {
        isFreeDay = false
        if selectedTypes.contains(type) {
            selectedTypes.remove(type)
        } else {
            selectedTypes.insert(type)
        }
    }

    func toggleTrigger(_ trigger: String) {
        if selectedTriggers.contains(trigger) {
            selectedTriggers.remove(trigger)
        } else {
            selectedTriggers.insert(trigger)
        }
    }

    func toggleEmotion(_ emotionId: String) {
        if selectedEmotions.contains(emotionId) {
            selectedEmotions.remove(emotionId)
        } else {
            selectedEmotions.insert(emotionId)
        }
    }

    func goToNext() {
        if let next = nextStep {
            withAnimation {
                currentStep = next
            }
        }
    }

    func goBack() {
        switch currentStep {
        case .selectType:
            break
        case .selectTriggers:
            currentStep = .selectType
        case .selectEmotions:
            currentStep = showTriggerStep ? .selectTriggers : .selectType
        case .notes:
            currentStep = .selectEmotions
        }
    }

    func save() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isSaving = true
        error = nil

        do {
            if isFreeDay {
                // Delete existing follow-ups for this date and add a "none" follow-up
                try await followUpService.deleteFollowUpsForDate(userId: userId, date: selectedDate)
                let followUp = FollowUpModel(
                    type: .none,
                    time: selectedDate,
                    triggers: []
                )
                _ = try await followUpService.addFollowUp(userId: userId, followUp: followUp)
            } else {
                let triggers = Array(selectedTriggers)

                if addAllFollowUps && selectedTypes.contains(.relapse) {
                    // Add all relapse-related types
                    for type in [FollowUpType.relapse, .pornOnly, .mastOnly, .slipUp] {
                        let followUp = FollowUpModel(type: type, time: selectedDate, triggers: triggers)
                        _ = try await followUpService.addFollowUp(userId: userId, followUp: followUp)
                    }
                } else {
                    for type in selectedTypes {
                        let followUp = FollowUpModel(type: type, time: selectedDate, triggers: triggers)
                        _ = try await followUpService.addFollowUp(userId: userId, followUp: followUp)
                    }
                }
            }

            // Save emotions
            for emotionId in selectedEmotions {
                if let emotion = Emotions.all.first(where: { $0.id == emotionId }) {
                    let emotionModel = EmotionModel(
                        emotionEmoji: emotion.emoji,
                        emotionName: emotion.id,
                        date: selectedDate
                    )
                    _ = try await emotionService.addEmotion(userId: userId, emotion: emotionModel)
                }
            }

            isSaving = false
        } catch {
            self.error = error.localizedDescription
            isSaving = false
        }
    }

    func reset() {
        currentStep = .selectType
        selectedDate = Date()
        selectedTypes.removeAll()
        isFreeDay = false
        addAllFollowUps = false
        selectedTriggers.removeAll()
        selectedEmotions.removeAll()
        notes = ""
        error = nil
    }
}
