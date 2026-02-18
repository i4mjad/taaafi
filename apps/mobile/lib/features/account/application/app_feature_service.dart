import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/app_feature.dart';

/// Service responsible for app feature operations only (SRP)
class AppFeatureService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== FEATURE QUERIES ====================

  /// Get all app features
  Future<List<AppFeature>> getAppFeatures() async {
    try {
      final querySnapshot = await _firestore
          .collection('features')
          .where('isActive', isEqualTo: true)
          .orderBy('category')
          .orderBy('nameEn')
          .get();

      return querySnapshot.docs
          .map((doc) => AppFeature.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw AppFeatureServiceException('Error fetching app features: $e');
    }
  }

  /// Get specific feature by unique name
  Future<AppFeature?> getFeatureByUniqueName(String uniqueName) async {
    try {
      final querySnapshot = await _firestore
          .collection('features')
          .where('uniqueName', isEqualTo: uniqueName)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return AppFeature.fromFirestore(querySnapshot.docs.first);
      }

      return null;
    } catch (e) {
      throw AppFeatureServiceException(
          'Error fetching feature by unique name: $e');
    }
  }

  /// Validate feature exists
  Future<bool> isValidFeature(String uniqueName) async {
    final feature = await getFeatureByUniqueName(uniqueName);
    return feature != null;
  }
}

// ==================== EXCEPTIONS ====================

class AppFeatureServiceException implements Exception {
  final String message;
  AppFeatureServiceException(this.message);

  @override
  String toString() => 'AppFeatureServiceException: $message';
}
