import ManagedSettings
import Foundation
import FamilyControls

class ShieldActionExtension: ShieldActionDelegate {

    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        guard let sharedDefaults = UserDefaults(
            suiteName: "group.com.eagle.screenblock"
        ) else {
            completionHandler(.defer)
            return
        }

        let blockingMode = sharedDefaults.string(
            forKey: "blockingMode"
        ) ?? "specific_apps"

        switch action {
        case .primaryButtonPressed:
            if blockingMode == "all_apps" {
                // check if this app is in allowed list
                if isAllowed(application, defaults: sharedDefaults) {
                    // auto-dismiss — this is an allowed app
                    completionHandler(.close)
                } else {
                    completionHandler(.defer)
                }
            } else {
                // specific apps mode — defer (keep blocked)
                completionHandler(.defer)
            }

        case .secondaryButtonPressed:
            // "Open Anyway" — close shield temporarily
            completionHandler(.close)

        @unknown default:
            completionHandler(.defer)
        }
    }

    override func handle(
        action: ShieldAction,
        for webDomain: WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        completionHandler(.defer)
    }

    override func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        completionHandler(.defer)
    }

    private func isAllowed(
        _ token: ApplicationToken,
        defaults: UserDefaults
    ) -> Bool {
        guard let data = defaults.data(forKey: "allowedAppTokens"),
              let tokens = try? JSONDecoder().decode(
                  Set<ApplicationToken>.self,
                  from: data
              )
        else { return false }

        return tokens.contains(token)
    }
}
