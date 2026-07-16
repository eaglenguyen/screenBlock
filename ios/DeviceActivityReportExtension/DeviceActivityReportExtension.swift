import DeviceActivity
import ExtensionKit
import SwiftUI

@main
struct TotalActivityReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        TotalActivityReport { configuration in
            TotalActivityView(configuration: configuration)
        }
        CompactActivityReport { configuration in // 👈 new — add alongside the existing one
            CompactActivityDisplay(configuration: configuration)
        }
    }
}
