import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ValidationInfoModalNotifier extends StateNotifier<bool> {
  ValidationInfoModalNotifier() : super(false) {
    _loadPreference();
  }

  static const String _key = "validation_info_modal_seen";

  /// Load the preference from SharedPreferences
  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_key) ?? false; // Default to false (not seen)
    } catch (e) {
      // If there's an error, default to false
      state = false;
    }
  }

  /// Mark that the user has seen the validation info modal
  Future<void> markAsSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
      state = true;
    } catch (e) {
      // If there's an error saving, still update the state
      state = true;
    }
  }

  /// Reset the preference (for testing purposes)
  Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, false);
      state = false;
    } catch (e) {
      state = false;
    }
  }
}

final validationInfoModalProvider =
    StateNotifierProvider<ValidationInfoModalNotifier, bool>((ref) {
  return ValidationInfoModalNotifier();
});
