import SwiftUI
import DeviceActivity
import ManagedSettings
import FamilyControls


struct TotalActivityView: View {
    let configuration: ActivityConfiguration

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // ── Total header card ─────────────────────
                VStack(spacing: 6) {
                    Text(configuration.formattedTotal)
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)
                    Text("Total Screen Time Today")
                        .font(.system(size: 13))
                        .foregroundColor(Color(
                            red: 112/255, green: 112/255, blue: 160/255
                        ))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color(red: 30/255, green: 30/255, blue: 53/255))
                .cornerRadius(20)
                .padding(.horizontal, 16)
                .padding(.top, 16)

                if configuration.appUsages.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 40))
                            .foregroundColor(Color(
                                red: 112/255, green: 112/255, blue: 160/255
                            ))
                        Text("No usage data yet")
                            .foregroundColor(Color(
                                red: 112/255, green: 112/255, blue: 160/255
                            ))
                            .font(.system(size: 15))
                    }
                    .padding(.top, 60)
                } else {
                    // ── App list card ─────────────────────
                    VStack(spacing: 0) {
                        ForEach(
                            Array(configuration.appUsages.prefix(15).enumerated()),
                            id: \.element.id
                        ) { index, app in
                            AppUsageRow(
                                app: app,
                                maxDuration: configuration.appUsages.first?.duration ?? 1
                            )
                            if index < min(configuration.appUsages.count, 15) - 1 {
                                Divider()
                                    .background(Color(
                                        red: 42/255, green: 42/255, blue: 72/255
                                    ))
                                    .padding(.leading, 64)
                            }
                        }
                    }
                    .background(Color(red: 30/255, green: 30/255, blue: 53/255))
                    .cornerRadius(20)
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 40)
        }
        .background(Color(red: 22/255, green: 22/255, blue: 42/255))
    }
}

struct AppUsageRow: View {
    let app: AppUsageData
    let maxDuration: TimeInterval

    var proportion: Double {
        guard maxDuration > 0 else { return 0 }
        return min(app.duration / maxDuration, 1.0)
    }
    
    var fallbackIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(iconColor(for: app.name))
                .frame(width: 40, height: 40)
            Text(String(app.name.prefix(1)).uppercased())
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // app icon
            appIconView
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(app.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Spacer()
                    Text(app.formattedDuration)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(
                            red: 237/255, green: 184/255, blue: 42/255
                        ))
                }

                // progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(
                                red: 42/255, green: 42/255, blue: 72/255
                            ))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(
                                red: 237/255, green: 184/255, blue: 42/255
                            ))
                            .frame(
                                width: geo.size.width * proportion,
                                height: 4
                            )
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
    
    
    @ViewBuilder
    var appIconView: some View {
        if let token = app.token {
            Label(token)
                .labelStyle(.iconOnly)
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            fallbackIcon
        }
    }
    

    func iconColor(for name: String) -> Color {
        let colors: [Color] = [
            Color(red: 88/255, green: 86/255, blue: 214/255),
            Color(red: 52/255, green: 199/255, blue: 89/255),
            Color(red: 255/255, green: 59/255, blue: 48/255),
            Color(red: 0/255, green: 122/255, blue: 255/255),
            Color(red: 255/255, green: 149/255, blue: 0/255),
            Color(red: 175/255, green: 82/255, blue: 222/255),
            Color(red: 90/255, green: 200/255, blue: 250/255),
        ]
        let index = abs(name.hashValue) % colors.count
        return colors[index]
    }
}
