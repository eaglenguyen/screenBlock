import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    // shield for a specific app
    override func configuration(
        shielding application: Application
    ) -> ShieldConfiguration {
        return shieldConfig()
    }

    // shield for an app because of its category
    override func configuration(
        shielding application: Application,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        return shieldConfig()
    }

    // shield for a website
    override func configuration(
        shielding webDomain: WebDomain
    ) -> ShieldConfiguration {
        return shieldConfig()
    }

    // shield for a website because of its category
    override func configuration(
        shielding webDomain: WebDomain,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        return shieldConfig()
    }

    private func shieldConfig() -> ShieldConfiguration {
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: UIColor(
                red: 22/255,
                green: 22/255,
                blue: 42/255,
                alpha: 0.97
            ),
            icon: UIImage(systemName: "shield.fill"),
            title: ShieldConfiguration.Label(
                text: "Time's Up",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "You've reached your limit.",
                color: UIColor(
                    red: 112/255,
                    green: 112/255,
                    blue: 160/255,
                    alpha: 1
                )
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "OK",
                color: UIColor(
                    red: 26/255,
                    green: 18/255,
                    blue: 8/255,
                    alpha: 1
                )
            ),
            primaryButtonBackgroundColor: UIColor(
                red: 237/255,
                green: 184/255,
                blue: 42/255,
                alpha: 1
            ),
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Open Anyway",
                color: UIColor(
                    red: 112/255,
                    green: 112/255,
                    blue: 160/255,
                    alpha: 1
                )
            )
        )
    }
}
