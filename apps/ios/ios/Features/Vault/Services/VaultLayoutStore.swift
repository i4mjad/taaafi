import Foundation

protocol VaultLayoutStoreProtocol {
    func load() -> VaultLayoutSettings
    func save(_ settings: VaultLayoutSettings)
}

final class VaultLayoutStore: VaultLayoutStoreProtocol {
    private let key = "vault_layout_settings"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> VaultLayoutSettings {
        guard let data = defaults.data(forKey: key),
              let settings = try? JSONDecoder().decode(VaultLayoutSettings.self, from: data) else {
            return .defaultSettings
        }
        return settings
    }

    func save(_ settings: VaultLayoutSettings) {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: key)
        }
    }
}
