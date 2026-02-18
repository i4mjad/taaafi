import 'package:flutter/services.dart';

/// Haptic feedback service
/// Sprint 4 - Feature 4.2: Mobile UX Improvements
class HapticService {
  /// Light impact for subtle interactions (selection, tap)
  static Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium impact for standard interactions (button press)
  static Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy impact for important actions (delete, confirm)
  static Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }

  /// Selection feedback for swipe/scroll interactions
  static Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }

  /// Vibrate for errors or warnings
  static Future<void> vibrate() async {
    await HapticFeedback.vibrate();
  }
}

