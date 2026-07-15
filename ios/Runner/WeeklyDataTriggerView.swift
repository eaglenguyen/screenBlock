//
//  WeeklyDataTriggerView.swift
//  Runner
//
//  Created by Egor on 7/15/26.
//

import Foundation
import SwiftUI
import DeviceActivity


@available(iOS 16.0, *)
struct WeeklyDataTriggerView: View {
    private var filter: DeviceActivityFilter {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 1
        let now = Date()
        let startOfWeek = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        )!
        return DeviceActivityFilter(
            segment: .weekly(during: DateInterval(start: startOfWeek, end: now)),
            users: .all,
            devices: .init([.iPhone])
        )
    }

    var body: some View {
        // 1x1, invisible — exists only to trigger makeConfiguration with a weekly filter
        DeviceActivityReport(.init("Total Activity"), filter: filter)
            .frame(width: 1, height: 1)
            .opacity(0)
    }
}
