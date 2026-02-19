import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/monitoring/error_logger.dart';
import 'package:reboot_app_3/features/fort/domain/models/fort_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fort_repository.g.dart';

class FortRepository {
  final FirebaseFirestore _firestore;
  final Ref _ref;

  FortRepository(this._firestore, this._ref);

  String? _getUserId() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (e, stackTrace) {
      _ref.read(errorLoggerProvider).logException(e, stackTrace);
      rethrow;
    }
  }

  /// Get the current fort state from Firestore.
  Future<FortState> getFortState() async {
    try {
      final uid = _getUserId();
      if (uid == null) return FortState.initial();

      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('fortState')
          .doc('current')
          .get();

      if (!doc.exists || doc.data() == null) return FortState.initial();
      return FortState.fromJson(doc.data()!);
    } catch (e, stackTrace) {
      _ref.read(errorLoggerProvider).logException(e, stackTrace);
      return FortState.initial();
    }
  }

  /// Save the fort state to Firestore.
  Future<void> saveFortState(FortState state) async {
    try {
      final uid = _getUserId();
      if (uid == null) return;

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('fortState')
          .doc('current')
          .set(state.toJson(), SetOptions(merge: true));
    } catch (e, stackTrace) {
      _ref.read(errorLoggerProvider).logException(e, stackTrace);
    }
  }

  /// Stream fort state changes in real-time.
  Stream<FortState> fortStateStream() {
    final uid = _getUserId();
    if (uid == null) return Stream.value(FortState.initial());

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('fortState')
        .doc('current')
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return FortState.initial();
      return FortState.fromJson(doc.data()!);
    });
  }
}

@Riverpod(keepAlive: true)
FortRepository fortRepository(Ref ref) {
  return FortRepository(FirebaseFirestore.instance, ref);
}
