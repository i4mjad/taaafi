import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/features/groups/domain/entities/group_achievement_entity.dart';
import 'package:reboot_app_3/features/groups/domain/services/group_achievements_service.dart';

/// Provider for GroupAchievementsService
final groupAchievementsServiceProvider = Provider<GroupAchievementsService>((ref) {
  return GroupAchievementsService(FirebaseFirestore.instance);
});

/// Provider to get achievements for a specific member in a group
final memberAchievementsProvider = FutureProvider.autoDispose
    .family<List<GroupAchievementEntity>, ({String groupId, String cpId})>(
  (ref, params) async {
    final service = ref.watch(groupAchievementsServiceProvider);
    return await service.getAchievements(
      groupId: params.groupId,
      cpId: params.cpId,
    );
  },
);

