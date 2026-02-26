import Foundation
import FirebaseCrashlytics

/// Wraps Firebase Crashlytics for structured error logging
/// Ported from: apps/mobile/lib/core/monitoring/error_logger.dart
@Observable
@MainActor
final class ErrorLogger {

    func logException(_ error: Error, context: [String: String]? = nil, message: String? = nil) {
        let crashlytics = Crashlytics.crashlytics()

        if let context {
            for (key, value) in context {
                crashlytics.setCustomValue(value, forKey: key)
            }
        }

        if let message {
            crashlytics.setCustomValue(message, forKey: "message")
        }

        crashlytics.record(error: error, userInfo: context)

        print("[Exception] \(message ?? error.localizedDescription)")
    }

    func logInfo(_ message: String, context: [String: String]? = nil) {
        let crashlytics = Crashlytics.crashlytics()

        if let context {
            crashlytics.log("INFO: \(message) - \(context)")
        } else {
            crashlytics.log("INFO: \(message)")
        }

        print("[Info] \(message)")
    }

    func logWarning(_ message: String, context: [String: String]? = nil) {
        let crashlytics = Crashlytics.crashlytics()

        if let context {
            crashlytics.log("WARNING: \(message) - \(context)")
        } else {
            crashlytics.log("WARNING: \(message)")
        }

        print("[Warning] \(message)")
    }
}
