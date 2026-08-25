import AppIntents
import FamilyControls
import ActivityKit
import ManagedSettings
import Foundation

@available(iOS 17.0, *)
struct PauseTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pause Timer"

    func perform() async throws -> some IntentResult {
        UserDefaults(suiteName: "group.com.eagle.pausenow")?.set(true, forKey: "debugPauseTapped")
        guard let activity = Activity<PauseNowActivityAttributes>.activities.first else {
            return .result()
        }
        let currentState = activity.content.state
        let remaining = max(0, Int(currentState.endTime.timeIntervalSinceNow))

        // 👇 new — lift the shield directly, same mechanism as liftShieldOnly()
        let store = ManagedSettingsStore()
        store.clearAllSettings()

        let newState = PauseNowActivityAttributes.ContentState(
            endTime: currentState.endTime,
            isPaused: true,
            pausedRemainingSeconds: remaining,
            isOnBreak: currentState.isOnBreak
        )
        await activity.update(.init(state: newState, staleDate: nil))

        let sharedDefaults = UserDefaults(suiteName: "group.com.eagle.pausenow")
        sharedDefaults?.set(true, forKey: "isBlocking") // 👈 new — keep native state consistent
        sharedDefaults?.set(true, forKey: "liveActivityIsPaused")
        sharedDefaults?.set(remaining, forKey: "liveActivityPausedRemainingSeconds")
        sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "liveActivityPauseChangedAt")
        sharedDefaults?.synchronize()

        return .result()
    }
}

@available(iOS 17.0, *)
struct ResumeTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Resume Timer"

    func perform() async throws -> some IntentResult {
        guard let activity = Activity<PauseNowActivityAttributes>.activities.first else {
            return .result()
        }
        let currentState = activity.content.state
        let newEndTime = Date().addingTimeInterval(TimeInterval(currentState.pausedRemainingSeconds))

        // 👇 new — re-apply the shield using the same stored tokens the app already saved
        let sharedDefaults = UserDefaults(suiteName: "group.com.eagle.pausenow")
        let store = ManagedSettingsStore()
        if let data = sharedDefaults?.data(forKey: "blockedApps"),
           let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            store.shield.applications = selection.applicationTokens
        }

        let newState = PauseNowActivityAttributes.ContentState(
            endTime: newEndTime,
            isPaused: false,
            pausedRemainingSeconds: 0,
            isOnBreak: currentState.isOnBreak
        )
        await activity.update(.init(state: newState, staleDate: nil))

        sharedDefaults?.set(false, forKey: "liveActivityIsPaused")
        sharedDefaults?.set(newEndTime.timeIntervalSince1970, forKey: "liveActivityResumedEndTime")
        sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "liveActivityPauseChangedAt")
        sharedDefaults?.synchronize()

        return .result()
    }
}
