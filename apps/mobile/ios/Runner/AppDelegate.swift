import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Register Fort method channel (com.taaafi.fort)
    if let controller = window?.rootViewController as? FlutterViewController {
      let fortChannel = FortMethodChannel()
      fortChannel.register(with: controller.binaryMessenger)

      // Register DeviceActivityReport platform view so Flutter can embed it
      if #available(iOS 16.0, *) {
        let registrar = self.registrar(forPlugin: "FortUsageReportView")!
        registrar.register(
          FortUsageReportViewFactory(),
          withId: "com.taaafi.fort/usageReportView"
        )
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    // Removes notifications from Notification Center
    UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    UIApplication.shared.applicationIconBadgeNumber = 0 // Resets the badge count
  }
}
