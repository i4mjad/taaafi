import UIKit

/// Static haptic feedback utility
/// Ported from: apps/mobile/lib/core/services/haptic_service.dart
enum HapticService {

    static func lightImpact() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func mediumImpact() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func heavyImpact() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    static func selectionClick() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func vibrate() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
