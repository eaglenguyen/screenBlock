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

@available(iOS 16.0, *)
class IOSBlockingService: NSObject {
    
    static let shared = IOSBlockingService()
    
    private let center = AuthorizationCenter.shared
    private let activityCenter = DeviceActivityCenter()
    private let store = ManagedSettingsStore()
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

        applyShield(mode: blockingMode)

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
    var onPauseEnded: (() -> Void)?

    func stopSessionMonitoring() {
        activityCenter.stopMonitoring([activityName]) // stops "com.eagle.pausenow.session"
    }

    func pauseBlocking(forMinutes minutes: Int) {
        NSLog("⏸ pauseBlocking for \(minutes) minutes")

        let now = Date()
        let pauseEndsAt = now.addingTimeInterval(TimeInterval(minutes * 60))

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

        let currentSessionType = sharedDefaults?.string(forKey: "sessionType") ?? "manual"

        sharedDefaults?.removeObject(forKey: "schedulePauseEndTime")
        sharedDefaults?.synchronize()

        activityCenter.stopMonitoring([DeviceActivityName("com.eagle.pausenow.pause")])
        pauseTimer?.invalidate()
        pauseTimer = nil
        cancelPauseNotification()

        let blockingMode = sharedDefaults?.string(forKey: "blockingMode") ?? "specific_apps"
        applyShield(mode: blockingMode)

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
    private func applyShield(mode: String) {
        store.clearAllSettings()

        switch mode {

        case "specific_apps":
            let tokens = getStoredAppTokens(mode: "specific_apps")
            guard !tokens.isEmpty else {
                NSLog("❌ applyShield: no blocked app tokens found")
                return
            }
            store.shield.applications = tokens
            NSLog("🛡 shielding \(tokens.count) specific apps")

        case "all_apps":
            let allowedTokens = getStoredAppTokens(mode: "all_apps_except")
            if allowedTokens.isEmpty {
                // no allowed app picked — shield everything
                store.shield.applicationCategories = .all()
                NSLog("🛡 shielding ALL categories (no exemptions)")
            } else {
                store.shield.applicationCategories = .all(except: allowedTokens)
                NSLog("🛡 shielding ALL categories except \(allowedTokens.count) apps")
            }

        default:
            NSLog("⚠️ applyShield: unknown mode '\(mode)'")
        }
    }
    
    func setSessionComplete() {
        sharedDefaults?.set(false, forKey: "isBlocking")
        sharedDefaults?.synchronize()
    }
}
