import SwiftUI
import DeviceActivity


@available(iOS 16.0, *)
struct ScreenTimeReportView: View {
    let id: UUID
    @State private var reportId = UUID() // 👈 internal state to force reload

    private var filter: DeviceActivityFilter {
        let now = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        return DeviceActivityFilter(
            segment: .daily(
                during: DateInterval(start: startOfDay, end: now)
            ),
            users: .all,
            devices: .init([.iPhone])
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("Screen Time")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 20) // 👈 added
                .padding(.bottom, 16)

            Divider()
                .background(Color.white.opacity(0.08))

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
