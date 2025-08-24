import 'package:cloud_firestore/cloud_firestore.dart';
import '../exceptions/community_exceptions.dart';
import '../models/community_profile_model.dart';

/// Abstract datasource for community remote operations
abstract class CommunityRemoteDatasource {
  /// Creates a new community profile
  Future<void> createProfile(CommunityProfileModel profile);

  /// Gets a community profile by user ID
  Future<CommunityProfileModel?> getProfile(String uid);

  /// Updates an existing community profile
  Future<void> updateProfile(CommunityProfileModel profile);

  /// Deletes a community profile
  Future<void> deleteProfile(String uid);

  /// Checks if a profile exists for the given user ID
  Future<bool> profileExists(String uid);

  /// Watches a community profile for real-time updates
  Stream<CommunityProfileModel?> watchProfile(String uid);

  /// Records user interest in community features
  Future<void> recordInterest();
}

/// Implementation of CommunityRemoteDatasource using Firestore
///
/// This class handles all the low-level Firestore operations for community profiles.
/// It converts between Firestore documents and data models, handles errors,
/// and provides a clean interface for the repository layer.
class CommunityRemoteDatasourceImpl implements CommunityRemoteDatasource {
  final FirebaseFirestore _firestore;

  /// Collection reference for community profiles
  late final CollectionReference<Map<String, dynamic>> _profilesCollection;

  /// Collection reference for community interest tracking
  late final CollectionReference<Map<String, dynamic>> _interestCollection;

  CommunityRemoteDatasourceImpl(this._firestore) {
    _profilesCollection = _firestore.collection('communityProfiles');
    _interestCollection = _firestore.collection('communityInterest');
  }

  @override
  Future<void> createProfile(CommunityProfileModel profile) async {
    try {
      await _profilesCollection.doc(profile.id).set(profile.toFirestore());
    } on FirebaseException catch (e) {
      throw NetworkException(
        'Failed to create profile: ${e.message}',
        e.code,
      );
    } catch (e) {
      throw NetworkException(
        'Unexpected error creating profile: $e',
      );
    }
  }

  @override
  Future<CommunityProfileModel?> getProfile(String uid) async {
    try {
      // First try to get by document ID (community profile ID)
      final docSnapshot = await _profilesCollection.doc(uid).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;

        // Filter out deleted profiles
        if (data['isDeleted'] == true) {
          return null;
        }

        return CommunityProfileModel.fromFirestore(docSnapshot);
      }

      // If not found by document ID, try querying by userUID (Firebase Auth UID)
      final snapshot = await _profilesCollection
          .where('userUID', isEqualTo: uid)
          .where('isDeleted', isEqualTo: false)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs.first;
      final data = doc.data();

      // Filter out deleted profiles client-side to avoid permission issues
      if (data['isDeleted'] == true) {
        return null;
      }

      return CommunityProfileModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw NetworkException(
        'Failed to get profile: ${e.message}',
        e.code,
      );
    } catch (e) {
      print('❌ Datasource getProfile: Unexpected error: $e');
      throw NetworkException(
        'Unexpected error getting profile: $e',
      );
    }
  }

  @override
  Future<void> updateProfile(CommunityProfileModel profile) async {
    try {
      await _profilesCollection.doc(profile.id).update(profile.toFirestore());
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        throw const ProfileNotFoundException(
          'Profile not found for update',
          'PROFILE_NOT_FOUND',
        );
      }
      throw NetworkException(
        'Failed to update profile: ${e.message}',
        e.code,
      );
    } catch (e) {
      throw NetworkException(
        'Unexpected error updating profile: $e',
      );
    }
  }

  @override
  Future<void> deleteProfile(String uid) async {
    try {
      // Find the profile document by userUID
      final snapshot = await _profilesCollection
          .where('userUID', isEqualTo: uid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Delete the found document
        await _profilesCollection.doc(snapshot.docs.first.id).delete();
      }
    } on FirebaseException catch (e) {
      throw NetworkException(
        'Failed to delete profile: ${e.message}',
        e.code,
      );
    } catch (e) {
      throw NetworkException(
        'Unexpected error deleting profile: $e',
      );
    }
  }

  @override
  Future<bool> profileExists(String uid) async {
    try {
      final snapshot = await _profilesCollection
          .where('userUID', isEqualTo: uid)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return false;
      }

      final data = snapshot.docs.first.data();

      // Only consider it as existing if it's not deleted
      return data['isDeleted'] != true;
    } on FirebaseException catch (e) {
      throw NetworkException(
        'Failed to check profile existence: ${e.message}',
        e.code,
      );
    } catch (e) {
      throw NetworkException(
        'Unexpected error checking profile existence: $e',
      );
    }
  }

  @override
  Stream<CommunityProfileModel?> watchProfile(String uid) {
    try {
      // First try to watch by document ID (community profile ID)
      return _profilesCollection
          .doc(uid)
          .snapshots()
          .asyncExpand((docSnapshot) {
        if (docSnapshot.exists) {
          final data = docSnapshot.data()!;

          // Filter out deleted profiles
          if (data['isDeleted'] == true) {
            return Stream.value(null);
          }

          return Stream.value(CommunityProfileModel.fromFirestore(docSnapshot));
        }

        // If not found by document ID, try watching by userUID (Firebase Auth UID)
        return _profilesCollection
            .where('userUID', isEqualTo: uid)
            .where('isDeleted', isEqualTo: false)
            .limit(1)
            .snapshots()
            .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return null;
          }

          final doc = snapshot.docs.first;
          final data = doc.data();

          // Filter out deleted profiles client-side to avoid permission issues
          if (data['isDeleted'] == true) {
            return null;
          }

          return CommunityProfileModel.fromFirestore(doc);
        });
      });
    } on FirebaseException catch (e) {
      print('❌ Datasource watchProfile: Firebase error: $e');
      throw NetworkException(
        'Failed to watch profile: ${e.message}',
        e.code,
      );
    } catch (e) {
      print('❌ Datasource watchProfile: Unexpected error: $e');
      throw NetworkException(
        'Unexpected error watching profile: $e',
      );
    }
  }

  @override
  Future<void> recordInterest() async {
    try {
      // Create a simple interest record with timestamp
      await _interestCollection.add({
        'timestamp': FieldValue.serverTimestamp(),
        'feature': 'community',
      });
    } on FirebaseException catch (e) {
      throw NetworkException(
        'Failed to record interest: ${e.message}',
        e.code,
      );
    } catch (e) {
      throw NetworkException(
        'Unexpected error recording interest: $e',
      );
    }
  }
}
