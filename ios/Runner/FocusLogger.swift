//
//  FocusLogger.swift
//  Runner
//
//  Focus debugging utility with os.Logger support
//

import Foundation
import os

enum FocusLogger {
    static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.taaafi.app", category: "Focus")
    
    @inlinable static func d(_ msg: String) {
        #if DEBUG || LOG_FOCUS
        logger.debug("\(msg, privacy: .public)")
        #endif
        FocusShared.appendLog("D [Runner] \(msg)")
    }
    
    @inlinable static func e(_ msg: String) {
        #if DEBUG || LOG_FOCUS
        logger.error("\(msg, privacy: .public)")
        #endif
        FocusShared.appendLog("E [Runner] \(msg)")
    }
    
    @inlinable static func d(_ msg: String, _ data: Any) {
        #if DEBUG || LOG_FOCUS
        let dataStr = String(describing: data)
        let truncated = dataStr.count <= 300 ? dataStr : String(dataStr.prefix(300)) + "…"
        logger.debug("\(msg, privacy: .public) — \(truncated, privacy: .public)")
        #else
        let dataStr = String(describing: data)
        let truncated = dataStr.count <= 300 ? dataStr : String(dataStr.prefix(300)) + "…"
        #endif
        FocusShared.appendLog("D [Runner] \(msg) — \(truncated)")
    }
}
