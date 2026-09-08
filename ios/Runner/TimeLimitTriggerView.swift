import Foundation
import SwiftUI
import DeviceActivity

@available(iOS 16.0, *)
struct TimeLimitTriggerView: View {
    @State private var reportId = UUID()

    private var filter: DeviceActivityFilter {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        return DeviceActivityFilter(
            segment: .daily(during: DateInterval(start: startOfDay, end: Date())),
            users: .all,
            devices: .init([.iPhone])
        )
    }

    var body: some View {
        DeviceActivityReport(.init("Time Limit Usage"), filter: filter)
            .id(reportId)
            .frame(width: 1, height: 1)
            .opacity(0)
            .onAppear {
                scheduleRetries()
            }
    }

    private func scheduleRetries() {
        for delay in [1, 2, 3] {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(delay)) {
                reportId = UUID()
            }
        }
    }
}
