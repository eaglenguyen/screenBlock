import SwiftUI
import DeviceActivity


@available(iOS 16.0, *)
struct ScreenTimeReportView: View {
    let id: UUID
    let targetDate: Date

    @State private var reportId = UUID() // 👈 restored

    private var filter: DeviceActivityFilter {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: targetDate)
        let isToday = calendar.isDateInToday(targetDate)
        let endOfInterval = isToday ? Date() : calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return DeviceActivityFilter(
            segment: .daily(
                during: DateInterval(start: startOfDay, end: endOfInterval)
            ),
            users: .all,
            devices: .init([.iPhone])
        )
    }

    var body: some View {
        DeviceActivityReport(.init("Total Activity"), filter: filter)
            .id(reportId)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                reportId = UUID()
            }
            .background(Color(red: 0x25/255, green: 0x25/255, blue: 0x25/255))
    }
}
