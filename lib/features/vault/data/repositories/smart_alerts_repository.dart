import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reboot_app_3/features/vault/data/models/smart_alert_settings.dart';

part 'smart_alerts_repository.g.dart';

class SmartAlertsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  SharedPreferences? _prefs;

  // Shared preferences keys
  static const String _keyPrefix = 'smart_alerts_';
  static const String _keyIsHighRiskEnabled = '${_keyPrefix}high_risk_enabled';
  static const String _keyIsVulnerabilityEnabled =
      '${_keyPrefix}vulnerability_enabled';
  static const String _keyVulnerabilityHour = '${_keyPrefix}vulnerability_hour';
  static const String _keyLastRiskHour = '${_keyPrefix}last_risk_hour';
  static const String _keyLastVulnerableWeekday =
      '${_keyPrefix}last_vulnerable_weekday';

  SmartAlertsRepository(this._firestore, this._auth);

  /// Get or initialize SharedPreferences
  Future<SharedPreferences> get _getPrefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Get current user's smart alert settings (with local cache fallback)
  Future<SmartAlertSettings?> getSmartAlertSettings() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // Try to get from Firestore first
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('smart_alerts')
          .get();

      SmartAlertSettings settings;
      if (doc.exists) {
        settings = SmartAlertSettings.fromDoc(doc);
        // Cache the Firestore settings locally
        await _cacheSettings(settings);
      } else {
        // Use cached settings or defaults
        settings = await _getCachedSettings() ?? const SmartAlertSettings();
      }

      return settings;
    } catch (e) {
      // On error, return cached settings or defaults
      return await _getCachedSettings() ?? const SmartAlertSettings();
    }
  }

  /// Cache settings to shared preferences
  Future<void> _cacheSettings(SmartAlertSettings settings) async {
    final prefs = await _getPrefs;
    await Future.wait([
      prefs.setBool(_keyIsHighRiskEnabled, settings.isHighRiskHourEnabled),
      prefs.setBool(
          _keyIsVulnerabilityEnabled, settings.isStreakVulnerabilityEnabled),
      prefs.setInt(_keyVulnerabilityHour, settings.vulnerabilityAlertHour),
      if (settings.lastCalculatedRiskHour != null)
        prefs.setInt(_keyLastRiskHour, settings.lastCalculatedRiskHour!),
      if (settings.lastCalculatedVulnerableWeekday != null)
        prefs.setInt(_keyLastVulnerableWeekday,
            settings.lastCalculatedVulnerableWeekday!),
    ]);
  }

  /// Get cached settings from shared preferences
  Future<SmartAlertSettings?> _getCachedSettings() async {
    try {
      final prefs = await _getPrefs;
      return SmartAlertSettings(
        isHighRiskHourEnabled: prefs.getBool(_keyIsHighRiskEnabled) ?? true,
        isStreakVulnerabilityEnabled:
            prefs.getBool(_keyIsVulnerabilityEnabled) ?? true,
        vulnerabilityAlertHour: prefs.getInt(_keyVulnerabilityHour) ?? 8,
        lastCalculatedRiskHour: prefs.getInt(_keyLastRiskHour),
        lastCalculatedVulnerableWeekday:
            prefs.getInt(_keyLastVulnerableWeekday),
      );
    } catch (e) {
      return null;
    }
  }

  /// Save smart alert settings (to both Firestore and cache)
  Future<void> saveSmartAlertSettings(SmartAlertSettings settings) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Cache immediately for UI responsiveness
    await _cacheSettings(settings);

    try {
      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('smart_alerts')
          .set(settings.toMap(), SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  /// Update specific setting (with immediate caching)
  Future<void> updateAlertToggle(SmartAlertType type, bool enabled) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Cache immediately
    final prefs = await _getPrefs;
    switch (type) {
      case SmartAlertType.highRiskHour:
        await prefs.setBool(_keyIsHighRiskEnabled, enabled);
        break;
      case SmartAlertType.streakVulnerability:
        await prefs.setBool(_keyIsVulnerabilityEnabled, enabled);
        break;
    }

    try {
      final updateData = <String, dynamic>{};
      switch (type) {
        case SmartAlertType.highRiskHour:
          updateData['isHighRiskHourEnabled'] = enabled;
          break;
        case SmartAlertType.streakVulnerability:
          updateData['isStreakVulnerabilityEnabled'] = enabled;
          break;
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('smart_alerts')
          .set(updateData, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  /// Update calculated risk hour (with immediate caching)
  Future<void> updateRiskHour(int riskHour) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Cache immediately
    final prefs = await _getPrefs;
    await prefs.setInt(_keyLastRiskHour, riskHour);

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('smart_alerts')
          .set({
        'lastCalculatedRiskHour': riskHour,
        'lastRiskHourCalculation': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  /// Update calculated vulnerable weekday (with immediate caching)
  Future<void> updateVulnerableWeekday(int weekday) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Cache immediately
    final prefs = await _getPrefs;
    await prefs.setInt(_keyLastVulnerableWeekday, weekday);

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('smart_alerts')
          .set({
        'lastCalculatedVulnerableWeekday': weekday,
        'lastVulnerabilityCalculation': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  /// Update vulnerability alert hour (with immediate caching)
  Future<void> updateVulnerabilityAlertHour(int hour) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Cache immediately for instant UI update
    final prefs = await _getPrefs;
    await prefs.setInt(_keyVulnerabilityHour, hour);

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('smart_alerts')
          .set({
        'vulnerabilityAlertHour': hour,
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  /// Mark alert as sent
  Future<void> markAlertSent(SmartAlertType type) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('smart_alerts')
          .set({
        'lastAlertSent': Timestamp.now(),
        'lastAlertType': type.name,
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  /// Update permission denied banner status
  Future<void> updatePermissionBannerStatus(bool hasShown) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('smart_alerts')
          .set({
        'hasPermissionDeniedBannerShown': hasShown,
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  /// Stream smart alert settings
  Stream<SmartAlertSettings?> watchSmartAlertSettings() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('smart_alerts')
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return SmartAlertSettings.fromDoc(doc);
      }
      return const SmartAlertSettings();
    });
  }
}

@riverpod
SmartAlertsRepository smartAlertsRepository(Ref ref) {
  return SmartAlertsRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
}
