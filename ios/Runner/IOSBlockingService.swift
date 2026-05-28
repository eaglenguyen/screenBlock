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
    private let sharedDefaults = UserDefaults(
        suiteName: "group.com.eagle.screenblock"
    )
    
    // activity name for our blocking session
    private let activityName = DeviceActivityName(
        "com.eagle.screenblock.session"
    )
    
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
        limitMinutes: Int
    ) {
        sharedDefaults?.set(true, forKey: "isBlocking")
        sharedDefaults?.set(blockingMode, forKey: "blockingMode")
        sharedDefaults?.set(
            Date().timeIntervalSince1970,
            forKey: "sessionStartTime"
        )
        sharedDefaults?.set(limitMinutes, forKey: "sessionMinutes")
        
        // immediately shield apps
        let appTokens = getStoredAppTokens(mode: blockingMode)

        guard !appTokens.isEmpty else {
            print("❌ no app tokens found")
            return
        }

        // immediately shield apps — same as Android instant blocking
        store.shield.applications = appTokens
    }
    
    
    func stopBlocking() {
        // clear session state
        sharedDefaults?.set(false, forKey: "isBlocking")
        sharedDefaults?.removeObject(forKey: "sessionStartTime")
        store.clearAllSettings()
        activityCenter.stopMonitoring([activityName])
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
            // clear the saved selection
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
    
    func getStoredAppTokens(
        mode: String
    ) -> Set<ApplicationToken> {
        let key = mode == "specific_apps"
            ? "blockedApps"
            : "allowedApps"
        
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
        // DeviceActivityReport runs in the extension
        // we trigger it and return results via shared defaults
        let center = DeviceActivityCenter()
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        let schedule = DeviceActivitySchedule(
            intervalStart: calendar.dateComponents(
                [.hour, .minute],
                from: startOfDay
            ),
            intervalEnd: calendar.dateComponents(
                [.hour, .minute],
                from: now
            ),
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
