import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:reboot_app_3/features/groups/application/groups_providers.dart';
import 'package:reboot_app_3/features/groups/domain/entities/group_membership_entity.dart';

part 'group_members_provider.g.dart';

/// Provider for group members list
@riverpod
Future<List<GroupMembershipEntity>> groupMembers(
    GroupMembersRef ref, String groupId) async {
  try {
    final repository = ref.read(groupsRepositoryProvider);
    return await repository.getGroupMembers(groupId);
  } catch (error, stackTrace) {
    print('Error in groupMembersProvider: $error');
    print('StackTrace: $stackTrace');
    rethrow;
  }
}
