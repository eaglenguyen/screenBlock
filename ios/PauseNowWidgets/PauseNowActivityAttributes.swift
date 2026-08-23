//
//  PauseNowActivityAttributes.swift
//  Runner
//
//  Created by Egor on 8/22/26.
//

import ActivityKit
import Foundation

@available(iOS 16.1, *) // 👈 add this — protects the struct itself when compiled into Runner (15.6 target)
struct PauseNowActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var endTime: Date
        var isPaused: Bool // 👈 new
        var pausedRemainingSeconds: Int
        var isOnBreak: Bool

    }

    var sessionType: String // "manual" — reserved for future use (schedule/pomodoro)
}
