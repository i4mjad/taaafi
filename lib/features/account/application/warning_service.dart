import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/warning.dart';
import 'device_service.dart';

/// Service responsible for warning-related operations only (SRP)
class WarningService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DeviceService _deviceService = DeviceService();

  // ==================== WARNING QUERIES ====================

  /// Get user's active warnings
  Future<List<Warning>> getUserWarnings(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('warnings')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('issuedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Warning.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw WarningServiceException('Error fetching user warnings: $e');
    }
  }

  /// Get high priority warnings for current user
  Future<List<Warning>> getCurrentUserHighPriorityWarnings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final warnings = await getUserWarnings(user.uid);
      return warnings
          .where((warning) =>
              warning.severity == WarningSeverity.high ||
              warning.severity == WarningSeverity.critical)
          .toList();
    } catch (e) {
      throw WarningServiceException(
          'Error fetching high priority warnings: $e');
    }
  }

  /// Get device warning history for violations (for admin panel)
  Future<List<Warning>> getDeviceWarningHistory(String userId) async {
    try {
      final userDeviceIds = await _deviceService.getUserDeviceIds(userId);
      if (userDeviceIds.isEmpty) {
        return [];
      }

      // Limit to 10 device IDs for Firestore query limitations
      final limitedDeviceIds = userDeviceIds.take(10).toList();

      // Query warnings with matching device IDs
      final warningsQuery = await _firestore
          .collection('warnings')
          .where('deviceIds', arrayContainsAny: limitedDeviceIds)
          .orderBy('issuedAt', descending: true)
          .limit(20)
          .get();

      return warningsQuery.docs
          .map((doc) => Warning.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw WarningServiceException(
          'Error fetching device warning history: $e');
    }
  }

  // ==================== VALIDATION ====================

  /// Validate warning creation
  void validateWarningCreation({
    required String reason,
  }) {
    // Reason is always required
    if (reason.trim().isEmpty) {
      throw WarningValidationException('Reason is required');
    }
  }
}

// ==================== EXCEPTIONS ====================

class WarningServiceException implements Exception {
  final String message;
  WarningServiceException(this.message);

  @override
  String toString() => 'WarningServiceException: $message';
}

class WarningValidationException implements Exception {
  final String message;
  WarningValidationException(this.message);

  @override
  String toString() => 'WarningValidationException: $message';
}
