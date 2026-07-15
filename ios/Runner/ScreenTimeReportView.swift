import SwiftUI
import DeviceActivity


@available(iOS 16.0, *)
struct ScreenTimeReportView: View {
    let id: UUID
    let targetDate: Date // 👈 new — which day this report should show

    @State private var reportId = UUID() // 👈 internal state to force reload

    private var filter: DeviceActivityFilter {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: targetDate)
        // 👇 if targetDate is today, end at "now"; otherwise end at the day's midnight boundary
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
                .id(reportId) // 👈 use internal state id
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    // 👇 force fresh reload every time view appears
                    reportId = UUID()
                }
        }
        .background(Color(red: 22/255, green: 22/255, blue: 42/255))
    }
}
