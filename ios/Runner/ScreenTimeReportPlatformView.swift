//
//  ScreenTimeReportPlatformView.swift
//  Runner
//
//  Created by Egor on 7/11/26.
//

import Foundation
import Flutter
import UIKit
import SwiftUI

@available(iOS 16.0, *)
class ScreenTimeReportPlatformView: NSObject, FlutterPlatformView {
    private let hostingController: UIHostingController<ScreenTimeReportView>

    init(frame: CGRect, viewId: Int64, args: Any?) {
        let reportView = ScreenTimeReportView(id: UUID())
        hostingController = UIHostingController(rootView: reportView)
        hostingController.view.frame = frame
        hostingController.view.backgroundColor = .clear
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
}
