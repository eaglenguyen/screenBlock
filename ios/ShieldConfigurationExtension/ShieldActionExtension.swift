import ManagedSettings
import UIKit

class ShieldActionExtension: ShieldActionDelegate {

    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        let sharedDefaults = UserDefaults(suiteName: "group.com.eagle.pausenow")
        let isBlocking = sharedDefaults?.bool(forKey: "isBlocking") ?? false
        let isPomodoroMode = sharedDefaults?.bool(forKey: "isPomodoroMode") ?? false

        if !isBlocking {
            // session complete screen
            switch action {
            case .primaryButtonPressed:
                completionHandler(.close)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let url = URL(string: "pausenow://") {
                    }
                }
            case .secondaryButtonPressed:
                // "Stay Focused" — dismiss shield, keep going
                completionHandler(.close)
            @unknown default:
                fatalError()
            }
        } else {
            // active blocking screen
            switch action {
            case .primaryButtonPressed:
                completionHandler(.close)
            case .secondaryButtonPressed:
                completionHandler(.defer)
            @unknown default:
                fatalError()
            }
        }
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        completionHandler(.close)
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        completionHandler(.close)
    }
}
