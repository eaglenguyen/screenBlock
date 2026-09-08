import Foundation
import Flutter
import UIKit
import SwiftUI

@available(iOS 16.0, *)
class TimeLimitTriggerPlatformView: NSObject, FlutterPlatformView {
    private let hostingController: UIHostingController<TimeLimitTriggerView>

    init(frame: CGRect, viewId: Int64, args: Any?) {
        let view = TimeLimitTriggerView()
        hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = frame
        hostingController.view.backgroundColor = .clear
        super.init()
    }

    func view() -> UIView {
        return hostingController.view
    }
}

@available(iOS 16.0, *)
class TimeLimitTriggerPlatformViewFactory: NSObject, FlutterPlatformViewFactory {
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return TimeLimitTriggerPlatformView(frame: frame, viewId: viewId, args: args)
    }
}
