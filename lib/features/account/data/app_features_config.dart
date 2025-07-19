import 'models/app_feature.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Configuration class for app features
/// This defines all features that can be banned or restricted
class AppFeaturesConfig {
  // Firestore instance for fetching features
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Feature unique names - these are used to link features to functionality
  static const String contactAdmin = 'contact_admin';
  static const String postCreation = 'post_creation';
  static const String commentCreation = 'comment_creation';
  static const String communityInteraction = 'community_interaction';

  //TODO: introduce this later through admin control §portal

  // static const String directMessaging = 'direct_messaging';
  // static const String groupCreation = 'group_creation';
  // static const String feedbackSubmission = 'feedback_submission';
  // static const String profileUpdate = 'profile_update';
  // static const String dataExport = 'data_export';
  // static const String communityAccess = 'community_access';

  /// Get all active app features from Firestore
  static Future<List<AppFeature>> getAllFeatures() async {
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
      return [];
    }
  }

  /// Get feature by unique name for easy access
  static Future<AppFeature?> getFeatureByUniqueName(String uniqueName) async {
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
      return null;
    }
  }

  /// Check if a feature unique name is valid
  static Future<bool> isValidFeature(String uniqueName) async {
    try {
      final querySnapshot = await _firestore
          .collection('features')
          .where('uniqueName', isEqualTo: uniqueName)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get features by category
  static Future<List<AppFeature>> getFeaturesByCategory(
      FeatureCategory category) async {
    try {
      final querySnapshot = await _firestore
          .collection('features')
          .where('category', isEqualTo: category.toString().split('.').last)
          .where('isActive', isEqualTo: true)
          .orderBy('nameEn')
          .get();

      return querySnapshot.docs
          .map((doc) => AppFeature.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get all communication features
  static Future<List<AppFeature>> getCommunicationFeatures() async {
    return await getFeaturesByCategory(FeatureCategory.communication);
  }

  /// Get all social features
  static Future<List<AppFeature>> getSocialFeatures() async {
    return await getFeaturesByCategory(FeatureCategory.social);
  }

  /// Get all content features
  static Future<List<AppFeature>> getContentFeatures() async {
    return await getFeaturesByCategory(FeatureCategory.content);
  }

  /// Get all settings features
  static Future<List<AppFeature>> getSettingsFeatures() async {
    return await getFeaturesByCategory(FeatureCategory.settings);
  }

  /// Get all bannable features
  static Future<List<AppFeature>> getBannableFeatures() async {
    try {
      final querySnapshot = await _firestore
          .collection('features')
          .where('isActive', isEqualTo: true)
          .where('isBannable', isEqualTo: true)
          .orderBy('category')
          .orderBy('nameEn')
          .get();

      return querySnapshot.docs
          .map((doc) => AppFeature.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
