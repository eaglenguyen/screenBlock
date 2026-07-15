//
//  WeeklyDataTriggerPlatformView.swift
//  Runner
//
//  Created by Egor on 7/15/26.
//

import Foundation
import Flutter
import UIKit
import SwiftUI

@available(iOS 16.0, *)
class WeeklyDataTriggerPlatformView: NSObject, FlutterPlatformView {
    private let hostingController: UIHostingController<WeeklyDataTriggerView>

    init(frame: CGRect, viewId: Int64, args: Any?) {
        let view = WeeklyDataTriggerView()
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
class WeeklyDataTriggerPlatformViewFactory: NSObject, FlutterPlatformViewFactory {
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return WeeklyDataTriggerPlatformView(frame: frame, viewId: viewId, args: args)
    }
}
