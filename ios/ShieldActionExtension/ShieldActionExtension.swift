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
            completionHandler(.close)
        case .secondaryButtonPressed:
            sendUnblockNotification() // 👈 new
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
            completionHandler(.close)
        case .secondaryButtonPressed:
            sendUnblockNotification() // 👈 new
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
            completionHandler(.close)
        case .secondaryButtonPressed:
            sendUnblockNotification() // 👈 new
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
    
    // 👇 new — fires an immediate local notification
    private func sendUnblockNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Take a small break!"
        content.sound = .default

        // fire essentially immediately
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


