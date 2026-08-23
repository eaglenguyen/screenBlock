import AppIntents
import ActivityKit
import Foundation

@available(iOS 17.0, *)
struct PauseTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pause Timer"

    func perform() async throws -> some IntentResult {
        guard let activity = Activity<PauseNowActivityAttributes>.activities.first else {
            return .result()
        }

        let currentState = activity.content.state
        let remaining = max(0, Int(currentState.endTime.timeIntervalSinceNow))

        let newState = PauseNowActivityAttributes.ContentState(
            endTime: currentState.endTime,
            isPaused: true,
            pausedRemainingSeconds: remaining
        )
        await activity.update(.init(state: newState, staleDate: nil))

        // 👇 write to shared storage so the main app can sync next time it's opened
        let sharedDefaults = UserDefaults(suiteName: "group.com.eagle.pausenow")
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

        let newState = PauseNowActivityAttributes.ContentState(
            endTime: newEndTime,
            isPaused: false,
            pausedRemainingSeconds: 0
        )
        await activity.update(.init(state: newState, staleDate: nil))

        let sharedDefaults = UserDefaults(suiteName: "group.com.eagle.pausenow")
        sharedDefaults?.set(false, forKey: "liveActivityIsPaused")
        sharedDefaults?.set(newEndTime.timeIntervalSince1970, forKey: "liveActivityResumedEndTime")
        sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "liveActivityPauseChangedAt")
        sharedDefaults?.synchronize()

        return .result()
    }
}
