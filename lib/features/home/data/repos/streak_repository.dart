import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/monitoring/error_logger.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'streak_repository.g.dart';

class StreakRepository {
  final FirebaseFirestore _firestore;
  final Ref ref;

  StreakRepository(this._firestore, this.ref);

  String? _getUserId() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  Future<DateTime> getUserFirstDate() async {
    try {
      final uid = _getUserId();
      if (uid == null) throw Exception('User not logged in');
      final docRef = _firestore.collection('users').doc(uid);
      final doc = await docRef.get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['userFirstDate'] != null) {
          return (data['userFirstDate'] as Timestamp).toDate();
        }
      }

      // If missing, throw; upper layers should ensure user completes registration.
      throw Exception('User first date not found');
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  Future<List<FollowUpModel>> readFollowUpsByType(FollowUpType type) async {
    try {
      final uid = _getUserId();
      if (uid == null) throw Exception('User not logged in');
      final querySnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('followUps')
          .where('type', isEqualTo: type.name)
          .get();
      return querySnapshot.docs
          .map((doc) => FollowUpModel.fromDoc(doc))
          .toList();
    } catch (e, stackTrace) {
      ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }
}

@Riverpod(keepAlive: true)
StreakRepository streakRepository(StreakRepositoryRef ref) {
  final firestore = FirebaseFirestore.instance;
  return StreakRepository(firestore, ref);
}
