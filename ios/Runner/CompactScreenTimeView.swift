import SwiftUI
import DeviceActivity

@available(iOS 16.0, *)
struct CompactScreenTimeView: View {
    let id: UUID
    let targetDate: Date

    @State private var reportId = UUID()
    @State private var showRetryPrompt = false
    @State private var autoRetryCount = 0

    private var filter: DeviceActivityFilter {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: targetDate)
        let isToday = calendar.isDateInToday(targetDate)
        let endOfInterval = isToday ? Date() : calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        return DeviceActivityFilter(
            segment: .daily(during: DateInterval(start: startOfDay, end: endOfInterval)),
            users: .all,
            devices: .init([.iPhone])
        )
    }

    var body: some View {
        ZStack {
            // 👇 loading/retry layer FIRST (drawn underneath)
            if showRetryPrompt {
                VStack(spacing: 8) {
                    Text("Couldn't load")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 160/255, green: 160/255, blue: 160/255))
                }
            } else {
                ProgressView()
                    .tint(Color(red: 237/255, green: 184/255, blue: 42/255))
            }

            // 👇 report SECOND (drawn on top once it has real, opaque content)
            DeviceActivityReport(.init("Compact Activity"), filter: filter)
                .id(reportId)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(red: 0x25/255, green: 0x25/255, blue: 0x25/255))
        .onAppear {
            scheduleAutoRetry()
        }
    }

    private func scheduleAutoRetry() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if autoRetryCount < 3 {
                autoRetryCount += 1
                reportId = UUID()
                scheduleAutoRetry()
            } else {
                showRetryPrompt = true
            }
        }
    }
}
