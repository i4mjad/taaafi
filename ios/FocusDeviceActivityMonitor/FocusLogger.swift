import Foundation
import os

enum FocusLogger {
  static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.taaafi.app", category: "Focus")
  
  @inlinable static func d(_ msg: String) {
    #if DEBUG
    logger.debug("\(msg, privacy: .public)")
    #endif
    FocusShared.appendLog("D [Extension] \(msg)")
  }
  
  @inlinable static func e(_ msg: String) {
    #if DEBUG
    logger.error("\(msg, privacy: .public)")
    #endif
    FocusShared.appendLog("E [Extension] \(msg)")
  }
  
  @inlinable static func d(_ msg: String, _ data: Any) {
    #if DEBUG
    let dataStr = String(describing: data)
    let truncated = dataStr.count <= 300 ? dataStr : String(dataStr.prefix(300)) + "…"
    logger.debug("\(msg, privacy: .public) — \(truncated, privacy: .public)")
    #endif
  }
}

// MARK: - Shared helpers

extension FocusShared {
  /// Append a log line into the shared App Group log buffer (capped to 200 lines)
  static func appendLog(_ line: String) {
    let ud = UserDefaults(suiteName: appGroupId) ?? UserDefaults.standard
    var logs = ud.stringArray(forKey: logsKey) ?? []
    logs.append(line)
    if logs.count > 200 {
      logs.removeFirst(logs.count - 200)
    }
    ud.set(logs, forKey: logsKey)
  }
}

