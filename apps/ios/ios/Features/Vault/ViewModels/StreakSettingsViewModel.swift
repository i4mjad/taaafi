import Foundation

@Observable
@MainActor
final class StreakSettingsViewModel {
    var settings: StreakDisplaySettings
    var userFirstDate: Date

    private let store: StreakSettingsStore

    init(userFirstDate: Date, store: StreakSettingsStore = StreakSettingsStore()) {
        self.store = store
        self.settings = store.load()
        self.userFirstDate = userFirstDate
    }

    func setDisplayMode(_ mode: StreakDisplayMode) {
        settings.displayMode = mode
    }

    func toggleVisibility(_ type: FollowUpType) {
        switch type {
        case .relapse:
            settings.visibility.relapse.toggle()
        case .pornOnly:
            settings.visibility.pornOnly.toggle()
        case .mastOnly:
            settings.visibility.mastOnly.toggle()
        case .slipUp:
            settings.visibility.slipUp.toggle()
        case .none:
            break
        }
    }

    func isVisible(_ type: FollowUpType) -> Bool {
        switch type {
        case .relapse: return settings.visibility.relapse
        case .pornOnly: return settings.visibility.pornOnly
        case .mastOnly: return settings.visibility.mastOnly
        case .slipUp: return settings.visibility.slipUp
        case .none: return true
        }
    }

    func save() {
        store.save(settings)
    }
}

// MARK: - Persistence

final class StreakSettingsStore {
    private let key = "streakDisplaySettings"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> StreakDisplaySettings {
        guard let data = defaults.data(forKey: key),
              let settings = try? JSONDecoder().decode(StreakDisplaySettings.self, from: data) else {
            return .defaultSettings
        }
        return settings
    }

    func save(_ settings: StreakDisplaySettings) {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: key)
        }
    }
}
