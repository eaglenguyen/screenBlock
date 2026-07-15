import DeviceActivity
import _DeviceActivity_SwiftUI
import ExtensionKit
import Foundation
import ManagedSettings

extension DeviceActivityReport.Context {
    static let totalActivity = Self("Total Activity")
}

struct AppUsageData: Identifiable {
    let id = UUID()
    let name: String
    let duration: TimeInterval
    let token: ApplicationToken? // 👈 add token for real icon

    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        if minutes > 0 { return "\(minutes)m" }
        return "<1m"
    }
}

struct ActivityConfiguration {
    let appUsages: [AppUsageData]
    let totalDuration: TimeInterval

    var formattedTotal: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}

struct TotalActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalActivity
    let content: (ActivityConfiguration) -> TotalActivityView

    func body(for configuration: ActivityConfiguration) -> TotalActivityView {
        TotalActivityView(configuration: configuration)
    }

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> ActivityConfiguration {
        var appUsages: [AppUsageData] = []
        var totalDuration: TimeInterval = 0
        var perDayTotals: [String: TimeInterval] = [:] // 👈 new — date string → total seconds

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]

        for await activityData in data {
            for await segment in activityData.activitySegments {
                var segmentTotal: TimeInterval = 0

                for await category in segment.categories {
                    for await app in category.applications {
                        let duration = app.totalActivityDuration
                        guard duration > 0 else { continue }
                        totalDuration += duration
                        segmentTotal += duration
                        appUsages.append(AppUsageData(
                            name: app.application.localizedDisplayName ?? "Unknown",
                            duration: duration,
                            token: app.application.token
                        ))
                    }
                }

                // 👇 key each day's total by its actual date
                let dayKey = dateFormatter.string(from: segment.dateInterval.start)
                perDayTotals[dayKey, default: 0] += segmentTotal
            }
        }

        appUsages.sort { $0.duration > $1.duration }

        // 👇 write per-day totals out, one key per date — Flutter can read all 7
        let sharedDefaults = UserDefaults(suiteName: "group.com.eagle.pausenow")
        for (day, total) in perDayTotals {
            sharedDefaults?.set(total, forKey: "screenTime_\(day)")
        }
        sharedDefaults?.set(Array(perDayTotals.keys), forKey: "screenTimeWeekDates")
        sharedDefaults?.synchronize()

        NSLog("📊 wrote \(perDayTotals.count) daily totals for the week")

        return ActivityConfiguration(
            appUsages: appUsages,
            totalDuration: totalDuration
        )
    }
}
