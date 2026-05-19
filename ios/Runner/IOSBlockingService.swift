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
        // save config to shared defaults
        // so DeviceActivityMonitor extension can read it
        sharedDefaults?.set(blockingMode, forKey: "blockingMode")
        
        // for iOS we use FamilyActivityPicker selection
        // stored from when user picked apps
        // start monitoring with time threshold
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(
                hour: 0, minute: 0
            ),
            intervalEnd: DateComponents(
                hour: 23, minute: 59
            ),
            repeats: false
        )
        
        let threshold = DateComponents(
            minute: limitMinutes
        )
        
        let event = DeviceActivityEvent(
            applications: getStoredAppTokens(
                mode: blockingMode
            ),
            threshold: threshold
        )
        
        do {
            try activityCenter.startMonitoring(
                activityName,
                during: schedule,
                events: [
                    DeviceActivityEvent.Name(
                        "com.eagle.screenblock.threshold"
                    ): event
                ]
            )
            print("✅ iOS monitoring started")
        } catch {
            print("❌ monitoring failed: \(error)")
        }
    }
    
    func stopBlocking() {
        activityCenter.stopMonitoring([activityName])
        store.clearAllSettings()
        print("✅ iOS monitoring stopped")
    }
    
    // MARK: - App Selection
    
    func saveAppSelection(
        _ selection: FamilyActivitySelection,
        forKey key: String
    ) {
        if let data = try? JSONEncoder().encode(selection) {
            sharedDefaults?.set(data, forKey: key)
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
    
    func getTodayUsage() async -> [String: Int] {
        // DeviceActivityReport handles this in iOS 16.2+
        // return empty for now — will implement with
        // DeviceActivityReport extension
        return [:]
    }
}
