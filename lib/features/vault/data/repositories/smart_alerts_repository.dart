import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:reboot_app_3/features/vault/data/models/smart_alert_settings.dart';

part 'smart_alerts_repository.g.dart';

class SmartAlertsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SmartAlertsRepository(this._firestore, this._auth);

  /// Get current user's smart alert settings
  Future<SmartAlertSettings?> getSmartAlertSettings() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('smart_alerts')
          .get();

      if (doc.exists) {
        return SmartAlertSettings.fromDoc(doc);
      }

      // Return default settings if no document exists
      return const SmartAlertSettings();
    } catch (e) {
      return null;
    }
  }

  /// Save smart alert settings
  Future<void> saveSmartAlertSettings(SmartAlertSettings settings) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
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

  /// Update specific setting
  Future<void> updateAlertToggle(SmartAlertType type, bool enabled) async {
    final user = _auth.currentUser;
    if (user == null) return;

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

  /// Update calculated risk hour
  Future<void> updateRiskHour(int riskHour) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('smart_alerts')
          .set({
        'lastCalculatedRiskHour': riskHour,
        'lastRiskHourCalculation': Timestamp.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  /// Update vulnerable weekday
  Future<void> updateVulnerableWeekday(int weekday) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('smart_alerts')
          .set({
        'lastCalculatedVulnerableWeekday': weekday,
        'lastVulnerabilityCalculation': Timestamp.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  /// Update vulnerability alert hour
  Future<void> updateVulnerabilityAlertHour(int hour) async {
    final user = _auth.currentUser;
    if (user == null) return;

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
