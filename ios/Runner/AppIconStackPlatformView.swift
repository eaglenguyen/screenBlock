//
//  AppIconStackPlatformView.swift
//  Runner
//
//  Created by Egor on 7/14/26.
//

import Foundation
import Flutter
import UIKit
import SwiftUI
import FamilyControls
import ManagedSettings


@available(iOS 16.0, *)
class AppIconStackPlatformView: NSObject, FlutterPlatformView {
    private let hostingController: UIHostingController<AppIconStackView>

    init(frame: CGRect, viewId: Int64, args: Any?) {
        let sharedDefaults = UserDefaults(suiteName: "group.com.eagle.pausenow")
        var tokens: Set<ApplicationToken> = []
        var size: CGFloat = 40

        if let argsDict = args as? [String: Any] {
            if let storageKey = argsDict["storageKey"] as? String,
               let data = sharedDefaults?.data(forKey: storageKey),
               let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
                tokens = selection.applicationTokens
            }
            if let sizeArg = argsDict["size"] as? Double {
                size = CGFloat(sizeArg)
            }
        }

        let view = AppIconStackView(tokens: tokens, size: size)
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
class AppIconStackPlatformViewFactory: NSObject, FlutterPlatformViewFactory {
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return AppIconStackPlatformView(frame: frame, viewId: viewId, args: args)
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}
