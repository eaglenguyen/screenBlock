import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        return shieldConfig(appName: application.localizedDisplayName ?? "This App")
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        return shieldConfig(appName: application.localizedDisplayName ?? "This App")
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        return shieldConfig(appName: webDomain.domain ?? "This Site")
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        return shieldConfig(appName: webDomain.domain ?? "This Site")
    }

    private func shieldConfig(appName: String = "This App") -> ShieldConfiguration {
        let sharedDefaults = UserDefaults(suiteName: "group.com.eagle.pausenow")
        let isBlocking = sharedDefaults?.bool(forKey: "isBlocking") ?? false
        let sessionMinutes = sharedDefaults?.integer(forKey: "sessionMinutes") ?? 0

        let navyBg = UIColor(red: 14/255, green: 14/255, blue: 30/255, alpha: 1.0)
        let gold = UIColor(red: 237/255, green: 184/255, blue: 42/255, alpha: 1.0)
        let goldText = UIColor(red: 26/255, green: 18/255, blue: 8/255, alpha: 1.0)
        let mutedWhite = UIColor(white: 1.0, alpha: 0.5)

        // 👇 test flag — check if the unblock button was already tapped
        let wasUnblockTapped = sharedDefaults?.bool(forKey: "unblockButtonTapped") ?? false
        let secondaryLabel = wasUnblockTapped ? "Didn't receive a notification?" : "Unblock App"

        return ShieldConfiguration(
            backgroundBlurStyle: nil,
            backgroundColor: navyBg,
            icon: UIImage(named: "PauseNowIcon"),
            title: ShieldConfiguration.Label(
                text: "\(appName) 🛑",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Open pause now if you\nwant to end the block session",
                color: mutedWhite
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Exit",
                color: goldText
            ),
            primaryButtonBackgroundColor: gold,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: secondaryLabel, // 👈 now conditional
                color: .white
            )
        )
    }
}
