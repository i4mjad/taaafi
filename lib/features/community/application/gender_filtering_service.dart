import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing gender-based filtering in community features
///
/// This service handles:
/// - Admin community profile identification and caching
/// - Same-gender community profile management
/// - Validation for comments and interactions based on gender rules
/// - Efficient caching to minimize database lookups
class GenderFilteringService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache management for performance
  final Map<String, List<String>> _genderProfileCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  List<String>? _cachedAdminCPIds;
  DateTime? _lastAdminCacheUpdate;

  static const Duration _cacheExpiry = Duration(minutes: 30);

  /// Get admin community profile IDs with caching
  ///
  /// Returns a list of community profile IDs that belong to admin users.
  /// Results are cached for 30 minutes to improve performance.
  Future<List<String>> getAdminCommunityProfileIds() async {
    // Return cached data if still valid
    if (_cachedAdminCPIds != null &&
        _lastAdminCacheUpdate != null &&
        DateTime.now().difference(_lastAdminCacheUpdate!) < _cacheExpiry) {
      return _cachedAdminCPIds!;
    }

    try {
      // Get admin user IDs from users collection
      final adminUsersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      final adminUserIds =
          adminUsersSnapshot.docs.map((doc) => doc.id).toList();

      if (adminUserIds.isEmpty) {
        _cachedAdminCPIds = [];
        _lastAdminCacheUpdate = DateTime.now();
        return [];
      }

      // Get community profiles for admin users in batches (Firestore whereIn limit is 10)
      final List<String> adminCPIds = [];
      const int batchSize = 10;

      for (int i = 0; i < adminUserIds.length; i += batchSize) {
        final batch = adminUserIds.skip(i).take(batchSize).toList();

        final cpSnapshot = await _firestore
            .collection('communityProfiles')
            .where(FieldPath.documentId, whereIn: batch)
            .where('isDeleted', isEqualTo: false)
            .get();

        adminCPIds.addAll(cpSnapshot.docs.map((doc) => doc.id));
      }

      // Cache the results
      _cachedAdminCPIds = adminCPIds;
      _lastAdminCacheUpdate = DateTime.now();

      return adminCPIds;
    } catch (e) {
      print('Error fetching admin community profiles: $e');
      return _cachedAdminCPIds ?? [];
    }
  }

  /// Get same gender community profile IDs efficiently
  ///
  /// [gender] The gender to filter by ('male' or 'female')
  /// Returns a list of community profile IDs for users of the specified gender
  Future<List<String>> getSameGenderProfileIds(String gender) async {
    final cacheKey = 'gender_$gender';

    // Check cache validity
    if (_genderProfileCache.containsKey(cacheKey) &&
        _cacheTimestamps.containsKey(cacheKey) &&
        DateTime.now().difference(_cacheTimestamps[cacheKey]!) < _cacheExpiry) {
      return _genderProfileCache[cacheKey]!;
    }

    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('communityProfiles')
          .where('gender', isEqualTo: gender)
          .where('isDeleted', isEqualTo: false)
          .get();

      final profileIds = snapshot.docs.map((doc) => doc.id).toList();

      // Cache results
      _genderProfileCache[cacheKey] = profileIds;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return profileIds;
    } catch (e) {
      print('Error fetching same gender profiles: $e');
      return _genderProfileCache[cacheKey] ?? [];
    }
  }

  /// Get community profile IDs that should be visible to the current user
  /// (same gender + all admins)
  ///
  /// [currentUserGender] The current user's gender
  /// Returns combined list of same-gender users and admin users
  Future<List<String>> getVisibleCommunityProfileIds(
      String currentUserGender) async {
    try {
      // Get same gender profiles and admin profiles in parallel
      final results = await Future.wait([
        getSameGenderProfileIds(currentUserGender),
        getAdminCommunityProfileIds(),
      ]);

      final sameGenderIds = results[0];
      final adminIds = results[1];

      // Combine and deduplicate
      final visibleIds = <String>{...sameGenderIds, ...adminIds}.toList();

      return visibleIds;
    } catch (e) {
      print('Error fetching visible community profiles: $e');
      return [];
    }
  }

  /// Validate if a user can interact with content based on gender rules
  ///
  /// [currentUserGender] The current user's gender
  /// [targetAuthorCPId] The community profile ID of the content author
  /// Returns true if interaction is allowed, false otherwise
  Future<bool> canInteractWithContent(
      String currentUserGender, String targetAuthorCPId) async {
    try {
      final visibleProfileIds =
          await getVisibleCommunityProfileIds(currentUserGender);
      return visibleProfileIds.contains(targetAuthorCPId);
    } catch (e) {
      print('Error validating content interaction: $e');
      // Default to allowing interaction on error to avoid blocking users
      return true;
    }
  }

  /// Check if a specific community profile belongs to an admin
  ///
  /// [cpId] The community profile ID to check
  /// Returns true if the profile belongs to an admin user
  Future<bool> isAdminCommunityProfile(String cpId) async {
    final adminIds = await getAdminCommunityProfileIds();
    return adminIds.contains(cpId);
  }

  /// Stream of visible community profile IDs
  ///
  /// [currentUserGender] The current user's gender
  /// Returns a stream that updates when profile visibility changes
  Stream<List<String>> watchVisibleCommunityProfileIds(
      String currentUserGender) async* {
    try {
      // Get admin IDs (cached)
      final adminIds = await getAdminCommunityProfileIds();

      // Watch same-gender profiles and combine with admin IDs
      await for (final snapshot in _firestore
          .collection('communityProfiles')
          .where('gender', isEqualTo: currentUserGender)
          .where('isDeleted', isEqualTo: false)
          .snapshots()) {
        final sameGenderIds = snapshot.docs.map((doc) => doc.id).toList();
        final visibleIds = <String>{...sameGenderIds, ...adminIds}.toList();

        yield visibleIds;
      }
    } catch (e) {
      print('Error watching visible community profiles: $e');
      yield [];
    }
  }

  /// Clear all caches - useful when admin roles change or for testing
  void clearCache() {
    _genderProfileCache.clear();
    _cacheTimestamps.clear();
    _cachedAdminCPIds = null;
    _lastAdminCacheUpdate = null;
  }

  /// Clear only admin cache - useful when admin roles change
  void clearAdminCache() {
    _cachedAdminCPIds = null;
    _lastAdminCacheUpdate = null;
  }
}
