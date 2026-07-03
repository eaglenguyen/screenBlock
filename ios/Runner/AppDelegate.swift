import UIKit
import FamilyControls
import Flutter
import SwiftUI
import UserNotifications
import os
import AudioToolbox


@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    private var flutterEngine: FlutterEngine?
    var flutterChannel: FlutterMethodChannel? // 👈 add this

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
            [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // setup notification delegate
        UNUserNotificationCenter.current().delegate = self

        let engine = FlutterEngine(name: "main engine")
        engine.run()
        GeneratedPluginRegistrant.register(with: engine)
        flutterEngine = engine

        if #available(iOS 16.0, *) {
            setupChannel(engine: engine)
        }

        let flutterVC = FlutterViewController(
            engine: engine,
            nibName: nil,
            bundle: nil
        )

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = flutterVC
        window?.makeKeyAndVisible()
        
        // add in didFinishLaunchingWithOptions before return true
        func registerNotificationCategories() {
            // Pomodoro work ended actions
            let startBreakAction = UNNotificationAction(
                identifier: "START_BREAK",
                title: "Start Break 🍅",
                options: []
            )
            let keepWorkingAction = UNNotificationAction(
                identifier: "KEEP_WORKING",
                title: "Keep Working 💪",
                options: []
            )
            let workEndedCategory = UNNotificationCategory(
                identifier: "POMODORO_WORK_ENDED",
                actions: [startBreakAction, keepWorkingAction],
                intentIdentifiers: [],
                options: []
            )

            // Pomodoro break ended actions
            let startWorkAction = UNNotificationAction(
                identifier: "START_WORK",
                title: "Start Working 🔒",
                options: []
            )
            let extendBreakAction = UNNotificationAction(
                identifier: "EXTEND_BREAK",
                title: "5 More Minutes ⏳",
                options: []
            )
            let breakEndedCategory = UNNotificationCategory(
                identifier: "POMODORO_BREAK_ENDED",
                actions: [startWorkAction, extendBreakAction],
                intentIdentifiers: [],
                options: []
            )

            UNUserNotificationCenter.current().setNotificationCategories([
                workEndedCategory,
                breakEndedCategory
            ])
        }
        
        registerNotificationCategories()
        UNUserNotificationCenter.current().delegate = self

        return true
    }
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // opened from shield action — app is now in foreground
        // Flutter's onAppResumed will handle state sync
        return true
    }

    // ── Notification delegate ─────────────────────────
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let action = response.actionIdentifier
        let defaults = UserDefaults(suiteName: "group.com.eagle.pausenow")
        NSLog("🔔 notification action: \(action)")

        if response.notification.request.identifier == "scheduleResume" {
            handleScheduleResume()
        }
        if #available(iOS 16.0, *) {
            switch action {
            case "START_BREAK":
                // 👇 unblock apps immediately for break
                IOSBlockingService.shared.store.clearAllSettings()
                defaults?.set("break", forKey: "pomodoroPhase")
                defaults?.set(Date().timeIntervalSince1970, forKey: "pomodoroBreakStartTime")
                defaults?.synchronize()

            case "KEEP_WORKING":
                // do nothing — apps stay blocked
                NSLog("Nothing happens")

            case "START_WORK":
                // 👇 reblock apps immediately for work
                let blockingMode = defaults?.string(forKey: "blockingMode") ?? "specific_apps"
                IOSBlockingService.shared.applyShield(mode: blockingMode)
                defaults?.set("work", forKey: "pomodoroPhase")
                defaults?.set(Date().timeIntervalSince1970, forKey: "pomodoroWorkStartTime")
                defaults?.synchronize()

            case "EXTEND_BREAK":
                // 👇 keep apps unblocked, update break end time
                IOSBlockingService.shared.store.clearAllSettings()
                let newBreakEnd = Date().addingTimeInterval(5 * 60)
                defaults?.set(newBreakEnd.timeIntervalSince1970, forKey: "pomodoroBreakEndsAt")
                defaults?.synchronize()
                NSLog("⏳ EXTEND_BREAK — 5 more minutes")

            default:
                break
            }
        }
        completionHandler()
    }
    

    // called when notification received while app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if notification.request.identifier == "scheduleResume" {
            handleScheduleResume()
        }
        completionHandler([])
    }



    private func handleScheduleResume() {
        NSLog("⏰ scheduleResume notification received — resuming blocking")
        if #available(iOS 16.0, *) {
            IOSBlockingService.shared.resumeBlocking()
        }
    }

    @available(iOS 16.0, *)
    private func setupChannel(engine: FlutterEngine) {
        IOSBlockingService.shared.checkAuthorizationStatus()
        let channel = FlutterMethodChannel(
            name: "com.eagle.pausenow/ios_blocking",
            binaryMessenger: engine.binaryMessenger
        )
        flutterChannel = channel // 👈 add this line

        
        // 👇 notify Flutter when native pause timer fires
         IOSBlockingService.shared.onPauseEnded = {
             DispatchQueue.main.async {
                 channel.invokeMethod("onPauseEnded", arguments: nil)
             }
         }
        

        channel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { return }
            Task { await self.handleMethodCall(call, result: result) }
        }
    }

    // ── Sheet dismiss delegate ────────────────────────
    class SheetDismissDelegate: NSObject, UIAdaptivePresentationControllerDelegate {
        let onDismiss: () -> Void

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        func presentationControllerDidDismiss(
            _ presentationController: UIPresentationController
        ) {
            onDismiss()
        }
    }

    // ── Updated showScreenTimeReport ──────────────────
    @available(iOS 16.0, *)
    @MainActor
    private func showScreenTimeReport(result: @escaping FlutterResult) async {
        guard let windowScene = UIApplication.shared
            .connectedScenes
            .first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController
        else {
            result(FlutterError(
                code: "NO_VIEW",
                message: "No view controller",
                details: nil
            ))
            return
        }

        // 👇 if a sheet is already presented, dismiss it first
        if let presented = rootVC.presentedViewController {
            presented.dismiss(animated: false)
            // wait for dismiss to complete
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
        }

        let reportView = ScreenTimeReportView(id: UUID())
        let reportVC = UIHostingController(rootView: reportView)
        reportVC.modalPresentationStyle = .pageSheet

        if let sheet = reportVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }

        let delegate = SheetDismissDelegate {
            result(nil)
        }
        reportVC.presentationController?.delegate = delegate
        objc_setAssociatedObject(
            reportVC,
            "dismissDelegate",
            delegate,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )

        rootVC.present(reportVC, animated: true)
    }


    @available(iOS 16.0, *)
    private func handleMethodCall(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) async {
        let service = IOSBlockingService.shared

        switch call.method {
        case "savePomodoroBreakState":
            if let args = call.arguments as? [String: Any] {
                let defaults = UserDefaults(suiteName: "group.com.eagle.pausenow")
                defaults?.set(args["roundCount"], forKey: "pomodoroRoundCount")
                defaults?.set(args["breakMinutes"], forKey: "pomodoroBreakMinutes")
                defaults?.set(args["breakStartTime"], forKey: "pomodoroBreakStartTime")
                defaults?.set(args["isLongBreak"], forKey: "pomodoroIsLongBreak")
                defaults?.set("break", forKey: "pomodoroPhase")
                defaults?.synchronize()
            }
            result(nil)
        case "getPomodoroBreakState":
            let defaults = UserDefaults(suiteName: "group.com.eagle.pausenow")
            result([
                "pomodoroPhase": defaults?.string(forKey: "pomodoroPhase") ?? "work",
                "pomodoroBreakMinutes": defaults?.integer(forKey: "pomodoroBreakMinutes") ?? 5,
                "pomodoroBreakStartTime": defaults?.integer(forKey: "pomodoroBreakStartTime") ?? 0,
                "pomodoroRoundCount": defaults?.integer(forKey: "pomodoroRoundCount") ?? 0,
                "pomodoroIsLongBreak": defaults?.bool(forKey: "pomodoroIsLongBreak") ?? false,
            ])
        case "clearPomodoroBreakState":
            let defaults = UserDefaults(suiteName: "group.com.eagle.pausenow")
            defaults?.removeObject(forKey: "pomodoroBreakMinutes")
            defaults?.removeObject(forKey: "pomodoroBreakStartTime")
            defaults?.removeObject(forKey: "pomodoroIsLongBreak")
            defaults?.set("work", forKey: "pomodoroPhase")
            defaults?.synchronize()
            result(nil)
        case "checkAndClearPendingClaim":
            let defaults = UserDefaults(suiteName: "group.com.eagle.pausenow")
            let pending = defaults?.bool(forKey: "pendingXpClaim") ?? false
            if pending {
                defaults?.set(false, forKey: "pendingXpClaim")
                defaults?.synchronize()
            }
            result(pending)
        case "getScreenTimeTotal":
            let sharedDefaults = UserDefaults(suiteName: "group.com.eagle.pausenow")
            let total = sharedDefaults?.double(forKey: "totalScreenTimeToday") ?? 0
            NSLog("📊 getScreenTimeTotal called — value: \(total)")
            let date = sharedDefaults?.string(forKey: "screenTimeTotalDate") ?? ""
            result(["total": total, "date": date])
        case "playSystemSound":
            if let args = call.arguments as? [String: Any],
               let soundId = args["soundId"] as? UInt32 {
                AudioServicesPlaySystemSound(soundId)
            }
            result(nil)
        case "stopSessionMonitoring":
            service.stopSessionMonitoring()
            result(nil)
        case "showScreenTimeReport":
            await showScreenTimeReport(result: result)
        case "checkNotificationPermission":
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    DispatchQueue.main.async {
                        result(settings.authorizationStatus == .authorized)
                    }
                }

            case "requestNotificationPermission":
                UNUserNotificationCenter.current().requestAuthorization(
                    options: [.alert, .sound, .badge]
                ) { granted, error in
                    DispatchQueue.main.async {
                        result(granted)
                    }
                }

        case "checkMonitoringStatus":
            let defaults = UserDefaults(suiteName: "group.com.eagle.pausenow")
            let status = defaults?.string(forKey: "monitoringStatus") ?? "never called"
            let activities = defaults?.array(forKey: "monitoringActivities") as? [String] ?? []
            result([
                "status": status,
                "activities": activities,
            ])

        case "checkExtensionRan":
            let defaults = UserDefaults(suiteName: "group.com.eagle.pausenow")
            let lastRan = defaults?.double(forKey: "extensionLastRan") ?? 0
            let lastActivity = defaults?.string(forKey: "extensionLastActivity") ?? "none"
            let lastEvent = defaults?.string(forKey: "extensionLastEvent") ?? "none"
            NSLog("🔍 Extension last ran: \(lastRan), activity: \(lastActivity), event: \(lastEvent)")
            result([
                "lastRan": lastRan,
                "lastActivity": lastActivity,
                "lastEvent": lastEvent,
            ])

        case "requestAuthorization":
            result(await service.requestAuthorization())

        case "isAuthorized":
            result(service.isAuthorized())

        case "saveBlockingMode":
            if let args = call.arguments as? [String: Any],
               let mode = args["mode"] as? String {
                let defaults = UserDefaults(suiteName: "group.com.eagle.pausenow")
                defaults?.set(mode, forKey: "blockingMode")
            }
            result(nil)
        case "setPremiumStatus":
            if let args = call.arguments as? [String: Any],
               let isPremium = args["isPremium"] as? Bool {
                let defaults = UserDefaults(suiteName: "group.com.eagle.pausenow")
                defaults?.set(isPremium, forKey: "isPremium")
                defaults?.synchronize()
                NSLog("💎 isPremium synced to native: \(isPremium)")
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
            // cancel any pending resume notification
            UNUserNotificationCenter.current()
                .removePendingNotificationRequests(withIdentifiers: ["scheduleResume"])
            result(nil)

        case "pauseBlocking":
            if let args = call.arguments as? [String: Any],
               let minutes = args["minutes"] as? Int {
                service.pauseBlocking(forMinutes: minutes)
            }
            result(nil)

        case "resumeBlocking":
            service.resumeBlocking()
            result(nil)

        case "stopBlockingCompletely":
            service.stopBlockingCompletely()
            result(nil)
            
        case "persistSessionType":
            if let args = call.arguments as? [String: Any],
               let type = args["type"] as? String {
                let defaults = UserDefaults(suiteName: "group.com.eagle.pausenow")
                defaults?.set(type, forKey: "sessionType")
                defaults?.synchronize()
            }
            result(nil)

        case "savePauseEndTime":
            if let args = call.arguments as? [String: Any],
               let endTimeMs = args["endTimeMs"] as? Int {
                let defaults = UserDefaults(suiteName: "group.com.eagle.pausenow")
                defaults?.set(endTimeMs, forKey: "schedulePauseEndTime")
                defaults?.synchronize()
                NSLog("⏰ savePauseEndTime: \(endTimeMs)")

                // schedule local notification for when pause expires
                let delaySeconds = Double(endTimeMs) / 1000.0 - Date().timeIntervalSince1970
                if delaySeconds > 0 {
                    scheduleResumeNotification(inSeconds: delaySeconds)
                }
            }
            result(nil)
            
        case "cancelPause":
            // cancel notification when user manually resumes
            UNUserNotificationCenter.current()
                .removePendingNotificationRequests(withIdentifiers: ["scheduleResume"])
            let defaults = UserDefaults(suiteName: "group.com.eagle.pausenow")
            defaults?.set(0, forKey: "schedulePauseEndTime")
            defaults?.synchronize()
            result(nil)

        case "getPersistedSession":
            let defaults = UserDefaults(suiteName: "group.com.eagle.pausenow")
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

    // ── Schedule resume notification ──────────────────

    private func scheduleResumeNotification(inSeconds delay: Double) {
        // request permission first
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound]
        ) { granted, _ in
            guard granted else {
                NSLog("⚠️ Notification permission denied — resume will trigger on app open")
                return
            }

            // remove any existing resume notification
            UNUserNotificationCenter.current()
                .removePendingNotificationRequests(withIdentifiers: ["scheduleResume"])

            let content = UNMutableNotificationContent()
            content.title = "Blocking Resumed"
            content.body = "Your pause is over. Apps are being blocked again."
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: delay,
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: "scheduleResume",
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    NSLog("❌ schedule notification error: \(error)")
                } else {
                    NSLog("⏰ resume notification scheduled in \(delay)s")
                }
            }
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

        let sharedDefaults = UserDefaults(suiteName: "group.com.eagle.pausenow")
        let blockingMode = sharedDefaults?.string(forKey: "blockingMode") ?? "specific_apps"
        let saveKey = blockingMode == "specific_apps" ? "blockedApps" : "allowedApps"
        let backupKey = "\(saveKey)_backup"

        // snapshot current selection before picker opens
        if let existing = sharedDefaults?.data(forKey: saveKey) {
            sharedDefaults?.set(existing, forKey: backupKey)
        } else {
            sharedDefaults?.removeObject(forKey: backupKey)
        }
        sharedDefaults?.synchronize()

        let picker = FamilyActivityPickerViewController(
            service: IOSBlockingService.shared,
            onDismiss: {
                if let data = sharedDefaults?.data(forKey: saveKey),
                   let selection = try? JSONDecoder().decode(
                       FamilyActivitySelection.self,
                       from: data
                   ) {
                    let count = selection.applicationTokens.count

                    // 👇 user intentionally cleared the list — allow it
                    if count == 0 {
                        sharedDefaults?.removeObject(forKey: saveKey)
                        sharedDefaults?.removeObject(forKey: backupKey)
                        sharedDefaults?.synchronize()
                        NSLog("✅ picker dismissed with 0 apps — list cleared")
                        result(0)
                        return
                    }

                    let isPremium = sharedDefaults?.bool(forKey: "isPremium") ?? false
                    let freeLimit = 3

                    if !isPremium && blockingMode == "specific_apps" && count > freeLimit {
                        // restore previous selection
                        if let backup = sharedDefaults?.data(forKey: backupKey) {
                            sharedDefaults?.set(backup, forKey: saveKey)
                            NSLog("🔄 restored previous selection from backup")
                        } else {
                            sharedDefaults?.removeObject(forKey: saveKey)
                            NSLog("🧹 no backup found — cleared selection")
                        }
                        sharedDefaults?.removeObject(forKey: backupKey)
                        sharedDefaults?.synchronize()
                        NSLog("🚫 free limit exceeded — count=\(count)")
                        result(freeLimit + 1)
                        return
                    }

                    // success — clear backup
                    sharedDefaults?.removeObject(forKey: backupKey)
                    sharedDefaults?.synchronize()
                    NSLog("✅ picker dismissed with \(count) apps saved")
                    result(count)

                } else {
                    // decode failed — picker dismissed without saving, restore backup
                    if let backup = sharedDefaults?.data(forKey: backupKey) {
                        sharedDefaults?.set(backup, forKey: saveKey)
                    }
                    sharedDefaults?.removeObject(forKey: backupKey)
                    sharedDefaults?.synchronize()
                    result(0)
                }
            },
            saveKey: saveKey
        )
        rootVC.present(picker, animated: true)
    }
}
