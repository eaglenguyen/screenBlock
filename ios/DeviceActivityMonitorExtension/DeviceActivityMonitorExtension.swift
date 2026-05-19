import DeviceActivity
import Foundation
import ManagedSettings
import FamilyControls

class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    // two separate stores
    let blockStore = ManagedSettingsStore(
        named: ManagedSettingsStore.Name("blockAll")
    )
    let allowStore = ManagedSettingsStore(
        named: ManagedSettingsStore.Name("allowList")
    )

    override func intervalDidStart(
        for activity: DeviceActivityName
    ) {
        super.intervalDidStart(for: activity)
        clearAll()
    }

    override func intervalDidEnd(
        for activity: DeviceActivityName
    ) {
        super.intervalDidEnd(for: activity)
        clearAll()
    }

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)

        guard let sharedDefaults = UserDefaults(
            suiteName: "group.com.eagle.screenblock"
        ) else { return }

        let blockingMode = sharedDefaults.string(
            forKey: "blockingMode"
        ) ?? "specific_apps"

        if blockingMode == "specific_apps" {
            _applySpecificAppsBlock(sharedDefaults)
        } else {
            _applyAllAppsBlock(sharedDefaults)
        }
    }

    // MARK: - Specific Apps Mode
    private func _applySpecificAppsBlock(
        _ defaults: UserDefaults
    ) {
        guard let data = defaults.data(forKey: "blockedApps"),
              let selection = try? JSONDecoder().decode(
                  FamilyActivitySelection.self,
                  from: data
              )
        else { return }

        // block specific apps and their categories
        blockStore.shield.applications =
            selection.applicationTokens
        
        if !selection.categoryTokens.isEmpty {
            blockStore.shield.applicationCategories =
                .specific(selection.categoryTokens)
        }
    }

    // MARK: - All Apps Mode
    private func _applyAllAppsBlock(
        _ defaults: UserDefaults
    ) {
        // step 1 — block all categories in main store
        blockStore.shield.applicationCategories = .all()

        // step 2 — if there are allowed apps,
        // set them in a separate store with a
        // passthrough shield config
        // ShieldActionExtension will auto-dismiss
        // the shield for these apps
        if let data = defaults.data(forKey: "allowedApps"),
           let selection = try? JSONDecoder().decode(
               FamilyActivitySelection.self,
               from: data
           ),
           !selection.applicationTokens.isEmpty
        {
            // store allowed tokens so ShieldActionExtension
            // knows which apps to auto-dismiss
            defaults.set(
                try? JSONEncoder().encode(
                    selection.applicationTokens
                ),
                forKey: "allowedAppTokens"
            )
            allowStore.shield.applications =
                selection.applicationTokens
        }
    }

    private func clearAll() {
        blockStore.clearAllSettings()
        allowStore.clearAllSettings()
    }
}
