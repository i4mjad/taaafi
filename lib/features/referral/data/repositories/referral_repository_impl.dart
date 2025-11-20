import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/entities/redemption_result.dart';
import '../../domain/repositories/referral_repository.dart';
import '../models/referral_code_model.dart';
import '../models/referral_stats_model.dart';

class ReferralRepositoryImpl implements ReferralRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  const ReferralRepositoryImpl(this._firestore, this._functions);

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

  @override
  Future<RedemptionResult> redeemReferralCode(String code) async {
    try {
      log('Attempting to redeem referral code: $code');

      final callable = _functions.httpsCallable('redeemReferralCode');
      final result = await callable.call<Map<String, dynamic>>({
        'code': code.trim().toUpperCase(),
      });

      final data = result.data;

      if (data['success'] == true) {
        log('Referral code redeemed successfully');
        return RedemptionResult.success(
          referrerName: data['referrerName'] as String,
          referrerId: data['referrerId'] as String,
        );
      } else {
        final errorMessage = data['message'] as String? ?? 'Unknown error';
        return RedemptionResult.error(errorMessage);
      }
    } on FirebaseFunctionsException catch (e) {
      log('FirebaseFunctionsException: ${e.code} - ${e.message}');

      // Map error codes to localization keys
      String errorKey;
      switch (e.code) {
        case 'not-found':
          errorKey = 'referral.input.invalid';
          break;
        case 'already-exists':
          errorKey = 'referral.input.already_used';
          break;
        case 'invalid-argument':
          if (e.message?.contains('own code') == true) {
            errorKey = 'referral.input.own_code';
          } else {
            errorKey = 'referral.input.invalid';
          }
          break;
        case 'failed-precondition':
          errorKey = 'referral.input.invalid';
          break;
        case 'unauthenticated':
          errorKey = 'referral.input.invalid';
          break;
        default:
          errorKey = 'referral.input.invalid';
      }

      return RedemptionResult.error(errorKey);
    } catch (e, stackTrace) {
      log('Error in redeemReferralCode: $e', stackTrace: stackTrace);
      return RedemptionResult.error('referral.input.invalid');
    }
  }
}
