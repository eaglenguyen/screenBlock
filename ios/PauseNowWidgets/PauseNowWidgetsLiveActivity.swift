import ActivityKit
import WidgetKit
import SwiftUI

func formatSeconds(_ seconds: Int) -> String {
    let m = seconds / 60
    let s = seconds % 60
    return String(format: "%02d:%02d", m, s)
}

struct PauseNowLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PauseNowActivityAttributes.self) { context in
            // ── Lock Screen / banner UI ──
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    HStack(spacing: 5) {
                        if context.state.isPaused {
                            Image(systemName: "pause.fill")
                                .font(.system(size: 11, weight: .bold))
                        }
                        Text(context.state.isPaused ? "PAUSING" : "BLOCKING")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(context.state.isPaused ? Color.orange : Color(red: 237/255, green: 184/255, blue: 42/255))
                    .clipShape(Capsule())

                    Spacer()

                    if #available(iOS 17.0, *) {
                        Button(intent: context.state.isPaused ? ResumeTimerIntent() : PauseTimerIntent()) {
                            Image(systemName: context.state.isPaused ? "play.fill" : "pause.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                if context.state.isPaused {
                    Text(formatSeconds(context.state.pausedRemainingSeconds))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                } else {
                    Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .activityBackgroundTint(Color(red: 14/255, green: 14/255, blue: 30/255))
            .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 5) {
                        if context.state.isPaused {
                            Image(systemName: "pause.fill")
                                .font(.system(size: 10, weight: .bold))
                        }
                        Text(context.state.isPaused ? "PAUSING" : "BLOCKING")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(context.state.isPaused ? Color.orange : Color(red: 237/255, green: 184/255, blue: 42/255))
                    .clipShape(Capsule())
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isPaused {
                        Text(formatSeconds(context.state.pausedRemainingSeconds))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(Color.orange)
                            .monospacedDigit()
                    } else {
                        Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 237/255, green: 184/255, blue: 42/255))
                            .monospacedDigit()
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if #available(iOS 17.0, *) {
                        Button(intent: context.state.isPaused ? ResumeTimerIntent() : PauseTimerIntent()) {
                            HStack {
                                Image(systemName: context.state.isPaused ? "play.fill" : "pause.fill")
                                Text(context.state.isPaused ? "Resume" : "Pause")
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(context.state.isPaused ? Color.orange : Color(red: 237/255, green: 184/255, blue: 42/255))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            } compactLeading: {
                if context.state.isPaused {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.orange)
                        .clipShape(Capsule())
                } else {
                    Text("BLOCKING")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color(red: 237/255, green: 184/255, blue: 42/255))
                        .clipShape(Capsule())
                }
            } compactTrailing: {
                if context.state.isPaused {
                    Text(formatSeconds(context.state.pausedRemainingSeconds))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color.orange)
                        .monospacedDigit()
                        .frame(maxWidth: 50)
                } else {
                    Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 237/255, green: 184/255, blue: 42/255))
                        .monospacedDigit()
                        .frame(maxWidth: 50)
                }
            } minimal: {
                Circle()
                    .fill(context.state.isPaused ? Color.orange : Color(red: 237/255, green: 184/255, blue: 42/255))
                    .frame(width: 12, height: 12)
            }
            .widgetURL(URL(string: "pausenow://open"))
            .keylineTint(context.state.isPaused ? Color.orange : Color(red: 237/255, green: 184/255, blue: 42/255))
        }
    }
}
