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
    
    // Register DeviceActivityReport platform view
    let reportFactory = DeviceActivityReportViewFactory(messenger: controller.binaryMessenger)
    controller.registrar(forPlugin: "DeviceActivityReportView")?.register(reportFactory, withId: "DeviceActivityReportView")

    channel.setMethodCallHandler { call, result in
      Task { @MainActor in
        switch call.method {
        case "ios_requestAuthorization":
          FocusLogger.d("🔵 [FLUTTER→IOS] ios_requestAuthorization: START")
          do { 
            try await FocusBridge.shared.requestAuthorization()
            FocusLogger.d("🔵 [FLUTTER→IOS] ios_requestAuthorization: ✅ SUCCESS - returning true")
            result(true) 
          }
          catch { 
            FocusLogger.e("🔵 [FLUTTER→IOS] ios_requestAuthorization: ❌ ERROR - \(error.localizedDescription)")
            result(FlutterError(code: "auth_failed", message: error.localizedDescription, details: nil)) 
          }

        case "ios_getAuthorizationStatus":
          FocusLogger.d("🔵 [FLUTTER→IOS] ios_getAuthorizationStatus: START")
          let status = await AuthorizationCenter.shared.authorizationStatus
          let ok = (status == .approved)
          let statusString = status == .notDetermined ? "notDetermined" : (status == .denied ? "denied" : (status == .approved ? "approved" : "unknown"))
          FocusLogger.d("🔵 [FLUTTER→IOS] ios_getAuthorizationStatus: status=\(statusString), returning=\(ok)")
          result(ok)

        case "ios_presentPicker":
          FocusLogger.d("🔵 [FLUTTER→IOS] ios_presentPicker: START")
          FocusBridge.shared.presentPicker()
          FocusLogger.d("🔵 [FLUTTER→IOS] ios_presentPicker: ✅ DONE - returning nil")
          result(nil)

        case "ios_startMonitoring":
          FocusLogger.d("🔵 [FLUTTER→IOS] ios_startMonitoring: START")
          do { 
            try FocusBridge.shared.startHourlyMonitoring()
            FocusLogger.d("🔵 [FLUTTER→IOS] ios_startMonitoring: ✅ SUCCESS - returning true")
            result(true) 
          }
          catch { 
            FocusLogger.e("🔵 [FLUTTER→IOS] ios_startMonitoring: ❌ ERROR - \(error.localizedDescription)")
            result(FlutterError(code: "monitor_failed", message: error.localizedDescription, details: nil)) 
          }

        case "ios_getSnapshot":
          FocusLogger.d("🔵 [FLUTTER→IOS] ios_getSnapshot: START")
          let snapshot = FocusBridge.shared.getLastSnapshot()
          FocusLogger.d("🔵 [FLUTTER→IOS] ios_getSnapshot: ✅ DONE - returning snapshot")
          result(snapshot)

        case "ios_getLogs":
          FocusLogger.d("🔵 [FLUTTER→IOS] ios_getLogs: START")
          let ud = UserDefaults(suiteName: FocusShared.appGroupId) ?? UserDefaults.standard
          let logs = ud.stringArray(forKey: FocusShared.logsKey) ?? []
          FocusLogger.d("🔵 [FLUTTER→IOS] ios_getLogs: ✅ DONE - returning \(logs.count) log entries")
          result(logs)

        case "ios_clearLogs":
          FocusLogger.d("🔵 [FLUTTER→IOS] ios_clearLogs: START")
          let ud = UserDefaults(suiteName: FocusShared.appGroupId) ?? UserDefaults.standard
          ud.removeObject(forKey: FocusShared.logsKey)
          FocusLogger.d("🔵 [FLUTTER→IOS] ios_clearLogs: ✅ DONE")
          result(true)

        default: 
          FocusLogger.d("🔵 [FLUTTER→IOS] ❌ unknown method: \(call.method)")
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
