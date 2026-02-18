import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/monitoring/error_logger.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';
import 'package:reboot_app_3/features/authentication/data/models/user_document.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';
import 'data_restoration_notifier.dart';
import 'migration_data_model.dart';

/// Repository for data restoration and migration operations
class DataRestorationRepository {
  final FirebaseFirestore _firestore;
  final Ref ref;

  DataRestorationRepository(this._firestore, this.ref);

  String? _getUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  /// Gets the user document with legacy arrays
  Future<UserDocument?> getUserDocument() async {
    try {
      final uid = _getUserId();
      if (uid == null) throw Exception('User not logged in');

      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.server));

      if (!doc.exists) return null;

      return UserDocument.fromFirestore(doc);
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Updates the user document with hasCheckedForDataLoss flag
  Future<void> markAsCheckedForDataLoss() async {
    try {
      final uid = _getUserId();
      if (uid == null) throw Exception('User not logged in');

      await _firestore
          .collection('users')
          .doc(uid)
          .update({'hasCheckedForDataLoss': true});

      // Invalidate user document provider to refresh the cached data
      // This ensures the button disappears after the flag is updated
      ref.invalidate(userDocumentsNotifierProvider);
      ref.invalidate(shouldShowDataRestorationButtonProvider);
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Gets all follow-ups for the user
  Future<List<FollowUpModel>> getAllFollowUps() async {
    try {
      final uid = _getUserId();
      if (uid == null) throw Exception('User not logged in');

      final querySnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('followUps')
          .get();

      return querySnapshot.docs
          .map((doc) => FollowUpModel.fromDoc(doc))
          .toList();
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Creates missing follow-ups in batches
  Future<void> createMissingFollowUps({
    required List<String> missingDates,
    required String followUpType,
  }) async {
    try {
      final uid = _getUserId();
      if (uid == null) throw Exception('User not logged in');

      // Prevent duplicate entries within the same operation
      final dateTypeMap = <String, Set<String>>{};

      // Process dates in batches of 500 (Firestore limit)
      const batchSize = 500;

      for (int i = 0; i < missingDates.length; i += batchSize) {
        final batch = _firestore.batch();
        final endIndex = (i + batchSize < missingDates.length)
            ? i + batchSize
            : missingDates.length;

        final batchDates = missingDates.sublist(i, endIndex);

        for (final date in batchDates) {
          // Skip if we've already processed this date-type combination
          final key = '$date-$followUpType';
          if (dateTypeMap.containsKey(key)) continue;

          dateTypeMap[key] = {followUpType};

          // Create timestamp at midnight UTC
          final timestamp = Timestamp.fromDate(
            DateTime.parse('${date}T00:00:00.000Z'),
          );

          final docRef = _firestore
              .collection('users')
              .doc(uid)
              .collection('followUps')
              .doc();

          batch.set(docRef, {
            'time': timestamp,
            'type': followUpType,
          });
        }

        // Commit the batch
        await batch.commit();
      }
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Removes duplicate follow-ups for a specific type and date
  Future<void> removeDuplicatesForDate({
    required String date,
    required String followUpType,
  }) async {
    try {
      final uid = _getUserId();
      if (uid == null) throw Exception('User not logged in');

      // Query all documents of the specified type
      final querySnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('followUps')
          .where('type', isEqualTo: followUpType)
          .get();

      // Filter documents that match the specific date
      final matchingDocs = querySnapshot.docs.where((doc) {
        final data = doc.data();
        final timestamp = data['time'] as Timestamp?;
        if (timestamp == null) return false;

        final docDate = timestamp.toDate().toIso8601String().substring(0, 10);
        return docDate == date;
      }).toList();

      // If more than one document matches, keep the first and delete the rest
      if (matchingDocs.length > 1) {
        final batch = _firestore.batch();

        // Skip the first document, delete the rest
        for (int i = 1; i < matchingDocs.length; i++) {
          batch.delete(matchingDocs[i].reference);
        }

        await batch.commit();
      }
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Removes all duplicates for a category
  Future<void> removeDuplicatesForCategory({
    required List<String> duplicateDates,
    required String followUpType,
  }) async {
    try {
      for (final date in duplicateDates) {
        await removeDuplicatesForDate(
          date: date,
          followUpType: followUpType,
        );
      }
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Analyzes migration status for all categories
  Future<MigrationData> analyzeMigrationStatus() async {
    try {
      final userDoc = await getUserDocument();
      if (userDoc == null) {
        throw Exception('User document not found');
      }

      final followUps = await getAllFollowUps();

      // Analyze each category
      final relapses = _analyzeCategoryStatus(
        legacyDates: userDoc.userRelapses ?? [],
        followUps: followUps,
        followUpType: 'relapse',
      );

      final mastOnly = _analyzeCategoryStatus(
        legacyDates: userDoc.userMasturbatingWithoutWatching ?? [],
        followUps: followUps,
        followUpType: 'mastOnly',
      );

      final pornOnly = _analyzeCategoryStatus(
        legacyDates: userDoc.userWatchingWithoutMasturbating ?? [],
        followUps: followUps,
        followUpType: 'pornOnly',
      );

      return MigrationData(
        relapses: relapses,
        mastOnly: mastOnly,
        pornOnly: pornOnly,
      );
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Analyzes migration status for a specific category
  CategoryMigrationStatus _analyzeCategoryStatus({
    required List<String> legacyDates,
    required List<FollowUpModel> followUps,
    required String followUpType,
  }) {
    // Filter follow-ups by type and convert to date strings
    final migratedDates = followUps
        .where((f) => f.type == followUpType)
        .map((f) => f.time.toIso8601String().substring(0, 10))
        .where((date) =>
            legacyDates.contains(date)) // Only include dates in legacy
        .toList();

    // Build date count map
    final dateCount = <String, int>{};
    for (final date in migratedDates) {
      dateCount[date] = (dateCount[date] ?? 0) + 1;
    }

    // Find duplicates
    final duplicates = dateCount.entries
        .where((entry) => entry.value > 1)
        .map((entry) => entry.key)
        .toList();

    // Calculate duplicate details
    final duplicateDetails = duplicates.map((date) {
      final count = dateCount[date]!;
      return DuplicateDetail(
        date: date,
        count: count,
        extras: count - 1,
      );
    }).toList();

    final duplicateCount =
        duplicateDetails.fold<int>(0, (sum, detail) => sum + detail.extras);

    // Find missing dates
    final uniqueMigratedDates = dateCount.keys.toSet();
    final missing = legacyDates
        .where((date) => !uniqueMigratedDates.contains(date))
        .toList();

    return CategoryMigrationStatus(
      legacy: legacyDates,
      migrated: migratedDates,
      missing: missing,
      duplicates: duplicates,
      duplicateCount: duplicateCount,
      dateCount: dateCount,
      duplicateDetails: duplicateDetails,
      totalEntries: migratedDates.length,
      uniqueEntries: uniqueMigratedDates.length,
    );
  }

  /// Checks if user should see the data restoration button
  Future<bool> shouldShowDataRestorationButton() async {
    try {
      final userDoc = await getUserDocument();
      if (userDoc == null) return false;

      // Don't show if already checked
      if (userDoc.hasCheckedForDataLoss == true) return false;

      // Only show for users created before 15/2/2025
      if (userDoc.userFirstDate == null) return false;

      final userCreationDate = userDoc.userFirstDate!.toDate();
      final cutoffDate = DateTime(2025, 2, 15);

      return userCreationDate.isBefore(cutoffDate);
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      return false;
    }
  }
}
