import SwiftUI

enum VaultRoute: Hashable {
    case dayOverview(date: Date)
    case addActivity
    case activityOverview(activityId: String)
    case ongoingActivity(ongoingActivityId: String)
    case allTasks
}

@Observable
@MainActor
final class VaultContainerViewModel {
    var selectedTab: VaultTab = .vault
    var navigationPath = NavigationPath()
    var showFollowUpSheet = false
    var showLayoutSettings = false
    var layoutSettings: VaultLayoutSettings

    private let layoutStore: VaultLayoutStoreProtocol

    init(layoutStore: VaultLayoutStoreProtocol = VaultLayoutStore()) {
        self.layoutStore = layoutStore
        self.layoutSettings = layoutStore.load()
    }

    var visibleTabs: [VaultTab] {
        layoutSettings.tabOrder.filter { !layoutSettings.hiddenTabs.contains($0) }
    }

    var visibleSections: [VaultSection] {
        layoutSettings.sectionOrder.filter { !layoutSettings.hiddenSections.contains($0) }
    }

    func navigate(to route: VaultRoute) {
        navigationPath.append(route)
    }

    func saveLayout() {
        layoutStore.save(layoutSettings)
    }

    func resetLayout() {
        layoutSettings = .defaultSettings
        layoutStore.save(layoutSettings)
    }

    func handleFABAction() {
        switch selectedTab {
        case .vault:
            showFollowUpSheet = true
        case .activities:
            navigate(to: .addActivity)
        default:
            break
        }
    }

    var fabConfig: (icon: String, label: String, color: Color)? {
        switch selectedTab {
        case .vault:
            return ("plus.circle.fill", Strings.Vault.dailyFollowUp, AppColors.primary)
        case .activities:
            return ("plus.circle.fill", Strings.Vault.addActivity, AppColors.primary)
        default:
            return nil
        }
    }
}
