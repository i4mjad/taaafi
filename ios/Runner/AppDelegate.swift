import UIKit
import Flutter
import FamilyControls
import DeviceActivity

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "analytics.usage", binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler { call, result in
      Task { @MainActor in
        switch call.method {
        case "ios_requestAuthorization":
          FocusLogger.d("ios_requestAuthorization:start")
          do { 
            try await FocusBridge.shared.requestAuthorization()
            FocusLogger.d("ios_requestAuthorization:done true")
            result(true) 
          }
          catch { 
            FocusLogger.e("ios_requestAuthorization:error \(error)")
            result(FlutterError(code: "auth_failed", message: error.localizedDescription, details: nil)) 
          }

        case "ios_getAuthorizationStatus":
          FocusLogger.d("ios_getAuthorizationStatus:start")
          let status = await AuthorizationCenter.shared.authorizationStatus
          let ok = (status == .approved)
          FocusLogger.d("ios_getAuthorizationStatus:done \(ok)")
          result(ok)

        case "ios_presentPicker":
          FocusLogger.d("ios_presentPicker:start")
          FocusBridge.shared.presentPicker()
          FocusLogger.d("ios_presentPicker:done")
          result(nil)

        case "ios_startMonitoring":
          FocusLogger.d("ios_startMonitoring:start")
          do { 
            try FocusBridge.shared.startHourlyMonitoring()
            FocusLogger.d("ios_startMonitoring:done true")
            result(true) 
          }
          catch { 
            FocusLogger.e("ios_startMonitoring:error \(error)")
            result(FlutterError(code: "monitor_failed", message: error.localizedDescription, details: nil)) 
          }

        case "ios_getSnapshot":
          FocusLogger.d("ios_getSnapshot:start")
          let snapshot = FocusBridge.shared.getLastSnapshot()
          FocusLogger.d("ios_getSnapshot:done", snapshot)
          result(snapshot)

        case "ios_getLogs":
          FocusLogger.d("ios_getLogs:start")
          let ud = UserDefaults(suiteName: FocusShared.appGroupId) ?? UserDefaults.standard
          let logs = ud.stringArray(forKey: FocusShared.logsKey) ?? []
          FocusLogger.d("ios_getLogs:done count=\(logs.count)")
          result(logs)

        case "ios_clearLogs":
          FocusLogger.d("ios_clearLogs:start")
          let ud = UserDefaults(suiteName: FocusShared.appGroupId) ?? UserDefaults.standard
          ud.removeObject(forKey: FocusShared.logsKey)
          FocusLogger.d("ios_clearLogs:done")
          result(true)

        default: 
          FocusLogger.d("unknown method: \(call.method)")
          result(FlutterMethodNotImplemented)
        }
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    // Removes notifications from Notification Center
    UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    UIApplication.shared.applicationIconBadgeNumber = 0 // Resets the badge count
    // Ensure monitoring is running each time app becomes active
    Task { @MainActor in
      do { try FocusBridge.shared.startHourlyMonitoring() } catch { /* ignore */ }
    }
  }

  
}
