import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Provides the custom shield UI shown when a blocked app is opened.
/// Displays Arabic motivational text with Islamic-inspired design.
///
/// NOTE: This extension must be added as an Xcode target with the
/// ManagedSettingsUI capability and the same App Group (group.com.taaafi.app).
@available(iOS 16.0, *)
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        return buildFortShield()
    }

    override func configuration(
        shielding application: Application,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        return buildFortShield()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        return buildFortShield()
    }

    override func configuration(
        shielding webDomain: WebDomain,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        return buildFortShield()
    }

    private func buildFortShield() -> ShieldConfiguration {
        // Arabic motivational text — "Your fort protects you"
        let title = ShieldConfiguration.Label(
            text: "حصنك يحميك",
            color: UIColor(red: 0.13, green: 0.13, blue: 0.20, alpha: 1.0)
        )
        let subtitle = ShieldConfiguration.Label(
            text: "خذ نفساً عميقاً وتذكّر لماذا بدأت",
            color: UIColor(red: 0.4, green: 0.4, blue: 0.5, alpha: 1.0)
        )
        let primaryButton = ShieldConfiguration.Label(
            text: "تأمّل",  // "Reflect"
            color: .white
        )
        let secondaryButton = ShieldConfiguration.Label(
            text: "إغلاق", // "Close"
            color: UIColor(red: 0.4, green: 0.4, blue: 0.5, alpha: 1.0)
        )

        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterial,
            backgroundColor: UIColor(red: 0.97, green: 0.96, blue: 0.94, alpha: 1.0),
            title: title,
            subtitle: subtitle,
            primaryButtonLabel: primaryButton,
            primaryButtonBackgroundColor: UIColor(red: 0.20, green: 0.55, blue: 0.45, alpha: 1.0),
            secondaryButtonLabel: secondaryButton
        )
    }
}
