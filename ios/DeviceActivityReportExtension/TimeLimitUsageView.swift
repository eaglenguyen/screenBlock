import SwiftUI
import DeviceActivity
import FamilyControls

@available(iOS 16.0, *)
struct TimeLimitUsageView: View {
    let configuration: ActivityConfiguration

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .onAppear {
                writeUsageByConfig()
            }
    }

    private func writeUsageByConfig() {
        let defaults = UserDefaults(suiteName: "group.com.eagle.pausenow")
        let configIds = defaults?.stringArray(forKey: "timeLimitConfigIds") ?? []

        var debugLines: [String] = []
        debugLines.append("configIds=\(configIds), appUsagesCount=\(configuration.appUsages.count)")

        for id in configIds {
            guard let data = defaults?.data(forKey: "timeLimitApps_\(id)"),
                  let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
            else {
                debugLines.append("config \(id): no valid selection data")
                continue
            }
            let tokens = selection.applicationTokens
            let matchedSeconds = configuration.appUsages
                .filter { usage in
                    guard let token = usage.token else { return false }
                    return tokens.contains(token)
                }
                .reduce(0.0) { $0 + $1.duration }
            debugLines.append("config \(id): tokens=\(tokens.count), matchedSeconds=\(matchedSeconds)")
            defaults?.set(Int(matchedSeconds / 60), forKey: "timeLimitUsed_\(id)")
        }

        defaults?.set(debugLines.joined(separator: " | "), forKey: "timeLimitDebugLog") // 👈 new
        defaults?.set(Date().timeIntervalSince1970, forKey: "timeLimitDebugLogTime") // 👈 new — so you know it's fresh
        defaults?.synchronize()
    }
}
