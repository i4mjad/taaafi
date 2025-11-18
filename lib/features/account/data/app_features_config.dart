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

  // Messaging features
  /// Used for sending messages in groups
  /// Also checked for direct messaging (shared permission)
  static const String sendMessage = 'sending_in_groups';

  /// Used for starting new direct message conversations
  /// Checked when user clicks "message" button on profile or tries to create new DM
  static const String startConversation = 'start_conversation';

  // Feature access guard
  static const String createPoll = 'create_a_poll';
  static const String shareMedia = 'share_a_media';
  static const String createOrJoinGroups = 'create_or_join_a_group';

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
