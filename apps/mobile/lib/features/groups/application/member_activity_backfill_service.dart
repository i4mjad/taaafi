import 'dart:developer';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service for backfilling activity data for group members
/// 
/// Security: Users can ONLY backfill their OWN data
class MemberActivityBackfillService {
  final FirebaseFunctions _functions;

  MemberActivityBackfillService(this._functions);

  /// Backfill activity data for the current user in a group
  /// 
  /// This will:
  /// - Count historical messages
  /// - Update messageCount, lastActiveAt, engagementScore
  /// - Award retroactive achievements
  /// 
  /// Throws [BackfillException] if the operation fails
  Future<BackfillResult> backfillMyActivity(String groupId) async {
    try {
      log('Triggering activity backfill for group: $groupId');

      final callable = _functions.httpsCallable('backfillMemberActivity');
      
      final result = await callable.call({
        'groupId': groupId,
      });

      final data = result.data as Map<String, dynamic>;
      
      final backfillResult = BackfillResult.fromJson(data);
      
      log('✅ Backfill complete: ${backfillResult.summary}');
      
      return backfillResult;
      
    } on FirebaseFunctionsException catch (e) {
      log('❌ Backfill failed: ${e.code} - ${e.message}');
      
      throw BackfillException(
        code: e.code,
        message: _getUserFriendlyMessage(e.code, e.message),
      );
    } catch (e) {
      log('❌ Unexpected error during backfill: $e');
      
      throw BackfillException(
        code: 'unknown',
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Convert error codes to user-friendly messages
  String _getUserFriendlyMessage(String code, String? message) {
    switch (code) {
      case 'unauthenticated':
        return 'You must be signed in to refresh activity data.';
      case 'not-found':
        return 'You are not a member of this group.';
      case 'permission-denied':
        return 'You do not have permission to perform this action.';
      case 'invalid-argument':
        return 'Invalid request. Please try again.';
      default:
        return message ?? 'An error occurred. Please try again.';
    }
  }
}

/// Result of backfill operation
class BackfillResult {
  final bool success;
  final String groupId;
  final String cpId;
  final int messagesBackfilled;
  final int achievementsAwarded;
  final int messageCount;
  final int engagementScore;
  final DateTime? lastActiveAt;

  BackfillResult({
    required this.success,
    required this.groupId,
    required this.cpId,
    required this.messagesBackfilled,
    required this.achievementsAwarded,
    required this.messageCount,
    required this.engagementScore,
    this.lastActiveAt,
  });

  factory BackfillResult.fromJson(Map<String, dynamic> json) {
    return BackfillResult(
      success: json['success'] as bool,
      groupId: json['groupId'] as String,
      cpId: json['cpId'] as String,
      messagesBackfilled: json['messagesBackfilled'] as int,
      achievementsAwarded: json['achievementsAwarded'] as int,
      messageCount: json['messageCount'] as int,
      engagementScore: json['engagementScore'] as int,
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.parse(json['lastActiveAt'] as String)
          : null,
    );
  }

  /// Human-readable summary of the backfill operation
  String get summary {
    return 'Backfilled $messagesBackfilled messages, '
           'awarded $achievementsAwarded achievements, '
           'engagement score: $engagementScore';
  }

  /// Check if the user had any activity
  bool get hadActivity => messagesBackfilled > 0;

  /// Check if any achievements were awarded
  bool get hadAchievements => achievementsAwarded > 0;
}

/// Exception thrown when backfill fails
class BackfillException implements Exception {
  final String code;
  final String message;

  BackfillException({
    required this.code,
    required this.message,
  });

  @override
  String toString() => 'BackfillException($code): $message';
}

/// Provider for backfill service
final memberActivityBackfillServiceProvider = Provider<MemberActivityBackfillService>((ref) {
  return MemberActivityBackfillService(FirebaseFunctions.instance);
});

