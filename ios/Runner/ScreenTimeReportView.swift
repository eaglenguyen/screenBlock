import SwiftUI
import DeviceActivity

@available(iOS 16.0, *)
struct ScreenTimeReportView: View {
    let id: UUID
    let targetDate: Date

    @State private var reportId = UUID()
    @State private var showRetryPrompt = false

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
        ZStack {
            // 👇 fallback layer — visible until real content paints over it
            VStack(spacing: 16) {
                if showRetryPrompt {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 40))
                        .foregroundColor(Color(red: 160/255, green: 160/255, blue: 160/255))
                    Text("Try again later")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(red: 160/255, green: 160/255, blue: 160/255))
                    Button(action: {
                        showRetryPrompt = false
                        reportId = UUID() // force a fresh attempt
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            showRetryPrompt = true
                        }
                    }) {
                        Text("Retry")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(red: 26/255, green: 18/255, blue: 8/255))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color(red: 237/255, green: 184/255, blue: 42/255))
                            .clipShape(Capsule())
                    }
                } else {
                    ProgressView()
                        .tint(Color(red: 237/255, green: 184/255, blue: 42/255))
                }
            }

            DeviceActivityReport(.init("Total Activity"), filter: filter)
                .id(reportId)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(red: 0x25/255, green: 0x25/255, blue: 0x25/255))
        .onAppear {
            // 👇 if nothing has rendered over the fallback within 6 seconds, show the retry prompt
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                showRetryPrompt = true
            }
        }
    }
}
