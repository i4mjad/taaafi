import 'dart:developer';
import '../entities/group_membership_entity.dart';
import '../repositories/groups_repository.dart';

/// Service for managing member activity tracking and engagement scoring
/// Sprint 2 - Feature 2.1: Member Activity Insights
class GroupActivityService {
  final GroupsRepository _repository;

  const GroupActivityService(this._repository);

  /// Update member activity timestamp (called on any group activity)
  /// This should be called when:
  /// - Member sends a message
  /// - Member reacts to a message
  /// - Member performs any group action
  Future<void> updateMemberActivity({
    required String groupId,
    required String cpId,
  }) async {
    try {
      log('Updating activity for member $cpId in group $groupId');
      await _repository.updateMemberActivity(groupId: groupId, cpId: cpId);
    } catch (e, stackTrace) {
      log('Error updating member activity: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Calculate engagement score for a member
  /// Formula:
  /// - Base: messageCount × 2
  /// - Bonus: +10 for active in last 24 hours
  /// - Bonus: +5 for active in last 7 days
  /// - Penalty: -5 for inactive > 7 days
  int calculateEngagementScore(GroupMembershipEntity member) {
    try {
      int score = member.messageCount * 2;

      if (member.lastActiveAt != null) {
        final now = DateTime.now();
        final hoursSinceActive = now.difference(member.lastActiveAt!).inHours;
        final daysSinceActive = now.difference(member.lastActiveAt!).inDays;

        // Active in last 24 hours
        if (hoursSinceActive < 24) {
          score += 10;
        }
        // Active in last 7 days
        else if (daysSinceActive < 7) {
          score += 5;
        }
        // Inactive for more than 7 days
        else if (daysSinceActive >= 7) {
          score -= 5;
        }
      } else {
        // Never been active
        score -= 5;
      }

      // Ensure score is never negative
      return score.clamp(0, 999);
    } catch (e, stackTrace) {
      log('Error calculating engagement score: $e', stackTrace: stackTrace);
      return 0;
    }
  }

  /// Get inactive members (not active for X days)
  Future<List<GroupMembershipEntity>> getInactiveMembers({
    required String groupId,
    int inactiveDays = 7,
  }) async {
    try {
      log('Getting inactive members for group $groupId (${inactiveDays} days)');
      return await _repository.getInactiveMembers(groupId, inactiveDays);
    } catch (e, stackTrace) {
      log('Error getting inactive members: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get members with activity data
  Future<List<GroupMembershipEntity>> getMembersWithActivity({
    required String groupId,
  }) async {
    try {
      log('Getting members with activity for group $groupId');
      return await _repository.getMembersWithActivity(groupId);
    } catch (e, stackTrace) {
      log('Error getting members with activity: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get activity statistics for a group
  Future<GroupActivityStats> getMemberActivityStats({
    required String groupId,
  }) async {
    try {
      log('Getting activity stats for group $groupId');
      
      final members = await _repository.getMembersWithActivity(groupId);
      final inactiveMembers = await getInactiveMembers(groupId: groupId);
      
      // Calculate statistics
      final totalMembers = members.length;
      final activeMembers = totalMembers - inactiveMembers.length;
      
      // Calculate average engagement
      final totalEngagement = members.fold<int>(
        0,
        (sum, member) => sum + member.engagementScore,
      );
      final averageEngagement = totalMembers > 0 
          ? (totalEngagement / totalMembers).round()
          : 0;
      
      // Find most active member
      GroupMembershipEntity? mostActiveMember;
      if (members.isNotEmpty) {
        mostActiveMember = members.reduce((curr, next) =>
            curr.engagementScore > next.engagementScore ? curr : next);
      }
      
      return GroupActivityStats(
        totalMembers: totalMembers,
        activeMembers: activeMembers,
        inactiveMembers: inactiveMembers.length,
        averageEngagement: averageEngagement,
        mostActiveMemberCpId: mostActiveMember?.cpId,
        mostActiveMemberScore: mostActiveMember?.engagementScore ?? 0,
      );
    } catch (e, stackTrace) {
      log('Error getting member activity stats: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Sort members by activity (most recent first)
  List<GroupMembershipEntity> sortMembersByActivity(
    List<GroupMembershipEntity> members,
  ) {
    final sortedMembers = List<GroupMembershipEntity>.from(members);
    sortedMembers.sort((a, b) {
      // Members with no activity go to the end
      if (a.lastActiveAt == null && b.lastActiveAt == null) return 0;
      if (a.lastActiveAt == null) return 1;
      if (b.lastActiveAt == null) return -1;
      
      // Sort by most recent activity first
      return b.lastActiveAt!.compareTo(a.lastActiveAt!);
    });
    return sortedMembers;
  }

  /// Sort members by engagement score (highest first)
  List<GroupMembershipEntity> sortMembersByEngagement(
    List<GroupMembershipEntity> members,
  ) {
    final sortedMembers = List<GroupMembershipEntity>.from(members);
    sortedMembers.sort((a, b) => b.engagementScore.compareTo(a.engagementScore));
    return sortedMembers;
  }

  /// Filter members by engagement level
  List<GroupMembershipEntity> filterMembersByEngagementLevel(
    List<GroupMembershipEntity> members,
    String level, // 'high', 'medium', 'low'
  ) {
    return members.where((member) => member.engagementLevel == level).toList();
  }
}

/// Statistics about group member activity
class GroupActivityStats {
  final int totalMembers;
  final int activeMembers;
  final int inactiveMembers;
  final int averageEngagement;
  final String? mostActiveMemberCpId;
  final int mostActiveMemberScore;

  const GroupActivityStats({
    required this.totalMembers,
    required this.activeMembers,
    required this.inactiveMembers,
    required this.averageEngagement,
    this.mostActiveMemberCpId,
    required this.mostActiveMemberScore,
  });
}

