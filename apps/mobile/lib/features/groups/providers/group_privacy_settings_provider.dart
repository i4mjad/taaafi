import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../application/groups_providers.dart';
import '../domain/entities/group_entity.dart';
import '../../community/domain/entities/community_profile_entity.dart';
import '../../community/presentation/providers/community_providers_new.dart';
import 'group_membership_provider.dart';

part 'group_privacy_settings_provider.g.dart';

/// State for group privacy settings
class GroupPrivacyState {
  final bool isLoading;
  final GroupEntity? group;
  final CommunityProfileEntity? userProfile;
  final bool isUserAdmin;
  final String? error;

  const GroupPrivacyState({
    this.isLoading = false,
    this.group,
    this.userProfile,
    this.isUserAdmin = false,
    this.error,
  });

  GroupPrivacyState copyWith({
    bool? isLoading,
    GroupEntity? group,
    CommunityProfileEntity? userProfile,
    bool? isUserAdmin,
    String? error,
  }) {
    return GroupPrivacyState(
      isLoading: isLoading ?? this.isLoading,
      group: group ?? this.group,
      userProfile: userProfile ?? this.userProfile,
      isUserAdmin: isUserAdmin ?? this.isUserAdmin,
      error: error ?? this.error,
    );
  }
}

/// Provider for group privacy settings state
@riverpod
class GroupPrivacySettings extends _$GroupPrivacySettings {
  @override
  Future<GroupPrivacyState> build() async {
    try {
      // Get current community profile
      final profile = await ref.watch(currentCommunityProfileProvider.future);
      if (profile == null) {
        return const GroupPrivacyState(
          error: 'No community profile found',
        );
      }

      // Get privacy service
      final privacyService = ref.watch(groupPrivacyServiceProvider);

      // Get user's current group and check if they're admin
      final group = await privacyService.getCurrentUserGroup(profile.id);
      final isAdmin = group != null
          ? await privacyService.isUserGroupAdmin(profile.id)
          : false;

      return GroupPrivacyState(
        group: group,
        userProfile: profile,
        isUserAdmin: isAdmin,
      );
    } catch (e) {
      return GroupPrivacyState(
        error: e.toString(),
      );
    }
  }

  /// Update user's anonymity setting
  Future<void> updateUserAnonymity(bool isAnonymous) async {
    final currentState = await future;
    if (currentState.userProfile == null) return;

    state = AsyncValue.data(currentState.copyWith(isLoading: true));

    try {
      final privacyService = ref.read(groupPrivacyServiceProvider);
      await privacyService.updateUserAnonymity(
        cpId: currentState.userProfile!.id,
        isAnonymous: isAnonymous,
      );

      // Refresh community profile provider to get updated data
      ref.invalidate(currentCommunityProfileProvider);

      // Refresh this provider
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  /// Update group visibility setting (admin only)
  Future<void> updateGroupVisibility(String visibility) async {
    final currentState = await future;
    if (currentState.group == null || !currentState.isUserAdmin) return;

    state = AsyncValue.data(currentState.copyWith(isLoading: true));

    try {
      final privacyService = ref.read(groupPrivacyServiceProvider);
      final updatedGroup = await privacyService.updateGroupPrivacySettings(
        groupId: currentState.group!.id,
        adminCpId: currentState.userProfile!.id,
        visibility: visibility,
      );

      // Refresh group membership provider to get updated data
      ref.invalidate(groupMembershipNotifierProvider);

      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        group: updatedGroup,
        error: null,
      ));
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  /// Update group join method setting (admin only)
  Future<void> updateGroupJoinMethod(String joinMethod) async {
    final currentState = await future;
    if (currentState.group == null || !currentState.isUserAdmin) return;

    state = AsyncValue.data(currentState.copyWith(isLoading: true));

    try {
      final privacyService = ref.read(groupPrivacyServiceProvider);
      final updatedGroup = await privacyService.updateGroupPrivacySettings(
        groupId: currentState.group!.id,
        adminCpId: currentState.userProfile!.id,
        joinMethod: joinMethod,
      );

      // Refresh group membership provider to get updated data
      ref.invalidate(groupMembershipNotifierProvider);

      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        group: updatedGroup,
        error: null,
      ));
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  /// Update both visibility and join method (admin only)
  Future<void> updateGroupPrivacySettings({
    String? visibility,
    String? joinMethod,
    String? joinCode,
    DateTime? joinCodeExpiresAt,
    int? joinCodeMaxUses,
  }) async {
    final currentState = await future;
    if (currentState.group == null || !currentState.isUserAdmin) return;

    state = AsyncValue.data(currentState.copyWith(isLoading: true));

    try {
      final privacyService = ref.read(groupPrivacyServiceProvider);
      final updatedGroup = await privacyService.updateGroupPrivacySettings(
        groupId: currentState.group!.id,
        adminCpId: currentState.userProfile!.id,
        visibility: visibility,
        joinMethod: joinMethod,
        joinCode: joinCode,
        joinCodeExpiresAt: joinCodeExpiresAt,
        joinCodeMaxUses: joinCodeMaxUses,
      );

      // Refresh group membership provider to get updated data
      ref.invalidate(groupMembershipNotifierProvider);

      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        group: updatedGroup,
        error: null,
      ));
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  /// Clear any error state
  void clearError() {
    state.whenData((currentState) {
      if (currentState.error != null) {
        state = AsyncValue.data(currentState.copyWith(error: null));
      }
    });
  }
}
