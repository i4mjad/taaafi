import SwiftUI

@Observable
@MainActor
final class VaultLayoutSettingsViewModel {
    var tabOrder: [VaultTab]
    var hiddenTabs: Set<VaultTab>
    var sectionOrder: [VaultSection]
    var hiddenSections: Set<VaultSection>

    private let layoutStore: VaultLayoutStoreProtocol

    init(settings: VaultLayoutSettings, layoutStore: VaultLayoutStoreProtocol = VaultLayoutStore()) {
        self.tabOrder = settings.tabOrder
        self.hiddenTabs = settings.hiddenTabs
        self.sectionOrder = settings.sectionOrder
        self.hiddenSections = settings.hiddenSections
        self.layoutStore = layoutStore
    }

    var currentSettings: VaultLayoutSettings {
        VaultLayoutSettings(
            tabOrder: tabOrder,
            hiddenTabs: hiddenTabs,
            sectionOrder: sectionOrder,
            hiddenSections: hiddenSections
        )
    }

    func toggleTabVisibility(_ tab: VaultTab) {
        // Don't allow hiding the vault tab
        guard tab != .vault else { return }
        if hiddenTabs.contains(tab) {
            hiddenTabs.remove(tab)
        } else {
            hiddenTabs.insert(tab)
        }
        save()
    }

    func toggleSectionVisibility(_ section: VaultSection) {
        if hiddenSections.contains(section) {
            hiddenSections.remove(section)
        } else {
            hiddenSections.insert(section)
        }
        save()
    }

    func moveTab(from source: IndexSet, to destination: Int) {
        tabOrder.move(fromOffsets: source, toOffset: destination)
        save()
    }

    func moveSection(from source: IndexSet, to destination: Int) {
        sectionOrder.move(fromOffsets: source, toOffset: destination)
        save()
    }

    func resetToDefault() {
        let defaults = VaultLayoutSettings.defaultSettings
        tabOrder = defaults.tabOrder
        hiddenTabs = defaults.hiddenTabs
        sectionOrder = defaults.sectionOrder
        hiddenSections = defaults.hiddenSections
        save()
    }

    private func save() {
        layoutStore.save(currentSettings)
    }
}
