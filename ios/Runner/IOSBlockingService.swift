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

@available(iOS 16.0, *)
class IOSBlockingService: NSObject {
    
    static let shared = IOSBlockingService()
    
    private let center = AuthorizationCenter.shared
    private let activityCenter = DeviceActivityCenter()
    private let store = ManagedSettingsStore()
    private let sharedDefaults = UserDefaults(suiteName: "group.com.eagle.screenblock")
    private var pauseTimer: Timer?
    private let activityName = DeviceActivityName("com.eagle.screenblock.session")
    
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
        sessionType: String = "manual"
    ) {
        // 👇 use sharedDefaults? directly — not sharedDefaults.standard
        sharedDefaults?.set(true, forKey: "isBlocking")
        sharedDefaults?.set(blockingMode, forKey: "blockingMode")
        sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "sessionStartTime")
        sharedDefaults?.set(limitMinutes, forKey: "sessionMinutes")
        sharedDefaults?.set(sessionType, forKey: "sessionType")
        sharedDefaults?.synchronize()
        NSLog("🔄 startBlocking: sessionType=\(sessionType) minutes=\(limitMinutes)")

        let appTokens = getStoredAppTokens(mode: blockingMode)
        guard !appTokens.isEmpty else {
            print("❌ no app tokens found")
            return
        }
        store.shield.applications = appTokens
    }
    
    func stopBlocking() {
        sharedDefaults?.set(false, forKey: "isBlocking")
        sharedDefaults?.removeObject(forKey: "sessionStartTime")
        sharedDefaults?.removeObject(forKey: "sessionType")
        sharedDefaults?.synchronize()
        store.clearAllSettings()
        activityCenter.stopMonitoring([activityName])
    }
    
    func stopBlockingCompletely() {
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
    }
    
    // MARK: - Pause / Break

    func pauseBlocking(forMinutes minutes: Int) {
        NSLog("⏸ iOS pauseBlocking for \(minutes) minutes")
        
        let now = Date()
        let pauseEndsAt = now.addingTimeInterval(TimeInterval(minutes * 60))
        
        sharedDefaults?.set(pauseEndsAt.timeIntervalSince1970, forKey: "schedulePauseEndTime")
        sharedDefaults?.synchronize()
        
        // unshield immediately
        store.clearAllSettings()
        
        // stop any existing pause activity first
        activityCenter.stopMonitoring([DeviceActivityName("com.eagle.screenblock.pause")])
        
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: now)
        let endComponents = calendar.dateComponents([.hour, .minute], from: pauseEndsAt)
        
        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: false
        )
        
        do {
            try activityCenter.startMonitoring(
                DeviceActivityName("com.eagle.screenblock.pause"),
                during: schedule
            )
            NSLog("✅ DeviceActivity pause scheduled until \(pauseEndsAt)")
        } catch {
            NSLog("❌ DeviceActivity pause error: \(error.localizedDescription)")
        }
        
        // Swift Timer fallback — only fires if app is foregrounded
        pauseTimer?.invalidate()
        pauseTimer = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(minutes * 60),
            repeats: false
        ) { [weak self] _ in
            self?.resumeBlocking()
        }
        
        // notification — works even when app is backgrounded
        cancelPauseNotification()
        let content = UNMutableNotificationContent()
        content.title = "Break Over 🔒"
        content.body = "Blocking has resumed. Please close any blocked apps."
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(minutes * 60),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "com.eagle.screenblock.pauseResume",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                NSLog("❌ notification error: \(error)")
            } else {
                NSLog("🔔 resume notification scheduled")
            }
        }
        
        NSLog("⏸ pauseBlocking: will resume at \(pauseEndsAt)")
    }

    private func cancelPauseNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: ["com.eagle.screenblock.pauseResume"]
            )
    }

    func resumeBlocking() {
        NSLog("▶️ iOS resumeBlocking called")
        
        sharedDefaults?.removeObject(forKey: "schedulePauseEndTime")
        sharedDefaults?.synchronize()
        
        // stop the pause activity monitor
        activityCenter.stopMonitoring([DeviceActivityName("com.eagle.screenblock.pause")])
        
        // cancel timer fallback if running
        pauseTimer?.invalidate()
        pauseTimer = nil
        cancelPauseNotification()
        
        // re-shield apps
        let blockingMode = sharedDefaults?.string(forKey: "blockingMode") ?? "specific_apps"
        let appTokens = getStoredAppTokens(mode: blockingMode)
        guard !appTokens.isEmpty else {
            NSLog("❌ resumeBlocking: no app tokens found")
            return
        }
        store.shield.applications = appTokens
        NSLog("▶️ resumeBlocking: re-shielded \(appTokens.count) apps")
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

        if selection.applicationTokens.isEmpty &&
           selection.categoryTokens.isEmpty {
            defaults.removeObject(forKey: key)
            defaults.synchronize()
            print("🦅 cleared selection for key: \(key)")
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
                DeviceActivityName("com.eagle.screenblock.stats"),
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
}
