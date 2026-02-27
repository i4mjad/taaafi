import UIKit
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Configure Firebase here where UIApplication is fully initialized.
        // Guard against double-configuration (init() fallback may have run first).
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        return true
    }
}
