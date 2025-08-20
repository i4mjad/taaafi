import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:reboot_app_3/features/shared/models/group.dart';

part 'group_membership_provider.g.dart';

/// Represents a user's current group membership status
class GroupMembership {
  final Group group;
  final DateTime joinedAt;
  final String memberRole; // 'member' or 'admin'
  final int totalPoints;

  const GroupMembership({
    required this.group,
    required this.joinedAt,
    this.memberRole = 'member',
    this.totalPoints = 0,
  });

  GroupMembership copyWith({
    Group? group,
    DateTime? joinedAt,
    String? memberRole,
    int? totalPoints,
  }) {
    return GroupMembership(
      group: group ?? this.group,
      joinedAt: joinedAt ?? this.joinedAt,
      memberRole: memberRole ?? this.memberRole,
      totalPoints: totalPoints ?? this.totalPoints,
    );
  }
}

/// Notifier for managing group membership state
@riverpod
class GroupMembershipNotifier extends _$GroupMembershipNotifier {
  @override
  GroupMembership? build() {
    // Initially, user is not in any group
    return null;
  }

  /// Simulates joining a random group
  void joinRandomGroup() {
    final demoGroup = Group(
      id: 'demo_group_1',
      name: 'دعم التعافي اليومي',
      description: 'مجموعة دعم للأشخاص الذين يسعون للتعافي من الإدمان',
      memberCount: 3,
      capacity: 6,
      gender: 'male', // This should match user's gender in real implementation
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now(),
    );

    state = GroupMembership(
      group: demoGroup,
      joinedAt: DateTime.now(),
      memberRole: 'member',
      totalPoints: 0,
    );
  }

  /// Simulates joining a group with a specific code
  void joinGroupWithCode(String code) {
    final demoGroup = Group(
      id: 'demo_group_code_$code',
      name: 'مجموعة $code',
      description: 'مجموعة دعم خاصة',
      memberCount: 5,
      capacity: 8,
      gender: 'male', // This should match user's gender in real implementation
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    );

    state = GroupMembership(
      group: demoGroup,
      joinedAt: DateTime.now(),
      memberRole: 'member',
      totalPoints: 0,
    );
  }

  /// Simulates leaving the current group
  void leaveGroup() {
    state = null;
  }

  /// Updates the user's points in the group
  void updatePoints(int newPoints) {
    if (state != null) {
      state = state!.copyWith(totalPoints: newPoints);
    }
  }
}
