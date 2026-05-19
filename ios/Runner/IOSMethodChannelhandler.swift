//
//  IOSMethodChannelhandler.swift
//  Runner
//
//  Created by Egor on 5/18/26.
//
import UIKit
import FamilyControls

@available(iOS 16.0, *)
class IOSMethodChannelHandler {
    
    private let service = IOSBlockingService.shared
    
    
    func register(with controller: FlutterViewController) {
        let channel = FlutterMethodChannel(
            name: "com.eagle.screenblock/ios_blocking",
            binaryMessenger: controller.binaryMessenger
        )
        channel.setMethodCallHandler(handle)
    }
    
    private func handle(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        Task {
            await handleAsync(call, result: result)
        }
    }
    
    private func handleAsync(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) async {
        switch call.method {
            
        case "requestAuthorization":
            let granted = await service.requestAuthorization()
            result(granted)
            
        case "isAuthorized":
            result(service.isAuthorized())
            
        case "startBlocking":
            guard let args = call.arguments as? [String: Any],
                  let packageNames = args["packageNames"] as? [String],
                  let blockingMode = args["blockingMode"] as? String,
                  let limitMinutes = args["limitMinutes"] as? Int
            else {
                result(FlutterError(
                    code: "INVALID_ARGS",
                    message: "Missing arguments",
                    details: nil
                ))
                return
            }
            service.startBlocking(
                packageNames: packageNames,
                blockingMode: blockingMode,
                limitMinutes: limitMinutes
            )
            result(nil)
            
        case "stopBlocking":
            service.stopBlocking()
            result(nil)
            
        case "showAppPicker":
            await showAppPicker(result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - App Picker
    @MainActor
    private func showAppPicker(
        result: @escaping FlutterResult
    ) async {
        // FamilyActivityPicker must be shown as a SwiftUI view
        // We present it modally over the Flutter view
        guard let windowScene = UIApplication.shared
            .connectedScenes
            .first as? UIWindowScene,
              let rootVC = windowScene.windows.first?
            .rootViewController
        else {
            result(FlutterError(
                code: "NO_VIEW",
                message: "Could not find root view controller",
                details: nil
            ))
            return
        }
        
        let picker = FamilyActivityPickerViewController(
            service: IOSBlockingService.shared,
            onDismiss: { result(nil) }
        )
        rootVC.present(picker, animated: true)
    }
}
