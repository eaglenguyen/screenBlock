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
            markUnblockReset() // 👈 new
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
        for webDomain: WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            markUnblockReset() // 👈 new
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
            markUnblockReset() // 👈 new
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

    private func markUnblockTapped() {
        let sharedDefaults = UserDefaults(suiteName: "group.com.eagle.pausenow")
        sharedDefaults?.set(true, forKey: "unblockButtonTapped")
        sharedDefaults?.synchronize()
    }

    // 👇 new — resets the flag when the user exits the shield
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
