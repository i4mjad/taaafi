import 'dart:developer';
import '../entities/group_membership_entity.dart';
import '../repositories/groups_repository.dart';

/// Service for exporting group member data
/// Sprint 2 - Feature 2.2: Bulk Member Management
class GroupExportService {
  final GroupsRepository _repository;

  const GroupExportService(this._repository);

  /// Generate CSV export of group members
  /// Returns a CSV string with member data
  Future<String> exportMembersAsCSV({
    required String groupId,
    List<String>? selectedCpIds, // If null, export all members
    bool includeInactive = false,
  }) async {
    try {
      log('Exporting members for group $groupId');

      // Fetch members with activity data
      final allMembers = await _repository.getMembersWithActivity(groupId);

      // Filter members based on selection
      List<GroupMembershipEntity> membersToExport = allMembers;

      if (selectedCpIds != null && selectedCpIds.isNotEmpty) {
        membersToExport =
            allMembers.where((m) => selectedCpIds.contains(m.cpId)).toList();
      }

      // Filter out inactive members if requested
      if (!includeInactive) {
        membersToExport =
            membersToExport.where((m) => !m.isInactive(days: 7)).toList();
      }

      // Generate CSV
      final csvBuffer = StringBuffer();

      // CSV Header
      csvBuffer.writeln(
          'Member ID,Role,Status,Joined Date,Last Active,Messages,Engagement Score,Engagement Level,Points');

      // CSV Rows
      for (final member in membersToExport) {
        final lastActiveStr = member.lastActiveAt != null
            ? member.lastActiveAt!.toIso8601String()
            : 'Never';

        csvBuffer.writeln([
          member.cpId,
          member.role,
          member.isActive ? 'Active' : 'Inactive',
          member.joinedAt.toIso8601String(),
          lastActiveStr,
          member.messageCount,
          member.engagementScore,
          member.engagementLevel,
          member.pointsTotal,
        ].join(','));
      }

      log('Exported ${membersToExport.length} members to CSV');
      return csvBuffer.toString();
    } catch (e, stackTrace) {
      log('Error exporting members as CSV: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get a shareable summary string for export
  String getExportSummary({
    required int totalMembers,
    required int activeMembers,
    required int inactiveMembers,
    required double averageEngagement,
  }) {
    return '''
Group Members Export Summary
----------------------------
Total Members: $totalMembers
Active Members: $activeMembers
Inactive Members: $inactiveMembers
Average Engagement: ${averageEngagement.toStringAsFixed(1)}
''';
  }
}

