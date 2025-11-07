import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../application/groups_providers.dart';
import '../domain/entities/group_entity.dart';
import '../../community/domain/entities/community_profile_entity.dart';
import '../../community/presentation/providers/community_providers_new.dart';
import '../../plus/data/notifiers/subscription_notifier.dart';
import 'group_membership_provider.dart';

part 'group_settings_provider.g.dart';

/// State for group settings
class GroupSettingsState {
  final bool isLoading;
  final GroupEntity? group;
  final CommunityProfileEntity? userProfile;
  final bool isUserAdmin;
  final bool isUserPlus;
  final int? actualMemberCount; // Real-time member count from Firestore
  final String? error;
  final String? successMessage;

  const GroupSettingsState({
    this.isLoading = false,
    this.group,
    this.userProfile,
    this.isUserAdmin = false,
    this.isUserPlus = false,
    this.actualMemberCount,
    this.error,
    this.successMessage,
  });

  GroupSettingsState copyWith({
    bool? isLoading,
    GroupEntity? group,
    CommunityProfileEntity? userProfile,
    bool? isUserAdmin,
    bool? isUserPlus,
    int? actualMemberCount,
    String? error,
    String? successMessage,
  }) {
    return GroupSettingsState(
      isLoading: isLoading ?? this.isLoading,
      group: group ?? this.group,
      userProfile: userProfile ?? this.userProfile,
      isUserAdmin: isUserAdmin ?? this.isUserAdmin,
      isUserPlus: isUserPlus ?? this.isUserPlus,
      actualMemberCount: actualMemberCount ?? this.actualMemberCount,
      error: error,
      successMessage: successMessage,
    );
  }
}

/// Provider for group settings state
@riverpod
class GroupSettings extends _$GroupSettings {
  @override
  Future<GroupSettingsState> build() async {
    try {
      // Get current community profile
      final profile = await ref.watch(currentCommunityProfileProvider.future);
      if (profile == null) {
        return const GroupSettingsState(
          error: 'No community profile found',
        );
      }

      // Get settings service
      final settingsService = ref.watch(groupSettingsServiceProvider);

      // Get user's current group and check if they're admin
      final group = await settingsService.getCurrentUserGroup(profile.id);
      final isAdmin = group != null
          ? await settingsService.isUserGroupAdmin(profile.id)
          : false;

      // Check Plus status using the proper provider
      final isPlus = ref.watch(hasActiveSubscriptionProvider);

      // Get real-time member count if group exists
      int? memberCount;
      if (group != null) {
        memberCount = await settingsService.getGroupMemberCount(group.id);
      }

      return GroupSettingsState(
        group: group,
        userProfile: profile,
        isUserAdmin: isAdmin,
        isUserPlus: isPlus,
        actualMemberCount: memberCount,
      );
    } catch (e) {
      return GroupSettingsState(
        error: e.toString(),
      );
    }
  }

  /// Update group capacity (admin only)
  Future<void> updateCapacity(int newCapacity) async {
    final currentState = await future;
    if (currentState.group == null || !currentState.isUserAdmin) {
      state = AsyncValue.data(currentState.copyWith(
        error: 'error-admin-permission-required',
      ));
      return;
    }

    state = AsyncValue.data(currentState.copyWith(isLoading: true));

    try {
      final settingsService = ref.read(groupSettingsServiceProvider);
      final updatedGroup = await settingsService.updateGroupCapacity(
        groupId: currentState.group!.id,
        adminCpId: currentState.userProfile!.id,
        newCapacity: newCapacity,
      );

      // Refresh group membership provider to get updated data
      ref.invalidate(groupMembershipNotifierProvider);

      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        group: updatedGroup,
        error: null,
        successMessage: 'capacity-updated-successfully',
      ));
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  /// Update group details (name and/or description) (admin only)
  Future<void> updateDetails({
    String? name,
    String? description,
  }) async {
    final currentState = await future;
    if (currentState.group == null || !currentState.isUserAdmin) {
      state = AsyncValue.data(currentState.copyWith(
        error: 'error-admin-permission-required',
      ));
      return;
    }

    state = AsyncValue.data(currentState.copyWith(isLoading: true));

    try {
      final settingsService = ref.read(groupSettingsServiceProvider);
      final updatedGroup = await settingsService.updateGroupDetails(
        groupId: currentState.group!.id,
        adminCpId: currentState.userProfile!.id,
        name: name,
        description: description,
      );

      // Refresh group membership provider to get updated data
      ref.invalidate(groupMembershipNotifierProvider);

      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        group: updatedGroup,
        error: null,
        successMessage: 'details-updated-successfully',
      ));
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  /// Clear any error or success message
  void clearMessages() {
    state.whenData((currentState) {
      if (currentState.error != null || currentState.successMessage != null) {
        state = AsyncValue.data(currentState.copyWith(
          error: null,
          successMessage: null,
        ));
      }
    });
  }
}

