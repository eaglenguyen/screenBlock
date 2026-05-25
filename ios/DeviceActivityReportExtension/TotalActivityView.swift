import SwiftUI
import DeviceActivity

struct TotalActivityView: View {
    let configuration: ActivityConfiguration

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                VStack(spacing: 4) {
                    Text(configuration.formattedTotal)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    Text("Total screen time today")
                        .font(.system(size: 14))
                        .foregroundColor(Color(
                            red: 112/255,
                            green: 112/255,
                            blue: 160/255
                        ))
                }
                .padding(.top, 20)

                if configuration.appUsages.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 40))
                            .foregroundColor(Color(
                                red: 112/255,
                                green: 112/255,
                                blue: 160/255
                            ))
                        Text("No usage data yet")
                            .foregroundColor(Color(
                                red: 112/255,
                                green: 112/255,
                                blue: 160/255
                            ))
                    }
                    .padding(.top, 60)
                } else {
                    VStack(spacing: 0) {
                        ForEach(
                            Array(configuration.appUsages
                                .prefix(20)
                                .enumerated()),
                            id: \.element.id
                        ) { index, app in
                            AppUsageRow(
                                app: app,
                                maxDuration: configuration
                                    .appUsages.first?.duration ?? 1
                            )
                            if index < min(
                                configuration.appUsages.count, 20
                            ) - 1 {
                                Divider()
                                    .background(Color(
                                        red: 42/255,
                                        green: 42/255,
                                        blue: 72/255
                                    ))
                                    .padding(.leading, 60)
                            }
                        }
                    }
                    .background(Color(
                        red: 30/255,
                        green: 30/255,
                        blue: 53/255
                    ))
                    .cornerRadius(16)
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 100)
        }
        .background(Color(
            red: 22/255,
            green: 22/255,
            blue: 42/255
        ))
    }
}

struct AppUsageRow: View {
    let app: AppUsageData
    let maxDuration: TimeInterval

    var proportion: Double {
        guard maxDuration > 0 else { return 0 }
        return min(app.duration / maxDuration, 1.0)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(
                        red: 37/255,
                        green: 37/255,
                        blue: 66/255
                    ))
                    .frame(width: 36, height: 36)
                Text(String(app.name.prefix(1)))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(app.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Spacer()
                    Text(app.formattedDuration)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(
                            red: 112/255,
                            green: 112/255,
                            blue: 160/255
                        ))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(
                                red: 37/255,
                                green: 37/255,
                                blue: 66/255
                            ))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(
                                red: 237/255,
                                green: 184/255,
                                blue: 42/255
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
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}
