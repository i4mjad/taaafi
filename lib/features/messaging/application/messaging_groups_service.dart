import 'package:reboot_app_3/features/messaging/data/models/messaging_group.dart';
import 'package:reboot_app_3/features/messaging/data/models/user_group_membership.dart';
import 'package:reboot_app_3/features/messaging/data/repositories/messaging_groups_repository.dart';
import 'package:reboot_app_3/features/plus/application/subscription_service.dart';

class MessagingGroupsService {
  final MessagingGroupsRepository _repository;
  final SubscriptionService _subscriptionService;

  MessagingGroupsService(this._repository, this._subscriptionService);

  /// Get all available messaging groups
  Future<List<MessagingGroup>> getAvailableGroups() async {
    return await _repository.getAvailableGroups();
  }

  /// Stream of available messaging groups
  Stream<List<MessagingGroup>> watchAvailableGroups() {
    return _repository.watchAvailableGroups();
  }

  /// Get user's current group memberships
  Future<UserGroupMemberships?> getUserGroupMemberships() async {
    return await _repository.getUserGroupMemberships();
  }

  /// Stream of user's group memberships
  Stream<UserGroupMemberships?> watchUserGroupMemberships() {
    return _repository.watchUserGroupMemberships();
  }

  /// Check if user can subscribe to a group (handles plus user validation)
  Future<bool> canSubscribeToGroup(MessagingGroup group) async {
    try {
      // Check if already subscribed
      final isAlreadySubscribed =
          await _repository.isSubscribedToGroup(group.topicId);
      if (isAlreadySubscribed) {
        return false;
      }

      // If group is for plus users only, check subscription status
      if (group.isForPlusUsers) {
        final hasActiveSubscription =
            await _subscriptionService.isSubscriptionActive();
        return hasActiveSubscription;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Subscribe to a messaging group
  Future<SubscriptionResult> subscribeToGroup(MessagingGroup group,
      {bool? hasActiveSubscription}) async {
    try {
      // Check if already subscribed
      final isAlreadySubscribed =
          await _repository.isSubscribedToGroup(group.topicId);

      if (isAlreadySubscribed) {
        return SubscriptionResult.alreadySubscribed();
      }

      // If group is for plus users only, check subscription status
      if (group.isForPlusUsers) {
        // Use provided subscription status or fallback to service check
        final effectiveSubscriptionStatus = hasActiveSubscription ??
            await _subscriptionService.isSubscriptionActive();

        if (!effectiveSubscriptionStatus) {
          return SubscriptionResult.requiresPlusSubscription();
        }
      }

      // Subscribe to the group
      await _repository.subscribeToGroup(group);
      return SubscriptionResult.success();
    } catch (e) {
      return SubscriptionResult.error(e.toString());
    }
  }

  /// Unsubscribe from a messaging group
  Future<bool> unsubscribeFromGroup(String topicId) async {
    try {
      await _repository.unsubscribeFromGroup(topicId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if user is subscribed to a specific group
  Future<bool> isSubscribedToGroup(String topicId) async {
    return await _repository.isSubscribedToGroup(topicId);
  }

  /// Get subscribed topic IDs for the current user
  Future<List<String>> getSubscribedTopicIds() async {
    return await _repository.getSubscribedTopicIds();
  }

  /// Get groups with subscription status and plus requirements
  Future<List<GroupWithStatus>> getGroupsWithStatus(
      {bool? hasActiveSubscription}) async {
    try {
      final groups = await getAvailableGroups();
      final userMemberships = await getUserGroupMemberships();
      final subscribedTopics = userMemberships?.groups
              .map((membership) => membership.topicId)
              .toSet() ??
          <String>{};

      final effectiveSubscriptionStatus = hasActiveSubscription ??
          await _subscriptionService.isSubscriptionActive();

      return groups.map((group) {
        final isSubscribed = subscribedTopics.contains(group.topicId);
        final canSubscribe = !isSubscribed &&
            (!group.isForPlusUsers || effectiveSubscriptionStatus);
        final requiresPlusUpgrade =
            group.isForPlusUsers && !effectiveSubscriptionStatus;

        return GroupWithStatus(
          group: group,
          isSubscribed: isSubscribed,
          canSubscribe: canSubscribe,
          requiresPlusUpgrade: requiresPlusUpgrade,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }
}

/// Result of a subscription attempt
class SubscriptionResult {
  final SubscriptionStatus status;
  final String? errorMessage;

  const SubscriptionResult._({
    required this.status,
    this.errorMessage,
  });

  factory SubscriptionResult.success() => const SubscriptionResult._(
        status: SubscriptionStatus.success,
      );

  factory SubscriptionResult.alreadySubscribed() => const SubscriptionResult._(
        status: SubscriptionStatus.alreadySubscribed,
      );

  factory SubscriptionResult.requiresPlusSubscription() =>
      const SubscriptionResult._(
        status: SubscriptionStatus.requiresPlusSubscription,
      );

  factory SubscriptionResult.error(String message) => SubscriptionResult._(
        status: SubscriptionStatus.error,
        errorMessage: message,
      );

  bool get isSuccess => status == SubscriptionStatus.success;
  bool get isAlreadySubscribed =>
      status == SubscriptionStatus.alreadySubscribed;
  bool get requiresPlusSubscription =>
      status == SubscriptionStatus.requiresPlusSubscription;
  bool get isError => status == SubscriptionStatus.error;
}

enum SubscriptionStatus {
  success,
  alreadySubscribed,
  requiresPlusSubscription,
  error,
}

/// Group with subscription status information
class GroupWithStatus {
  final MessagingGroup group;
  final bool isSubscribed;
  final bool canSubscribe;
  final bool requiresPlusUpgrade;

  const GroupWithStatus({
    required this.group,
    required this.isSubscribed,
    required this.canSubscribe,
    required this.requiresPlusUpgrade,
  });
}
