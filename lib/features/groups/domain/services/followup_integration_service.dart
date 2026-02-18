import 'dart:developer' as developer;
import 'package:reboot_app_3/features/shared/models/follow_up.dart';
import 'package:reboot_app_3/features/vault/data/follow_up/follow_up_repository.dart';
import '../entities/group_update_entity.dart';

/// Service for integrating followup system with group updates
/// 
/// Generates update content based on followup entries
class FollowupIntegrationService {
  final FollowUpRepository _followupRepository;

  FollowupIntegrationService(this._followupRepository);

  void log(String message, {StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'FollowupIntegrationService',
      stackTrace: stackTrace,
    );
  }

  /// Get user's recent followups (last 7 days)
  Future<List<FollowUpModel>> getRecentFollowups(String cpId) async {
    try {
      log('Getting recent followups for user: $cpId');

      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      
      // Get all followups
      final allFollowups = await _followupRepository.readAllFollowUps();
      
      // Filter to last 7 days
      final recentFollowups = allFollowups
          .where((followup) => followup.time.isAfter(sevenDaysAgo))
          .toList();
      
      // Sort by time (newest first)
      recentFollowups.sort((a, b) => b.time.compareTo(a.time));
      
      log('Found ${recentFollowups.length} recent followups');
      return recentFollowups;
    } catch (e, stackTrace) {
      log('Error getting recent followups: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Check if a followup has already been shared in a group
  /// Note: This would require storing the linkedFollowupId in updates
  /// For now, we'll return false (always allow sharing)
  Future<bool> isFollowupShared(String followupId, String groupId) async {
    // TODO: Implement proper check by querying group_updates
    // where linkedFollowupId == followupId and groupId == groupId
    return false;
  }

  /// Generate update content based on followup entry
  /// Creates contextual, supportive content based on the followup type
  UpdateContent generateUpdateContentFromFollowup(FollowUpModel followup) {
    log('Generating update content for followup type: ${followup.type.name}');

    switch (followup.type) {
      case FollowUpType.relapse:
        return UpdateContent(
          type: UpdateType.struggle,
          title: 'update-from-followup',
          content: 'relapse-update-content',
          isPreset: true,
        );

      case FollowUpType.pornOnly:
        return UpdateContent(
          type: UpdateType.struggle,
          title: 'update-from-followup',
          content: 'porn-only-update-content',
          isPreset: true,
        );

      case FollowUpType.mastOnly:
        return UpdateContent(
          type: UpdateType.struggle,
          title: 'update-from-followup',
          content: 'mast-only-update-content',
          isPreset: true,
        );

      case FollowUpType.slipUp:
        return UpdateContent(
          type: UpdateType.struggle,
          title: 'update-from-followup',
          content: 'slip-up-update-content',
          isPreset: true,
        );

      case FollowUpType.none:
        // This should not be used, but fallback to general
        return UpdateContent(
          type: UpdateType.general,
          title: '',
          content: '',
          isPreset: false,
        );
    }
  }

  /// Get followup type display name (for UI)
  String getFollowupTypeDisplayName(FollowUpType type) {
    switch (type) {
      case FollowUpType.relapse:
        return 'followup-type-relapse';
      case FollowUpType.pornOnly:
        return 'followup-type-porn-only';
      case FollowUpType.mastOnly:
        return 'followup-type-mast-only';
      case FollowUpType.slipUp:
        return 'followup-type-slip-up';
      case FollowUpType.none:
        return 'followup-type-none';
    }
  }

  /// Check if followup type can be shared (exclude 'none')
  bool canShareFollowupType(FollowUpType type) {
    return type != FollowUpType.none;
  }

  /// Format followup date for display
  String formatFollowupDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Generated update content from followup
class UpdateContent {
  final UpdateType type;
  final String title; // Localization key
  final String content; // Localization key
  final bool isPreset; // Whether this uses preset localization

  const UpdateContent({
    required this.type,
    required this.title,
    required this.content,
    required this.isPreset,
  });
}

