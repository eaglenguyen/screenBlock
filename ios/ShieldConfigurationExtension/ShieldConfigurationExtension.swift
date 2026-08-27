import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        let key = tokenKey(for: application.token)
        return shieldConfig(appName: application.localizedDisplayName ?? "This App", attemptKey: key)
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        let key = tokenKey(for: application.token)
        return shieldConfig(appName: application.localizedDisplayName ?? "This App", attemptKey: key)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        let key = tokenKey(for: webDomain.token)
        return shieldConfig(appName: webDomain.domain ?? "This Site", attemptKey: key)
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        let key = tokenKey(for: webDomain.token)
        return shieldConfig(appName: webDomain.domain ?? "This Site", attemptKey: key)
    }

    private func tokenKey<T: Codable>(for token: T?) -> String {
        guard let token = token, let data = try? JSONEncoder().encode(token) else {
            return "unknown"
        }
        return data.base64EncodedString()
    }

    private func shieldConfig(appName: String, attemptKey: String) -> ShieldConfiguration {
        let sharedDefaults = UserDefaults(suiteName: "group.com.eagle.pausenow")

        let countKey = "openAttemptCount_\(attemptKey)"     // 👈 keyed on token, not appName
        let dateKey = "openAttemptCountDate_\(attemptKey)"
        let lastIncrementKey = "openAttemptLastIncrement_\(attemptKey)"

        let today = Calendar.current.startOfDay(for: Date())
        let lastCountDate = sharedDefaults?.double(forKey: dateKey) ?? 0
        let lastCountDay = lastCountDate > 0
            ? Calendar.current.startOfDay(for: Date(timeIntervalSince1970: lastCountDate))
            : Date.distantPast

        var currentCount: Int
        let now = Date().timeIntervalSince1970
        let lastIncrementTime = sharedDefaults?.double(forKey: lastIncrementKey) ?? 0
        let withinDebounceWindow = (now - lastIncrementTime) < 3.0

        if lastCountDay != today {
            currentCount = 1
            sharedDefaults?.set(today.timeIntervalSince1970, forKey: dateKey)
            sharedDefaults?.set(now, forKey: lastIncrementKey)
            sharedDefaults?.set(currentCount, forKey: countKey)
        } else if withinDebounceWindow {
            currentCount = sharedDefaults?.integer(forKey: countKey) ?? 1
        } else {
            currentCount = (sharedDefaults?.integer(forKey: countKey) ?? 0) + 1
            sharedDefaults?.set(now, forKey: lastIncrementKey)
            sharedDefaults?.set(currentCount, forKey: countKey)
        }
        sharedDefaults?.synchronize()

        let navyBg = UIColor(red: 14/255, green: 14/255, blue: 30/255, alpha: 1.0)
        let gold = UIColor(red: 237/255, green: 184/255, blue: 42/255, alpha: 1.0)
        let goldText = UIColor(red: 26/255, green: 18/255, blue: 8/255, alpha: 1.0)
        let mutedWhite = UIColor(white: 1.0, alpha: 0.5)

        let wasUnblockTapped = sharedDefaults?.bool(forKey: "unblockButtonTapped") ?? false
        let secondaryLabel = wasUnblockTapped ? "didnt get a notification? Open pause now" : "Emergency unblock"

        return ShieldConfiguration(
            backgroundBlurStyle: nil,
            backgroundColor: navyBg,
            icon: UIImage(named: "PauseNowIcon"),
            title: ShieldConfiguration.Label(text: "\(appName) blocked 🔒", color: .white),
            subtitle: ShieldConfiguration.Label(text: "\(currentCount)x today", color: mutedWhite),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Nevermind", color: goldText),
            primaryButtonBackgroundColor: gold,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: secondaryLabel,
                color: wasUnblockTapped ? mutedWhite : .white
            )
        )
    }
}
