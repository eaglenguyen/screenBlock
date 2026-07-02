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
        let isPomodoroMode = sharedDefaults?.bool(forKey: "isPomodoroMode") ?? false
        let sessionMinutes = sharedDefaults?.integer(forKey: "sessionMinutes") ?? 0
        let roundCount = sharedDefaults?.integer(forKey: "pomodoroRoundCount") ?? 0

        // ── Colors ───────────────────────────────────
        let navyBg = UIColor(red: 14/255, green: 14/255, blue: 30/255, alpha: 1.0)
        let gold = UIColor(red: 237/255, green: 184/255, blue: 42/255, alpha: 1.0)
        let goldText = UIColor(red: 26/255, green: 18/255, blue: 8/255, alpha: 1.0)
        let mutedWhite = UIColor(white: 1.0, alpha: 0.5)
        let red = UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: 1.0)
        let redText = UIColor(white: 1.0, alpha: 1.0)

        // ── Session complete screen ───────────────────
        if !isBlocking {
            // session ended — show completion screen
            if isPomodoroMode {
                return ShieldConfiguration(
                    backgroundColor: navyBg,
                    icon: UIImage(named: "PauseNowIcon"),
                    title: ShieldConfiguration.Label(
                        text: "Round \(roundCount) Complete! 🍅",
                        color: .white
                    ),
                    subtitle: ShieldConfiguration.Label(
                        text: "Great work! You earned \(sessionMinutes * 5) ⭐️ this round.",
                        color: mutedWhite
                    ),
                    primaryButtonLabel: ShieldConfiguration.Label(
                        text: "Take a Break",
                        color: goldText
                    ),
                    primaryButtonBackgroundColor: gold,
                    secondaryButtonLabel: ShieldConfiguration.Label(
                        text: "Stay Focused",
                        color: mutedWhite
                    )
                )
            } else {
                return ShieldConfiguration(
                    backgroundColor: navyBg,
                    icon: UIImage(named: "PauseNowIcon"),
                    title: ShieldConfiguration.Label(
                        text: "Session Complete! ⚡",
                        color: .white
                    ),
                    subtitle: ShieldConfiguration.Label(
                        text: "You earned \(sessionMinutes * 5) ⭐️ for this session.",
                        color: mutedWhite
                    ),
                    primaryButtonLabel: ShieldConfiguration.Label(
                        text: "Claim your ⭐️",
                        color: goldText
                    ),
                    primaryButtonBackgroundColor: gold,
                    secondaryButtonLabel: ShieldConfiguration.Label(
                        text: "Stay Focused",
                        color: mutedWhite
                    )
                )
            }
        }

        // ── Active blocking screen ────────────────────
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
                text: "Got it",
                color: goldText
            ),
            primaryButtonBackgroundColor: gold
        )
    }
}
