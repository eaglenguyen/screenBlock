import DeviceActivity
import FamilyControls
import ManagedSettings
import Foundation
import os

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    
    let store = ManagedSettingsStore()
    let sharedDefaults = UserDefaults(suiteName: "group.com.eagle.pausenow")
    private let logger = OSLog(subsystem: "com.eagle.pausenow.pausenowMonitor", category: "monitor")
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        sharedDefaults?.set("intervalDidStart", forKey: "extensionLastEvent")
        sharedDefaults?.set(activity.rawValue, forKey: "extensionLastActivity")
        sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "extensionLastRan")
        sharedDefaults?.synchronize()
        
        // 👇 new — regular schedule start
        if activity.rawValue.hasPrefix("com.eagle.pausenow.schedule.") {
            let scheduleId = activity.rawValue.replacingOccurrences(
                of: "com.eagle.pausenow.schedule.", with: ""
            )
            guard isScheduleActiveToday(scheduleId: scheduleId) else {
                os_log("⏭ schedule interval started but not active today, skipping shield", log: logger, type: .fault)
                return
            }
            shieldScheduleApps(scheduleId: scheduleId)
        }
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        os_log("🔥 intervalDidEnd: %{public}@", log: logger, type: .fault, activity.rawValue)
        sharedDefaults?.set("intervalDidEnd", forKey: "extensionLastEvent")
        sharedDefaults?.set(activity.rawValue, forKey: "extensionLastActivity")
        sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "extensionLastRan")
        sharedDefaults?.synchronize()
        
        if activity.rawValue == "com.eagle.pausenow.pause" {
            if sharedDefaults?.object(forKey: "schedulePauseEndTime") != nil {
                reshieldApps()
            } else {
                os_log("⏭ pause intervalDidEnd fired but no active pause tracked — skipping stray reshield", log: logger, type: .fault)
            }
            sharedDefaults?.removeObject(forKey: "schedulePauseEndTime")
            sharedDefaults?.synchronize()
        }
        
        // 👇 new — regular schedule end, ALWAYS unshield regardless of day
        if activity.rawValue.hasPrefix("com.eagle.pausenow.schedule.") {
            let scheduleId = activity.rawValue.replacingOccurrences(
                of: "com.eagle.pausenow.schedule.", with: ""
            )
            unshieldScheduleAppsInExtension(scheduleId: scheduleId)
        }
        
    }
    
    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        
        if activity.rawValue == "com.eagle.pausenow.pause" {
            NSLog("⏰ pause warning fired — re-shielding now")
            sharedDefaults?.set("intervalWillEndWarning", forKey: "extensionLastEvent")
            sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "extensionLastRan")
            sharedDefaults?.synchronize()
            reshieldApps()
        }
    }
    
    private func reshieldApps() {
        let blockingMode = sharedDefaults?.string(forKey: "blockingMode") ?? "specific_apps"
        let scheduleId = sharedDefaults?.string(forKey: "activeScheduleId") // 👈 new

        let selection: FamilyActivitySelection?
        if let scheduleId = scheduleId {
            let key = "schedule_\(scheduleId)_\(blockingMode)"
            guard let data = sharedDefaults?.data(forKey: key),
                  let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
            else {
                os_log("❌ reshieldApps: no per-schedule tokens found", log: logger, type: .fault)
                return
            }
            selection = decoded
        } else {
            let key = blockingMode == "specific_apps" ? "blockedApps" : "allowedApps"
            guard let data = sharedDefaults?.data(forKey: key),
                  let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
            else {
                os_log("❌ reshieldApps: no manual tokens found", log: logger, type: .fault)
                return
            }
            selection = decoded
        }

        guard let selection = selection else { return }
        store.shield.applications = selection.applicationTokens
        os_log("✅ reshielded %d apps", log: logger, type: .fault, selection.applicationTokens.count)
    }
    
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        sharedDefaults?.set("eventDidReachThreshold", forKey: "extensionLastEvent")
        sharedDefaults?.set(activity.rawValue, forKey: "extensionLastActivity")
        sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "extensionLastRan")
        sharedDefaults?.synchronize()

        // activity name format: "com.eagle.pausenow.timelimit.<configId>"
        guard activity.rawValue.hasPrefix("com.eagle.pausenow.timelimit.") else { return }
        let configId = activity.rawValue.replacingOccurrences(
            of: "com.eagle.pausenow.timelimit.", with: ""
        )

        guard isConfigActiveToday(configId: configId) else {
            os_log("⏭ time-limit threshold hit but not active today, skipping shield", log: logger, type: .fault)
            return
        }

        shieldTimeLimitApps(configId: configId)
    }

    private func isConfigActiveToday(configId: String) -> Bool {
        guard let daysJson = sharedDefaults?.string(forKey: "timeLimitDays_\(configId)"),
              let data = daysJson.data(using: .utf8),
              let days = try? JSONDecoder().decode([Int].self, from: data)
        else { return true } // fail open — if we can't read days, don't block the shield

        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        // Calendar: Sunday=1...Saturday=7 → convert to Mon=0...Sun=6
        let dayIndex = weekday == 1 ? 6 : weekday - 2

        return days.contains(dayIndex)
    }

    private func shieldTimeLimitApps(configId: String) {
        let saveKey = "timeLimitApps_\(configId)"
        guard let data = sharedDefaults?.data(forKey: saveKey),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else {
            return
        }

        // 👇 merge with whatever's already shielded, don't overwrite existing shields
        var currentlyShielded = store.shield.applications ?? []
        currentlyShielded.formUnion(selection.applicationTokens)
        store.shield.applications = currentlyShielded

        os_log("🛡 time-limit shield applied for config %{public}@, %d apps",
               log: logger, type: .fault, configId, selection.applicationTokens.count)
    }
    
    // private helpers for new schedule day-checking + shield/unshield branches
    
    private func isScheduleActiveToday(scheduleId: String) -> Bool {
        guard let daysJson = sharedDefaults?.string(forKey: "scheduleDays_\(scheduleId)"),
              let data = daysJson.data(using: .utf8),
              let days = try? JSONDecoder().decode([Int].self, from: data)
        else { return true } // fail open

        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let dayIndex = weekday == 1 ? 6 : weekday - 2 // Sun=1..Sat=7 → Mon=0..Sun=6

        return days.contains(dayIndex)
    }

    private func shieldScheduleApps(scheduleId: String) {
        let blockingMode = sharedDefaults?.string(forKey: "scheduleBlockingMode_\(scheduleId)") ?? "specific_apps"
        let key = "schedule_\(scheduleId)_\(blockingMode)"

        guard let data = sharedDefaults?.data(forKey: key),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else {
            os_log("❌ shieldScheduleApps: no tokens for %{public}@", log: logger, type: .fault, scheduleId)
            return
        }

        var currentlyShielded = store.shield.applications ?? []
        currentlyShielded.formUnion(selection.applicationTokens)
        store.shield.applications = currentlyShielded

        os_log("🛡 schedule shield applied for %{public}@, %d apps",
               log: logger, type: .fault, scheduleId, selection.applicationTokens.count)
    }

    private func unshieldScheduleAppsInExtension(scheduleId: String) {
        let blockingMode = sharedDefaults?.string(forKey: "scheduleBlockingMode_\(scheduleId)") ?? "specific_apps"
        let key = "schedule_\(scheduleId)_\(blockingMode)"

        guard let data = sharedDefaults?.data(forKey: key),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else {
            os_log("⚠️ unshieldScheduleAppsInExtension: no tokens for %{public}@", log: logger, type: .fault, scheduleId)
            return
        }

        var currentlyShielded = store.shield.applications ?? []
        currentlyShielded.subtract(selection.applicationTokens)
        store.shield.applications = currentlyShielded.isEmpty ? nil : currentlyShielded

        os_log("✅ schedule unshielded for %{public}@, %d apps",
               log: logger, type: .fault, scheduleId, selection.applicationTokens.count)
    }
}
