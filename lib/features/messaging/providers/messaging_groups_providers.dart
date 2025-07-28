import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:reboot_app_3/core/messaging/fcm_topic_service.dart';
import 'package:reboot_app_3/features/messaging/application/messaging_groups_service.dart';
import 'package:reboot_app_3/features/messaging/data/models/messaging_group.dart';
import 'package:reboot_app_3/features/messaging/data/models/user_group_membership.dart';
import 'package:reboot_app_3/features/messaging/data/repositories/messaging_groups_repository.dart';
import 'package:reboot_app_3/features/plus/application/subscription_service.dart';
import 'package:reboot_app_3/features/plus/data/notifiers/subscription_notifier.dart';
import 'package:reboot_app_3/features/plus/data/repositories/subscription_repository.dart'
    as plus;

part 'messaging_groups_providers.g.dart';

// ==================== REPOSITORIES ====================

@riverpod
MessagingGroupsRepository messagingGroupsRepository(Ref ref) {
  return MessagingGroupsRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
    ref.watch(fcmTopicServiceProvider),
    ref,
  );
}

// ==================== SERVICES ====================

@riverpod
MessagingGroupsService messagingGroupsService(Ref ref) {
  final repository = ref.watch(messagingGroupsRepositoryProvider);
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return MessagingGroupsService(repository, subscriptionService);
}

// ==================== NOTIFIERS ====================

@riverpod
class MessagingGroupsNotifier extends _$MessagingGroupsNotifier {
  MessagingGroupsService get service =>
      ref.read(messagingGroupsServiceProvider);

  @override
  Future<List<GroupWithStatus>> build() async {
    // Watch subscription status to trigger rebuild when it changes
    final subscriptionAsync = ref.watch(subscriptionNotifierProvider);

    // Get subscription status from the notifier state, not from service
    final hasActiveSubscription = subscriptionAsync.when(
      data: (subscription) =>
          subscription.status == plus.SubscriptionStatus.plus &&
          subscription.isActive,
      loading: () => false,
      error: (_, __) => false,
    );

    return await service.getGroupsWithStatus(
        hasActiveSubscription: hasActiveSubscription);
  }

  /// Subscribe to a messaging group
  Future<void> subscribeToGroup(MessagingGroup group) async {
    state = const AsyncValue.loading();
    try {
      // Get current subscription status to pass to service
      final currentSubscription = ref.read(subscriptionNotifierProvider);
      final hasActiveSubscription = currentSubscription.when(
        data: (subscription) =>
            subscription.status == plus.SubscriptionStatus.plus &&
            subscription.isActive,
        loading: () => false,
        error: (_, __) => false,
      );

      final result = await service.subscribeToGroup(group,
          hasActiveSubscription: hasActiveSubscription);

      if (result.isSuccess) {
        // Refresh the state
        final currentSubscription = ref.read(subscriptionNotifierProvider);
        final hasActiveSubscription = currentSubscription.when(
          data: (subscription) =>
              subscription.status == plus.SubscriptionStatus.plus &&
              subscription.isActive,
          loading: () => false,
          error: (_, __) => false,
        );

        final refreshedGroups = await service.getGroupsWithStatus(
            hasActiveSubscription: hasActiveSubscription);
        state = AsyncValue.data(refreshedGroups);
      } else {
        // Handle specific error cases
        if (result.requiresPlusSubscription) {
          throw Exception('This feature requires Ta3afi Plus subscription');
        } else if (result.isAlreadySubscribed) {
          throw Exception('Already subscribed to this group');
        } else if (result.isError) {
          throw Exception(
              result.errorMessage ?? 'Failed to subscribe to group');
        }
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Unsubscribe from a messaging group
  Future<void> unsubscribeFromGroup(String topicId) async {
    state = const AsyncValue.loading();
    try {
      final success = await service.unsubscribeFromGroup(topicId);
      if (success) {
        // Refresh the state
        state = AsyncValue.data(await service.getGroupsWithStatus());
      } else {
        throw Exception('Failed to unsubscribe from group');
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Refresh the groups
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await service.getGroupsWithStatus());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ==================== STREAM PROVIDERS ====================

@riverpod
Stream<List<MessagingGroup>> availableGroupsStream(Ref ref) {
  final service = ref.watch(messagingGroupsServiceProvider);
  return service.watchAvailableGroups();
}

@riverpod
Stream<UserGroupMemberships?> userGroupMembershipsStream(Ref ref) {
  final service = ref.watch(messagingGroupsServiceProvider);
  return service.watchUserGroupMemberships();
}

// ==================== SIMPLE PROVIDERS ====================

@riverpod
Future<List<MessagingGroup>> availableGroups(Ref ref) async {
  final service = ref.watch(messagingGroupsServiceProvider);
  return await service.getAvailableGroups();
}

@riverpod
Future<UserGroupMemberships?> userGroupMemberships(Ref ref) async {
  final service = ref.watch(messagingGroupsServiceProvider);
  return await service.getUserGroupMemberships();
}

@riverpod
Future<List<String>> subscribedTopicIds(Ref ref) async {
  final service = ref.watch(messagingGroupsServiceProvider);
  return await service.getSubscribedTopicIds();
}

// ==================== UTILITY PROVIDERS ====================

@riverpod
Future<bool> isSubscribedToGroup(Ref ref, String topicId) async {
  final service = ref.watch(messagingGroupsServiceProvider);
  return await service.isSubscribedToGroup(topicId);
}

@riverpod
Future<bool> canSubscribeToGroup(Ref ref, MessagingGroup group) async {
  final service = ref.watch(messagingGroupsServiceProvider);
  return await service.canSubscribeToGroup(group);
}
