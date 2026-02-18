import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/monitoring/error_logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fcm_topic_service.g.dart';

/// Abstract interface for FCM topic operations
abstract class FcmTopicService {
  Future<bool> subscribeToTopic(String topicId);
  Future<bool> unsubscribeFromTopic(String topicId);
  Future<bool> subscribeToMultipleTopics(List<String> topicIds);
  Future<bool> unsubscribeFromMultipleTopics(List<String> topicIds);
}

/// Implementation of FCM topic service
class FcmTopicServiceImpl implements FcmTopicService {
  final FirebaseMessaging _firebaseMessaging;
  final Ref _ref;

  FcmTopicServiceImpl(this._firebaseMessaging, this._ref);

  @override
  Future<bool> subscribeToTopic(String topicId) async {
    try {
      if (topicId.isEmpty) {
        throw ArgumentError('Topic ID cannot be empty');
      }

      // Sanitize topic ID to match FCM requirements
      final sanitizedTopicId = _sanitizeTopicId(topicId);

      await _firebaseMessaging.subscribeToTopic(sanitizedTopicId);
      return true;
    } catch (e, stackTrace) {
      _ref.read(errorLoggerProvider).logException(
            Exception('Failed to subscribe to FCM topic: $topicId - $e'),
            stackTrace,
          );
      return false;
    }
  }

  @override
  Future<bool> unsubscribeFromTopic(String topicId) async {
    try {
      if (topicId.isEmpty) {
        throw ArgumentError('Topic ID cannot be empty');
      }

      // Sanitize topic ID to match FCM requirements
      final sanitizedTopicId = _sanitizeTopicId(topicId);

      await _firebaseMessaging.unsubscribeFromTopic(sanitizedTopicId);
      return true;
    } catch (e, stackTrace) {
      _ref.read(errorLoggerProvider).logException(
            Exception('Failed to unsubscribe from FCM topic: $topicId - $e'),
            stackTrace,
          );
      return false;
    }
  }

  @override
  Future<bool> subscribeToMultipleTopics(List<String> topicIds) async {
    if (topicIds.isEmpty) return true;

    final results = await Future.wait(
      topicIds.map((topicId) => subscribeToTopic(topicId)),
    );

    // Return true only if all subscriptions succeeded
    return results.every((result) => result);
  }

  @override
  Future<bool> unsubscribeFromMultipleTopics(List<String> topicIds) async {
    if (topicIds.isEmpty) return true;

    final results = await Future.wait(
      topicIds.map((topicId) => unsubscribeFromTopic(topicId)),
    );

    // Return true only if all unsubscriptions succeeded
    return results.every((result) => result);
  }

  /// Sanitize topic ID to match FCM requirements
  /// Topic names must match the regular expression: "[a-zA-Z0-9-_.~%]+".
  String _sanitizeTopicId(String topicId) {
    return topicId.replaceAll(RegExp(r'[^a-zA-Z0-9\-_.~%]'), '_');
  }
}

@riverpod
FcmTopicService fcmTopicService(Ref ref) {
  return FcmTopicServiceImpl(FirebaseMessaging.instance, ref);
}
