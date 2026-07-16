import UIKit
import SwiftUI

@available(iOS 16.0, *)
class ScreenTimeReportPlatformView: NSObject, FlutterPlatformView {
    private let hostingController: UIHostingController<ScreenTimeReportView>

    init(frame: CGRect, viewId: Int64, args: Any?) {
        var targetDate = Date() // default to today

        if let argsDict = args as? [String: Any],
           let dateString = argsDict["date"] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = TimeZone.current
            if let parsed = formatter.date(from: dateString) {
                targetDate = parsed
            }
        }

        let reportView = ScreenTimeReportView(id: UUID(), targetDate: targetDate)
        hostingController = UIHostingController(rootView: reportView)
        hostingController.view.frame = frame
        hostingController.view.backgroundColor = .clear
        hostingController.view.insetsLayoutMarginsFromSafeArea = false
        if #available(iOS 16.4, *) {
            hostingController.safeAreaRegions = SafeAreaRegions()
        }
        super.init()
    }

    func view() -> UIView {
        return hostingController.view
    }
}

@available(iOS 16.0, *)
class ScreenTimeReportPlatformViewFactory: NSObject, FlutterPlatformViewFactory {
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return ScreenTimeReportPlatformView(frame: frame, viewId: viewId, args: args)
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}
