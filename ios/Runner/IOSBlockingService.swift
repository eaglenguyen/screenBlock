//
//  IOSBlockingService.swift
//  Runner
//
//  Created by Egor on 5/18/26.
//

import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings
import Combine
import UserNotifications
import ActivityKit


@available(iOS 16.0, *)
class IOSBlockingService: NSObject {
    
    // Live activity logic
    private var currentActivity: Any? // 👈 no generic constraint, avoids the availability requirement on the property itself
    
    func getOpenAttemptCount(appName: String) -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        let dateKey = "openAttemptCountDate_\(appName)"
        let countKey = "openAttemptCount_\(appName)"

        let lastCountDate = sharedDefaults?.double(forKey: dateKey) ?? 0
        let lastCountDay = lastCountDate > 0
            ? Calendar.current.startOfDay(for: Date(timeIntervalSince1970: lastCountDate))
            : Date.distantPast

        if lastCountDay != today {
            return 0
        }
        return sharedDefaults?.integer(forKey: countKey) ?? 0
    }
    
    func startLiveActivity(endTime: Date, isOnBreak: Bool = false, isPomodoro: Bool = false) {
        guard #available(iOS 16.2, *) else { return }
        endLiveActivity()
        let attributes = PauseNowActivityAttributes(sessionType: "manual", isPomodoro: isPomodoro)
        let initialState = PauseNowActivityAttributes.ContentState(
            endTime: endTime,
            isPaused: false,
            pausedRemainingSeconds: 0,
            isOnBreak: isOnBreak
        )
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            NSLog("✅ Live Activity started (isPomodoro: \(isPomodoro))")
        } catch {
            NSLog("❌ Live Activity start error: \(error)")
        }
    }

    func updateLiveActivity(endTime: Date, isPaused: Bool, pausedRemainingSeconds: Int = 0, isOnBreak: Bool = false) {
        guard #available(iOS 16.2, *) else { return }
        Task {
            for activity in Activity<PauseNowActivityAttributes>.activities {
                let newState = PauseNowActivityAttributes.ContentState(
                    endTime: endTime,
                    isPaused: isPaused,
                    pausedRemainingSeconds: pausedRemainingSeconds,
                    isOnBreak: isOnBreak
                )
                await activity.update(.init(state: newState, staleDate: nil))
            }
        }
    }

    func endLiveActivity() {
        guard #available(iOS 16.2, *) else { return }
        Task {
            for activity in Activity<PauseNowActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            currentActivity = nil
        }
    }
    
    func liftShieldOnly() {
        store.clearAllSettings()
        sharedDefaults?.set(false, forKey: "isBlocking")
        sharedDefaults?.synchronize()
        activityCenter.stopMonitoring([activityName])
        // 👈 deliberately no endLiveActivity() call here
    }
    
    func checkLiveActivityPauseState() -> [String: Any] {
        let isPaused = sharedDefaults?.bool(forKey: "liveActivityIsPaused") ?? false
        let remaining = sharedDefaults?.integer(forKey: "liveActivityPausedRemainingSeconds") ?? 0
        let resumedEndTime = sharedDefaults?.double(forKey: "liveActivityResumedEndTime") ?? 0
        return [
            "isPaused": isPaused,
            "pausedRemainingSeconds": remaining,
            "resumedEndTime": resumedEndTime,
        ]
    }
    
    func syncUninstallProtection() {
        let enabled = sharedDefaults?.bool(forKey: "uninstallProtectionEnabled") ?? false
        let isManualBlocking = sharedDefaults?.bool(forKey: "isBlocking") ?? false
        let isScheduleActive = sharedDefaults?.bool(forKey: "isScheduleCurrentlyActive") ?? false
        let shouldRestrict = enabled && (isManualBlocking || isScheduleActive)
        store.application.denyAppRemoval = shouldRestrict
        NSLog("🔒 syncUninstallProtection — enabled: \(enabled), manual: \(isManualBlocking), schedule: \(isScheduleActive), restricted: \(shouldRestrict)")
    }
    
    // Ends here
    
    static let shared = IOSBlockingService()
    
    private let center = AuthorizationCenter.shared
    private let activityCenter = DeviceActivityCenter()
    let store = ManagedSettingsStore()
    private let sharedDefaults = UserDefaults(suiteName: "group.com.eagle.pausenow")
    private var pauseTimer: Timer?
    private let activityName = DeviceActivityName("com.eagle.pausenow.session")
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> Bool {
        do {
            try await center.requestAuthorization(for: .individual)
            return true
        } catch {
            print("❌ FamilyControls auth failed: \(error)")
            return false
        }
    }
    
    func isAuthorized() -> Bool {
        return center.authorizationStatus == .approved
    }
    
    // MARK: - Blocking
    func startBlocking(
        packageNames: [String],
        blockingMode: String,
        limitMinutes: Int,
        sessionType: String = "manual",
        scheduleId: String? = nil,
        isPomodoro: Bool = false
    ) {
        sharedDefaults?.set(false, forKey: "unblockButtonTapped")
        sharedDefaults?.set(true, forKey: "isBlocking")
        sharedDefaults?.set(blockingMode, forKey: "blockingMode")
        sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "sessionStartTime")
        sharedDefaults?.set(limitMinutes, forKey: "sessionMinutes")
        sharedDefaults?.set(sessionType, forKey: "sessionType")
        if let scheduleId = scheduleId {
            sharedDefaults?.set(scheduleId, forKey: "activeScheduleId")
        } else {
            sharedDefaults?.removeObject(forKey: "activeScheduleId")
        }
        sharedDefaults?.synchronize()
        applyShield(mode: blockingMode, scheduleId: scheduleId)
        syncUninstallProtection()

        if sessionType == "manual" {
            let endTime = Date().addingTimeInterval(TimeInterval(limitMinutes * 60))
            startLiveActivity(endTime: endTime, isPomodoro: isPomodoro) // 👈 only one call now
        }
    }

    func stopBlocking() {
        sharedDefaults?.set(false, forKey: "unblockButtonTapped") // 👈 new — reset on pause
        sharedDefaults?.set(false, forKey: "isBlocking")
        sharedDefaults?.removeObject(forKey: "sessionStartTime")
        sharedDefaults?.removeObject(forKey: "sessionType")
        sharedDefaults?.synchronize()
        store.clearAllSettings()
        activityCenter.stopMonitoring([activityName])
        endLiveActivity() // 👈 new

    }

    func stopBlockingCompletely() {
        sharedDefaults?.set(false, forKey: "unblockButtonTapped") // 👈 new — reset on pause
        sharedDefaults?.set(false, forKey: "isBlocking")
        sharedDefaults?.removeObject(forKey: "sessionStartTime")
        sharedDefaults?.removeObject(forKey: "sessionType")
        sharedDefaults?.removeObject(forKey: "schedulePauseEndTime")
        sharedDefaults?.synchronize()
        store.clearAllSettings()
        activityCenter.stopMonitoring([activityName])
        pauseTimer?.invalidate()
        pauseTimer = nil
        cancelPauseNotification()
        endLiveActivity()
        syncUninstallProtection() // 👈 new

    }

    // MARK: - Pause / Break
    var onPauseEnded: (() -> Void)?

    func stopSessionMonitoring() {
        activityCenter.stopMonitoring([activityName]) // stops "com.eagle.pausenow.session"
    }

    func pauseBlocking(forMinutes minutes: Int) {
        NSLog("⏸ pauseBlocking for \(minutes) minutes")
        sharedDefaults?.set(false, forKey: "unblockButtonTapped") // 👈 new — reset on pause
        let now = Date()
        let pauseEndsAt = now.addingTimeInterval(TimeInterval(minutes * 60))
        
        updateLiveActivity(endTime: pauseEndsAt, isPaused: true)

        pauseTimer?.invalidate()
        pauseTimer = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(minutes * 60),
            repeats: false
        ) { [weak self] _ in
            NSLog("⏱ native pause timer fired — resuming blocking")
            self?.resumeBlocking()
            self?.onPauseEnded?()
        }

        sharedDefaults?.set(pauseEndsAt.timeIntervalSince1970, forKey: "schedulePauseEndTime")
        sharedDefaults?.synchronize()

        store.clearAllSettings()
        activityCenter.stopMonitoring([DeviceActivityName("com.eagle.pausenow.pause")])

        let calendar = Calendar.current
        let roundedStart = calendar.date(
            bySetting: .second,
            value: 0,
            of: now.addingTimeInterval(60)
        ) ?? now
        let startComponents = calendar.dateComponents([.hour, .minute], from: roundedStart)

        let schedule: DeviceActivitySchedule

        if minutes < 15 {
            let endDate = now.addingTimeInterval(30 * 60)
            let endComponents = calendar.dateComponents([.hour, .minute], from: endDate)
            let warningMinutes = 30 - minutes
            schedule = DeviceActivitySchedule(
                intervalStart: startComponents,
                intervalEnd: endComponents,
                repeats: false,
                warningTime: DateComponents(minute: warningMinutes)
            )
            NSLog("⏸ warningTime trick: 30min window, warning at \(minutes) mins (warningMinutes=\(warningMinutes))")
        } else {
            let adjustedEnd = pauseEndsAt.addingTimeInterval(60)
            let endComponents = calendar.dateComponents([.hour, .minute], from: adjustedEnd)
            schedule = DeviceActivitySchedule(
                intervalStart: startComponents,
                intervalEnd: endComponents,
                repeats: false
            )
            NSLog("⏸ exact schedule: ends in \(minutes) mins + 1 min buffer")
        }

        do {
            try activityCenter.startMonitoring(
                DeviceActivityName("com.eagle.pausenow.pause"),
                during: schedule
            )
            NSLog("✅ pause scheduled")
            sharedDefaults?.set("success", forKey: "monitoringStatus")
        } catch {
            NSLog("❌ startMonitoring error: \(error)")
            sharedDefaults?.set("failed:\(error.localizedDescription)", forKey: "monitoringStatus")
        }

        cancelPauseNotification()

    }




    private func cancelPauseNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: ["com.eagle.pausenow.pauseResume"]
            )
    }
    func resumeBlocking() {
        sharedDefaults?.set(false, forKey: "unblockButtonTapped") // 👈 new — reset on pause
        let currentSessionType = sharedDefaults?.string(forKey: "sessionType") ?? "manual"
        let scheduleId = sharedDefaults?.string(forKey: "activeScheduleId") // 👈 new
        sharedDefaults?.removeObject(forKey: "schedulePauseEndTime")
        sharedDefaults?.synchronize()

        activityCenter.stopMonitoring([DeviceActivityName("com.eagle.pausenow.pause")])
        pauseTimer?.invalidate()
        pauseTimer = nil
        cancelPauseNotification()

        let blockingMode = sharedDefaults?.string(forKey: "blockingMode") ?? "specific_apps"
        applyShield(mode: blockingMode, scheduleId: scheduleId) // 👈 pass through
        
        // 👇 new — restore the Live Activity to BLOCKING with the original session's remaining time
        if currentSessionType == "manual" {
            let sessionStart = sharedDefaults?.double(forKey: "sessionStartTime") ?? 0
            let sessionMinutes = sharedDefaults?.integer(forKey: "sessionMinutes") ?? 0
            if sessionStart > 0 {
                let originalEndTime = Date(timeIntervalSince1970: sessionStart).addingTimeInterval(TimeInterval(sessionMinutes * 60))
                updateLiveActivity(endTime: originalEndTime, isPaused: false)
            }
        }

        // 👇 only notify Flutter for manual sessions
        if currentSessionType == "manual" {
            onPauseEnded?()
        }
    }



    func getPersistedSession() -> [String: Any] {
        let isBlocking = sharedDefaults?.bool(forKey: "isBlocking") ?? false
        let sessionType = sharedDefaults?.string(forKey: "sessionType") ?? "manual"
        let startTime = sharedDefaults?.double(forKey: "sessionStartTime") ?? 0
        let minutes = sharedDefaults?.integer(forKey: "sessionMinutes") ?? 0
        NSLog("🔄 getPersistedSession: isBlocking=\(isBlocking) sessionType=\(sessionType) minutes=\(minutes)")
        return [
            "isBlocking": isBlocking,
            "sessionType": sessionType,
            "startTime": startTime,
            "minutes": minutes
        ]
    }

    // MARK: - App Selection

    func saveAppSelection(
        _ selection: FamilyActivitySelection,
        forKey key: String
    ) {
        guard let defaults = sharedDefaults else {
            print("🦅 sharedDefaults nil")
            return
        }

        do {
            let data = try JSONEncoder().encode(selection)
            defaults.set(data, forKey: key)
            defaults.synchronize()
            print("🦅 saved \(selection.applicationTokens.count) tokens for key: \(key)")
        } catch {
            print("🦅 encoding failed: \(error)")
        }
    }

    func getStoredAppTokens(mode: String) -> Set<ApplicationToken> {
        let key = mode == "specific_apps" ? "blockedApps" : "allowedApps"

        guard let data = sharedDefaults?.data(forKey: key),
              let selection = try? JSONDecoder().decode(
                FamilyActivitySelection.self,
                from: data
              )
        else { return [] }

        return selection.applicationTokens
    }

    // MARK: - Usage Stats
    
    func getTotalScreenTimeSeconds() -> Double {
        return sharedDefaults?.double(forKey: "totalScreenTimeSeconds") ?? 0
    }

    func fetchTodayUsage() async -> [[String: Any]] {
        let center = DeviceActivityCenter()
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)

        let schedule = DeviceActivitySchedule(
            intervalStart: calendar.dateComponents([.hour, .minute], from: startOfDay),
            intervalEnd: calendar.dateComponents([.hour, .minute], from: now),
            repeats: false
        )

        do {
            try center.startMonitoring(
                DeviceActivityName("com.eagle.pausenow.stats"),
                during: schedule
            )
        } catch {
            print("❌ stats monitoring error: \(error)")
        }

        return []
    }

    func checkAuthorizationStatus() {
        let status = center.authorizationStatus
        NSLog("🦅 FamilyControls auth status: \(status)")
        switch status {
        case .notDetermined:
            NSLog("🦅 not determined — needs authorization")
        case .denied:
            NSLog("🦅 denied — user rejected")
        case .approved:
            NSLog("🦅 approved ✅")
        case .approvedWithDataAccess:
            NSLog("🦅 approved WITH data access ✅ — stats should work")
        @unknown default:
            NSLog("🦅 unknown status")
        }
    }

        // MARK - Shield
    func applyShield(mode: String, scheduleId: String? = nil) {
        store.clearAllSettings()

        switch mode {
        case "specific_apps":
            let tokens: Set<ApplicationToken>
            if let scheduleId = scheduleId {
                tokens = getScheduleTokens(scheduleId: scheduleId, blockingMode: "specific_apps") // 👈 per-schedule
            } else {
                tokens = getStoredAppTokens(mode: "specific_apps") // 👈 manual blocking, unchanged, global key
            }
            guard !tokens.isEmpty else {
                NSLog("❌ applyShield: no blocked app tokens found")
                return
            }
            store.shield.applications = tokens
            NSLog("🛡 shielding \(tokens.count) specific apps (schedule: \(scheduleId ?? "manual"))")

        case "all_apps":
            let allowedTokens: Set<ApplicationToken>
            if let scheduleId = scheduleId {
                allowedTokens = getScheduleTokens(scheduleId: scheduleId, blockingMode: "all_apps")
            } else {
                allowedTokens = getStoredAppTokens(mode: "all_apps_except")
            }
            if allowedTokens.isEmpty {
                store.shield.applicationCategories = .all()
            } else {
                store.shield.applicationCategories = .all(except: allowedTokens)
            }

        default:
            NSLog("⚠️ applyShield: unknown mode '\(mode)'")
        }
    }
    
    
    
    // MARK: - Regular Schedule Monitoring

    func startScheduleMonitoring(scheduleId: String, startTime: String, endTime: String) {
        let calendar = Calendar.current

        let startParts = startTime.split(separator: ":").compactMap { Int($0) }
        let endParts = endTime.split(separator: ":").compactMap { Int($0) }

        guard startParts.count == 2, endParts.count == 2 else {
            NSLog("❌ startScheduleMonitoring: invalid time format for \(scheduleId)")
            return
        }

        let startComponents = DateComponents(hour: startParts[0], minute: startParts[1])
        let endComponents = DateComponents(hour: endParts[0], minute: endParts[1])

        // full-day-spanning schedule, repeats daily —
        // day-of-week filtering happens in the extension callback (same pattern as time-limit)
        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: true
        )

        let activityName = DeviceActivityName("com.eagle.pausenow.schedule.\(scheduleId)")

        do {
            try activityCenter.startMonitoring(activityName, during: schedule)
            NSLog("✅ schedule monitoring started for \(scheduleId): \(startTime)-\(endTime)")
        } catch {
            NSLog("❌ startScheduleMonitoring error for \(scheduleId): \(error)")
        }
    }

    func stopScheduleMonitoring(scheduleId: String) {
        let activityName = DeviceActivityName("com.eagle.pausenow.schedule.\(scheduleId)")
        activityCenter.stopMonitoring([activityName])
        NSLog("🛑 stopped schedule monitoring for \(scheduleId)")
    }

    func syncScheduleMonitoring(_ schedules: [[String: Any]]) {
        let allActivities = schedules.compactMap { schedule -> DeviceActivityName? in
            guard let id = schedule["id"] as? String else { return nil }
            return DeviceActivityName("com.eagle.pausenow.schedule.\(id)")
        }
        activityCenter.stopMonitoring(allActivities)

        for schedule in schedules {
            guard let id = schedule["id"] as? String,
                  let startTime = schedule["startTime"] as? String,
                  let endTime = schedule["endTime"] as? String,
                  let days = schedule["days"] as? [Int],           // 👈 added
                  let blockingMode = schedule["blockingType"] as? String, // 👈 added
                  let isActive = schedule["isActive"] as? Bool,
                  isActive
            else { continue }

            // 👇 save days + blockingMode so the extension can check them
            if let daysData = try? JSONEncoder().encode(days),
               let daysJson = String(data: daysData, encoding: .utf8) {
                sharedDefaults?.set(daysJson, forKey: "scheduleDays_\(id)")
            }
            sharedDefaults?.set(blockingMode, forKey: "scheduleBlockingMode_\(id)")

            startScheduleMonitoring(scheduleId: id, startTime: startTime, endTime: endTime)
        }
    }

    func unshieldScheduleApps(scheduleId: String, blockingMode: String) {
        let tokens = getScheduleTokens(scheduleId: scheduleId, blockingMode: blockingMode)
        guard !tokens.isEmpty else {
            NSLog("⚠️ unshieldScheduleApps: no tokens found for \(scheduleId)")
            return
        }

        var currentlyShielded = store.shield.applications ?? []
        currentlyShielded.subtract(tokens)
        store.shield.applications = currentlyShielded.isEmpty ? nil : currentlyShielded
        NSLog("✅ unshielded \(tokens.count) apps for schedule \(scheduleId)")
    }
    
    // MARK: - Time Limit Monitoring

    func startTimeLimitMonitoring(configId: String, limitMinutes: Int) {
        let saveKey = "timeLimitApps_\(configId)"
        guard let data = sharedDefaults?.data(forKey: saveKey),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data),
              !selection.applicationTokens.isEmpty
        else {
            NSLog("❌ startTimeLimitMonitoring: no tokens found for config \(configId)")
            return
        }

        let activityName = DeviceActivityName("com.eagle.pausenow.timelimit.\(configId)")
        let calendar = Calendar.current

        // full-day schedule — day-of-week filtering happens in the extension callback
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        // one event per app token, all sharing the same threshold
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        for (index, token) in selection.applicationTokens.enumerated() {
            let eventName = DeviceActivityEvent.Name("timelimit_\(configId)_\(index)")
            events[eventName] = DeviceActivityEvent(
                applications: [token],
                threshold: DateComponents(minute: limitMinutes)
            )
        }

        do {
            try activityCenter.startMonitoring(activityName, during: schedule, events: events)
            NSLog("✅ time-limit monitoring started for config \(configId), \(events.count) apps, limit=\(limitMinutes)min")
        } catch {
            NSLog("❌ startTimeLimitMonitoring error: \(error)")
        }
    }

    func stopTimeLimitMonitoring(configId: String) {
        let activityName = DeviceActivityName("com.eagle.pausenow.timelimit.\(configId)")
        activityCenter.stopMonitoring([activityName])
        NSLog("🛑 stopped time-limit monitoring for config \(configId)")
    }

    func syncTimeLimitConfigs(_ configs: [[String: Any]]) {
        // stop all existing time-limit monitoring first, then re-register from scratch —
        // simplest way to keep native state consistent with Dart's current config list
        let allActivities = configs.compactMap { config -> DeviceActivityName? in
            guard let id = config["id"] as? String else { return nil }
            return DeviceActivityName("com.eagle.pausenow.timelimit.\(id)")
        }
        activityCenter.stopMonitoring(allActivities)

        for config in configs {
            guard let id = config["id"] as? String,
                  let limitMinutes = config["limitMinutes"] as? Int,
                  let isActive = config["isActive"] as? Bool,
                  isActive
            else { continue }

            startTimeLimitMonitoring(configId: id, limitMinutes: limitMinutes)
        }
    }
    
    func unshieldConfigApps(configId: String) {
        let saveKey = "timeLimitApps_\(configId)"
        guard let data = sharedDefaults?.data(forKey: saveKey),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else {
            NSLog("⚠️ unshieldConfigApps: no tokens found for config \(configId)")
            return
        }

        var currentlyShielded = store.shield.applications ?? []
        currentlyShielded.subtract(selection.applicationTokens)
        store.shield.applications = currentlyShielded.isEmpty ? nil : currentlyShielded

        NSLog("✅ unshielded \(selection.applicationTokens.count) apps for config \(configId)")
    }
    
    func getScheduleTokens(scheduleId: String, blockingMode: String) -> Set<ApplicationToken> {
        let saveKey = "schedule_\(scheduleId)_\(blockingMode)"
        guard let data = sharedDefaults?.data(forKey: saveKey),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else { return [] }
        return selection.applicationTokens
    }
    
    
    func setAppRemovalRestricted(_ restricted: Bool) {
        store.application.denyAppRemoval = restricted
        NSLog("🔒 denyAppRemoval set to \(restricted)")
    }
    
    
    func setQuickBlocked(packageName: String, tokenData: Data, blocked: Bool) {
        // Note: iOS identifies apps by ApplicationToken, not package name —
        // this requires its own FamilyActivityPicker selection per quick-block app,
        // saved similarly to how schedule/time-limit tokens are saved
        guard let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: tokenData) else { return }
        var currentlyShielded = store.shield.applications ?? []
        if blocked {
            currentlyShielded.formUnion(selection.applicationTokens)
        } else {
            currentlyShielded.subtract(selection.applicationTokens)
        }
        store.shield.applications = currentlyShielded.isEmpty ? nil : currentlyShielded
    }
    
    func toggleQuickBlock(cardId: String, blocked: Bool) {
        guard let data = sharedDefaults?.data(forKey: "quickblock_\(cardId)"),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else { return }

        var shielded = store.shield.applications ?? []
        if blocked {
            shielded.formUnion(selection.applicationTokens)
        } else {
            shielded.subtract(selection.applicationTokens)
        }
        store.shield.applications = shielded.isEmpty ? nil : shielded
    }
    
    func hasQuickBlockSelection(cardId: String) -> Bool {
        return sharedDefaults?.data(forKey: "quickblock_\(cardId)") != nil
    }
    
    func resetQuickBlockSelection(cardId: String) {
        toggleQuickBlock(cardId: cardId, blocked: false)
        sharedDefaults?.removeObject(forKey: "quickblock_\(cardId)")
        sharedDefaults?.synchronize()
    }

    
    

}
