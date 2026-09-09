import ManagedSettings
import UserNotifications
import Foundation
import FamilyControls

class ShieldActionExtension: ShieldActionDelegate {
    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            markUnblockReset()
            completionHandler(.close)
        case .secondaryButtonPressed:
            if let configId = findLockAppConfigId(for: application) {
                markLockAppUnblockTapped(configId: configId, token: application)
                sendLockAppUnblockNotification()
            } else {
                markUnblockTapped()
                sendUnblockNotification()
            }
            completionHandler(.defer)
        case .firstSecondarySubmenuItemPressed:
            completionHandler(.close)
        case .secondSecondarySubmenuItemPressed:
            completionHandler(.close)
        case .thirdSecondarySubmenuItemPressed:
            completionHandler(.close)
        @unknown default:
            completionHandler(.close)
        }
    }

    override func handle(
        action: ShieldAction,
        for webDomain: WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            markUnblockReset()
            completionHandler(.close)
        case .secondaryButtonPressed:
            markUnblockTapped()
            sendUnblockNotification()
            completionHandler(.defer)
        case .firstSecondarySubmenuItemPressed:
            completionHandler(.close)
        case .secondSecondarySubmenuItemPressed:
            completionHandler(.close)
        case .thirdSecondarySubmenuItemPressed:
            completionHandler(.close)
        @unknown default:
            completionHandler(.close)
        }
    }

    override func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            markUnblockReset()
            completionHandler(.close)
        case .secondaryButtonPressed:
            markUnblockTapped()
            sendUnblockNotification()
            completionHandler(.defer)
        case .firstSecondarySubmenuItemPressed:
            completionHandler(.close)
        case .secondSecondarySubmenuItemPressed:
            completionHandler(.close)
        case .thirdSecondarySubmenuItemPressed:
            completionHandler(.close)
        @unknown default:
            completionHandler(.close)
        }
    }

    // 👇 new — reverse-lookup: does this token belong to a Lock App config?
    private func findLockAppConfigId(for token: ApplicationToken) -> String? {
        let sharedDefaults = UserDefaults(suiteName: "group.com.eagle.pausenow")
        let configIds = sharedDefaults?.stringArray(forKey: "lockAppConfigIds") ?? []
        for configId in configIds {
            guard let data = sharedDefaults?.data(forKey: "lockApp_\(configId)"),
                  let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
            else { continue }
            if selection.applicationTokens.contains(token) {
                return configId
            }
        }
        return nil
    }

    private func markLockAppUnblockTapped(configId: String, token: ApplicationToken) {
        let sharedDefaults = UserDefaults(suiteName: "group.com.eagle.pausenow")
        sharedDefaults?.set(configId, forKey: "pendingLockAppConfirmId")
        sharedDefaults?.synchronize()
    }

    private func sendLockAppUnblockNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Ready to unlock?"
        content.body = "Tap to confirm and use your app."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "com.eagle.pausenow.lockAppUnlockNudge",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                NSLog("❌ failed to schedule lock-app unblock notification: \(error)")
            }
        }
    }

    private func markUnblockTapped() {
        let sharedDefaults = UserDefaults(suiteName: "group.com.eagle.pausenow")
        sharedDefaults?.set(true, forKey: "unblockButtonTapped")
        sharedDefaults?.synchronize()
    }

    private func markUnblockReset() {
        let sharedDefaults = UserDefaults(suiteName: "group.com.eagle.pausenow")
        sharedDefaults?.set(false, forKey: "unblockButtonTapped")
        sharedDefaults?.synchronize()
    }

    private func sendUnblockNotification() {
        let content = UNMutableNotificationContent()
        content.title = "your apps are currently blocked!"
        content.body = "take a small break"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "com.eagle.pausenow.unblockNudge",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                NSLog("❌ failed to schedule unblock notification: \(error)")
            }
        }
    }
}
