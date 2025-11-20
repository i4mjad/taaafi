import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/referral_repository.dart';
import '../models/referral_code_model.dart';
import '../models/referral_stats_model.dart';

class ReferralRepositoryImpl implements ReferralRepository {
  final FirebaseFirestore _firestore;

  const ReferralRepositoryImpl(this._firestore);

  @override
  Future<ReferralCodeModel?> getUserReferralCode(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('referralCodes')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return ReferralCodeModel.fromFirestore(querySnapshot.docs.first);
    } catch (e, stackTrace) {
      log('Error in getUserReferralCode: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<ReferralStatsModel?> getReferralStats(String userId) async {
    try {
      final docSnapshot =
          await _firestore.collection('referralStats').doc(userId).get();

      if (!docSnapshot.exists) {
        return null;
      }

      return ReferralStatsModel.fromFirestore(docSnapshot);
    } catch (e, stackTrace) {
      log('Error in getReferralStats: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> validateReferralCode(String code) async {
    try {
      final querySnapshot = await _firestore
          .collection('referralCodes')
          .where('code', isEqualTo: code.toUpperCase())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e, stackTrace) {
      log('Error in validateReferralCode: $e', stackTrace: stackTrace);
      return false;
    }
  }

  @override
  Future<ReferralCodeModel?> getReferralCodeByCode(String code) async {
    try {
      final querySnapshot = await _firestore
          .collection('referralCodes')
          .where('code', isEqualTo: code.toUpperCase())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return ReferralCodeModel.fromFirestore(querySnapshot.docs.first);
    } catch (e, stackTrace) {
      log('Error in getReferralCodeByCode: $e', stackTrace: stackTrace);
      rethrow;
    }
  }
}
