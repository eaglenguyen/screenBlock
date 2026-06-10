import DeviceActivity
import FamilyControls
import ManagedSettings
import Foundation
import os

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    
    let store = ManagedSettingsStore()
    let sharedDefaults = UserDefaults(suiteName: "group.com.eagle.screenblock")
    private let logger = OSLog(subsystem: "com.eagle.screenblock.ScreenBlockMonitor", category: "monitor")
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        os_log("🔥 intervalDidStart: %{public}@", log: logger, type: .fault, activity.rawValue)
        sharedDefaults?.set("intervalDidStart", forKey: "extensionLastEvent")
        sharedDefaults?.set(activity.rawValue, forKey: "extensionLastActivity")
        sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "extensionLastRan")
        sharedDefaults?.synchronize()
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        os_log("🔥 intervalDidEnd: %{public}@", log: logger, type: .fault, activity.rawValue)
        sharedDefaults?.set("intervalDidEnd", forKey: "extensionLastEvent")
        sharedDefaults?.set(activity.rawValue, forKey: "extensionLastActivity")
        sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "extensionLastRan")
        sharedDefaults?.synchronize()
        
        if activity.rawValue == "com.eagle.screenblock.pause" {
            os_log("⏰ pause ended — re-shielding", log: logger, type: .fault)
            reshieldApps()
            sharedDefaults?.removeObject(forKey: "schedulePauseEndTime")
            sharedDefaults?.synchronize()
        }
    }
    
    private func reshieldApps() {
        let blockingMode = sharedDefaults?.string(forKey: "blockingMode") ?? "specific_apps"
        let key = blockingMode == "specific_apps" ? "blockedApps" : "allowedApps"
        
        guard let data = sharedDefaults?.data(forKey: key),
              let selection = try? JSONDecoder().decode(
                FamilyActivitySelection.self, from: data
              ) else {
            os_log("❌ reshieldApps: no app tokens found", log: logger, type: .fault)
            sharedDefaults?.set("reshieldApps_noTokens", forKey: "extensionLastEvent")
            sharedDefaults?.synchronize()
            return
        }
        
        store.shield.applications = selection.applicationTokens
        os_log("✅ reshielded %d apps", log: logger, type: .fault, selection.applicationTokens.count)
        sharedDefaults?.set("reshieldApps_success", forKey: "extensionLastEvent")
        sharedDefaults?.synchronize()
    }
}
