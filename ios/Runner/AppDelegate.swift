import UIKit
import Flutter

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
          do { try await FocusBridge.shared.requestAuthorization(); result(true) }
          catch { result(FlutterError(code: "auth_failed", message: error.localizedDescription, details: nil)) }

        case "ios_presentPicker":
          FocusBridge.shared.presentPicker(); result(nil)

        case "ios_startMonitoring":
          do { try FocusBridge.shared.startHourlyMonitoring(); result(true) }
          catch { result(FlutterError(code: "monitor_failed", message: error.localizedDescription, details: nil)) }

        case "ios_getSnapshot":
          result(FocusBridge.shared.getLastSnapshot())

        default: result(FlutterMethodNotImplemented)
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
  }

  
}
