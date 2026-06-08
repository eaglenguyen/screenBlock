import UIKit
import FamilyControls
import Flutter
import os

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
            [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        os_log("🦅🦅🦅 APP LAUNCHED", log: .default, type: .fault)

        let flutterEngine = FlutterEngine(name: "main engine")
        flutterEngine.run()
        GeneratedPluginRegistrant.register(with: flutterEngine)

        if #available(iOS 16.0, *) {
            setupChannel(engine: flutterEngine)
        }

        let flutterVC = FlutterViewController(
            engine: flutterEngine,
            nibName: nil,
            bundle: nil
        )

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = flutterVC
        window?.makeKeyAndVisible()

        return true
    }

    @available(iOS 16.0, *)
    private func setupChannel(engine: FlutterEngine) {
        IOSBlockingService.shared.checkAuthorizationStatus()
        let channel = FlutterMethodChannel(
            name: "com.eagle.screenblock/ios_blocking",
            binaryMessenger: engine.binaryMessenger
        )
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { return }
            Task { await self.handleMethodCall(call, result: result) }
        }
    }

    @available(iOS 16.0, *)
    private func handleMethodCall(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) async {
        let service = IOSBlockingService.shared

        switch call.method {

        case "requestAuthorization":
            result(await service.requestAuthorization())

        case "isAuthorized":
            result(service.isAuthorized())

        case "saveBlockingMode":
            if let args = call.arguments as? [String: Any],
               let mode = args["mode"] as? String {
                let defaults = UserDefaults(suiteName: "group.com.eagle.screenblock")
                defaults?.set(mode, forKey: "blockingMode")
                print("✅ saved blockingMode: \(mode)")
            }
            result(nil)

        case "openScreenTime":
            if let url = URL(string: "App-prefs:") {
                DispatchQueue.main.async {
                    UIApplication.shared.open(url)
                }
            }
            result(nil)

        case "startBlocking":
            guard let args = call.arguments as? [String: Any],
                  let packageNames = args["packageNames"] as? [String],
                  let blockingMode = args["blockingMode"] as? String,
                  let limitMinutes = args["limitMinutes"] as? Int
            else {
                result(nil)
                break
            }
            let sessionType = args["sessionType"] as? String ?? "manual"
            service.startBlocking(
                packageNames: packageNames,
                blockingMode: blockingMode,
                limitMinutes: limitMinutes,
                sessionType: sessionType
            )
            result(nil)

        case "stopBlocking":
            service.stopBlocking()
            result(nil)

        case "persistSessionType":
            if let args = call.arguments as? [String: Any],
               let type = args["type"] as? String {
                let defaults = UserDefaults(suiteName: "group.com.eagle.screenblock")
                defaults?.set(type, forKey: "sessionType")
                defaults?.synchronize()
                NSLog("🔄 persistSessionType saved: \(type)")
            }
            result(nil)

        case "getPersistedSession":
            let defaults = UserDefaults(suiteName: "group.com.eagle.screenblock")
            let isBlocking = defaults?.bool(forKey: "isBlocking") ?? false
            let sessionType = defaults?.string(forKey: "sessionType") ?? "manual"
            let startTime = defaults?.double(forKey: "sessionStartTime") ?? 0
            let minutes = defaults?.integer(forKey: "sessionMinutes") ?? 0

            NSLog("🔄 getPersistedSession: isBlocking=\(isBlocking) sessionType=\(sessionType) minutes=\(minutes)")

            if isBlocking {
                result([
                    "isBlocking": true,
                    "startTime": startTime,
                    "minutes": minutes,
                    "sessionType": sessionType,
                ])
            } else {
                result(["isBlocking": false])
            }

        case "showAppPicker":
            await showAppPicker(result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    @available(iOS 16.0, *)
    @MainActor
    private func showAppPicker(result: @escaping FlutterResult) async {
        guard let windowScene = UIApplication.shared
            .connectedScenes
            .first as? UIWindowScene,
              let rootVC = windowScene.windows.first?
            .rootViewController
        else {
            result(FlutterError(
                code: "NO_VIEW",
                message: "No view controller",
                details: nil
            ))
            return
        }

        let sharedDefaults = UserDefaults(suiteName: "group.com.eagle.screenblock")
        let blockingMode = sharedDefaults?.string(forKey: "blockingMode") ?? "specific_apps"
        let saveKey = blockingMode == "specific_apps" ? "blockedApps" : "allowedApps"

        let picker = FamilyActivityPickerViewController(
            service: IOSBlockingService.shared,
            onDismiss: {
                if let data = sharedDefaults?.data(forKey: saveKey),
                   let selection = try? JSONDecoder().decode(
                       FamilyActivitySelection.self,
                       from: data
                   ) {
                    let count = selection.applicationTokens.count
                    print("✅ picker dismissed with \(count) apps saved")
                    result(count)
                } else {
                    print("❌ no selection saved after picker dismissed")
                    result(0)
                }
            },
            saveKey: saveKey
        )
        rootVC.present(picker, animated: true)
    }
}
