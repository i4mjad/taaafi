import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:reboot_app_3/features/account/data/user_profile_notifier.dart';
import 'package:reboot_app_3/features/groups/application/groups_providers.dart';
import 'package:reboot_app_3/features/groups/domain/entities/group_entity.dart';

part 'filtered_public_groups_provider.g.dart';

/// State for paginated group exploration
class PaginatedGroupsState {
  final List<GroupEntity> groups;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
  final bool isLoadingMore;

  const PaginatedGroupsState({
    this.groups = const [],
    this.lastDocument,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  PaginatedGroupsState copyWith({
    List<GroupEntity>? groups,
    DocumentSnapshot? lastDocument,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return PaginatedGroupsState(
      groups: groups ?? this.groups,
      lastDocument: lastDocument ?? this.lastDocument,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Paginated provider for public groups exploration
@riverpod
class PaginatedPublicGroups extends _$PaginatedPublicGroups {
  static const _pageSize = 20;

  @override
  FutureOr<PaginatedGroupsState> build() async {
    final userProfile = await ref.watch(userProfileNotifierProvider.future);
    if (userProfile == null) {
      return const PaginatedGroupsState(groups: [], hasMore: false);
    }

    final groupsService = ref.watch(groupsServiceProvider);
    final result = await groupsService.getPublicGroupsPaginated(
      limit: _pageSize,
      userGender: userProfile.gender.toLowerCase(),
    );

    return PaginatedGroupsState(
      groups: result.groups.map((g) => g.toEntity()).toList(),
      lastDocument: result.lastDocument,
      hasMore: result.hasMore,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final userProfile =
          await ref.read(userProfileNotifierProvider.future);
      if (userProfile == null) return;

      final groupsService = ref.read(groupsServiceProvider);
      final result = await groupsService.getPublicGroupsPaginated(
        limit: _pageSize,
        userGender: userProfile.gender.toLowerCase(),
        startAfterDocument: current.lastDocument,
      );

      final newGroups = result.groups.map((g) => g.toEntity()).toList();
      state = AsyncData(PaginatedGroupsState(
        groups: [...current.groups, ...newGroups],
        lastDocument: result.lastDocument,
        hasMore: result.hasMore,
      ));
    } catch (e) {
      // Keep existing data but stop loading indicator
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  void refresh() {
    ref.invalidateSelf();
  }
}
