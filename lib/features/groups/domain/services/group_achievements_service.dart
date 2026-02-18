import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../entities/group_achievement_entity.dart';
import '../entities/group_membership_entity.dart';

/// Service for managing group achievements
/// Sprint 4 - Feature 4.1: Enhanced Member Profiles
class GroupAchievementsService {
  final FirebaseFirestore _firestore;

  const GroupAchievementsService(this._firestore);

  /// Get all achievements for a member in a group
  Future<List<GroupAchievementEntity>> getAchievements({
    required String groupId,
    required String cpId,
  }) async {
    try {
      log('Getting achievements for member $cpId in group $groupId');
      
      // Query by cpId only to avoid composite index requirement
      final snapshot = await _firestore
          .collection('groupAchievements')
          .where('cpId', isEqualTo: cpId)
          .get();

      // Filter by groupId and sort in code
      final achievements = snapshot.docs
          .map((doc) => GroupAchievementEntity.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .where((achievement) => achievement.groupId == groupId)
          .toList();
      
      // Sort by earnedAt descending
      achievements.sort((a, b) => b.earnedAt.compareTo(a.earnedAt));

      log('Found ${achievements.length} achievements for member');
      return achievements;
    } catch (e, stackTrace) {
      log('Error getting achievements: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Check and award achievements for a member
  /// This should be called after significant actions (message sent, etc.)
  Future<List<GroupAchievementEntity>> checkAndAwardAchievements({
    required String groupId,
    required String cpId,
    required GroupMembershipEntity membership,
  }) async {
    try {
      log('Checking achievements for member $cpId in group $groupId');

      final newAchievements = <GroupAchievementEntity>[];
      final existingAchievements = await getAchievements(
        groupId: groupId,
        cpId: cpId,
      );
      final existingTypes = existingAchievements
          .map((a) => a.achievementType)
          .toSet();

      // Check Welcome achievement (earned on join)
      if (!existingTypes.contains(AchievementType.welcome)) {
        final achievement = await _awardAchievement(
          groupId: groupId,
          cpId: cpId,
          type: AchievementType.welcome,
          title: 'welcome-achievement',
          description: 'welcome-desc',
        );
        if (achievement != null) newAchievements.add(achievement);
      }

      // Check First Message achievement
      if (!existingTypes.contains(AchievementType.firstMessage) &&
          membership.messageCount > 0) {
        final achievement = await _awardAchievement(
          groupId: groupId,
          cpId: cpId,
          type: AchievementType.firstMessage,
          title: 'first-message-achievement',
          description: 'first-message-desc',
        );
        if (achievement != null) newAchievements.add(achievement);
      }

      // Check Week Warrior achievement (active for 7 days straight)
      if (!existingTypes.contains(AchievementType.weekWarrior) &&
          membership.lastActiveAt != null) {
        final daysSinceJoin = DateTime.now().difference(membership.joinedAt).inDays;
        if (daysSinceJoin >= 7) {
          final achievement = await _awardAchievement(
            groupId: groupId,
            cpId: cpId,
            type: AchievementType.weekWarrior,
            title: 'week-warrior-achievement',
            description: 'week-warrior-desc',
          );
          if (achievement != null) newAchievements.add(achievement);
        }
      }

      // Check Month Master achievement (active for 30 days)
      if (!existingTypes.contains(AchievementType.monthMaster) &&
          membership.lastActiveAt != null) {
        final daysSinceJoin = DateTime.now().difference(membership.joinedAt).inDays;
        if (daysSinceJoin >= 30) {
          final achievement = await _awardAchievement(
            groupId: groupId,
            cpId: cpId,
            type: AchievementType.monthMaster,
            title: 'month-master-achievement',
            description: 'month-master-desc',
          );
          if (achievement != null) newAchievements.add(achievement);
        }
      }

      return newAchievements;
    } catch (e, stackTrace) {
      log('Error checking and awarding achievements: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Award a specific achievement to a member
  Future<GroupAchievementEntity?> _awardAchievement({
    required String groupId,
    required String cpId,
    required String type,
    required String title,
    required String description,
  }) async {
    try {
      final docRef = _firestore.collection('groupAchievements').doc();
      
      final achievement = GroupAchievementEntity(
        id: docRef.id,
        groupId: groupId,
        cpId: cpId,
        achievementType: type,
        title: title,
        description: description,
        iconUrl: null,
        earnedAt: DateTime.now(),
      );

      await docRef.set(achievement.toJson());
      
      // Also update community profile's groupAchievements array
      await _firestore.collection('communityProfiles').doc(cpId).update({
        'groupAchievements': FieldValue.arrayUnion([achievement.id]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      log('Awarded achievement: $type to member $cpId');
      return achievement;
    } catch (e, stackTrace) {
      log('Error awarding achievement: $e', stackTrace: stackTrace);
      return null;
    }
  }

  /// Get all possible achievement definitions
  List<Map<String, String>> getAllAchievementDefinitions() {
    return [
      {
        'type': AchievementType.welcome,
        'title': 'welcome-achievement',
        'description': 'welcome-desc',
      },
      {
        'type': AchievementType.firstMessage,
        'title': 'first-message-achievement',
        'description': 'first-message-desc',
      },
      {
        'type': AchievementType.weekWarrior,
        'title': 'week-warrior-achievement',
        'description': 'week-warrior-desc',
      },
      {
        'type': AchievementType.monthMaster,
        'title': 'month-master-achievement',
        'description': 'month-master-desc',
      },
      {
        'type': AchievementType.helpful,
        'title': 'helpful-achievement',
        'description': 'helpful-desc',
      },
      {
        'type': AchievementType.topContributor,
        'title': 'top-contributor-achievement',
        'description': 'top-contributor-desc',
      },
    ];
  }

  /// Get achievement progress for a member
  Map<String, dynamic> getAchievementProgress({
    required GroupMembershipEntity membership,
    required List<GroupAchievementEntity> earnedAchievements,
  }) {
    final earnedTypes = earnedAchievements.map((a) => a.achievementType).toSet();
    final daysSinceJoin = DateTime.now().difference(membership.joinedAt).inDays;

    return {
      'welcome': earnedTypes.contains(AchievementType.welcome),
      'firstMessage': earnedTypes.contains(AchievementType.firstMessage),
      'weekWarrior': earnedTypes.contains(AchievementType.weekWarrior),
      'weekWarriorProgress': daysSinceJoin >= 7 ? 1.0 : daysSinceJoin / 7.0,
      'monthMaster': earnedTypes.contains(AchievementType.monthMaster),
      'monthMasterProgress': daysSinceJoin >= 30 ? 1.0 : daysSinceJoin / 30.0,
      'helpful': earnedTypes.contains(AchievementType.helpful),
      'topContributor': earnedTypes.contains(AchievementType.topContributor),
    };
  }
}

