import SwiftUI
import DeviceActivity

@available(iOS 16.0, *)
struct ScreenTimeReportView: View {
    let id: UUID
    let targetDate: Date
    @State private var reportId = UUID()
    @State private var showRetryPrompt = false

    private var isDark: Bool {
        UserDefaults(suiteName: "group.com.eagle.pausenow")?.bool(forKey: "appIsDarkMode") ?? true
    }

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
                        reportId = UUID()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            showRetryPrompt = true
                        }
                    }) {
                        Text("Retry")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(isDark ? Color(red: 26/255, green: 18/255, blue: 8/255) : .white) // 👈 needs to work on both accent colors, see note below
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(isDark ? Color(red: 0xD4/255, green: 0xCF/255, blue: 0xC4/255) : Color(red: 0x7D/255, green: 0xD3/255, blue: 0xB0/255)) // 👈 was hardcoded gold — now matches accent()
                            .clipShape(Capsule())
                    }
                } else {
                    ProgressView()
                        .tint(isDark ? Color(red: 0xD4/255, green: 0xCF/255, blue: 0xC4/255) : Color(red: 0x7D/255, green: 0xD3/255, blue: 0xB0/255)) // 👈 was hardcoded gold
                }
            }
            DeviceActivityReport(.init("Total Activity"), filter: filter)
                .id(reportId)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            DeviceActivityReport(.init("Compact Activity"), filter: filter)
                .id(reportId)
                .frame(width: 1, height: 1)
                .opacity(0)
                .allowsHitTesting(false)
        }
        .background(isDark ? Color(red: 0x25/255, green: 0x25/255, blue: 0x25/255) : Color.white) // 👈 was hardcoded dark only
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                showRetryPrompt = true
            }
        }
    }
}
