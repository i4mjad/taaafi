import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/challenge_entity.dart';
import '../../domain/entities/challenge_participation_entity.dart';
import '../../domain/entities/challenge_stats_entity.dart';
import '../../domain/entities/challenge_update_entity.dart';
import '../../domain/repositories/challenges_repository.dart';
import '../models/challenge_model.dart';
import '../models/challenge_participation_model.dart';
import '../models/challenge_update_model.dart';

class ChallengesRepositoryImpl implements ChallengesRepository {
  final FirebaseFirestore _firestore;

  const ChallengesRepositoryImpl(this._firestore);

  // Collection references
  CollectionReference<Map<String, dynamic>> get _challengesCollection =>
      _firestore.collection('group_challenges');

  CollectionReference<Map<String, dynamic>> get _participationsCollection =>
      _firestore.collection('challenge_participants');

  CollectionReference<Map<String, dynamic>> get _updatesCollection =>
      _firestore.collection('challenge_updates');

  // ============================================
  // Challenge CRUD Operations
  // ============================================

  @override
  Future<String> createChallenge(ChallengeEntity challenge) async {
    try {
      final model = ChallengeModel.fromEntity(challenge);
      final docRef = await _challengesCollection.add(model.toFirestore());
      return docRef.id;
    } catch (e, stackTrace) {
      log('Error creating challenge: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<ChallengeEntity?> getChallengeById(String challengeId) async {
    try {
      final doc = await _challengesCollection.doc(challengeId).get();
      if (!doc.exists) return null;
      return ChallengeModel.fromFirestore(doc);
    } catch (e, stackTrace) {
      log('Error getting challenge by ID: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updateChallenge(ChallengeEntity challenge) async {
    try {
      final model = ChallengeModel.fromEntity(challenge);
      await _challengesCollection
          .doc(challenge.id)
          .update(model.toFirestore());
    } catch (e, stackTrace) {
      log('Error updating challenge: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteChallenge(String challengeId) async {
    try {
      await _challengesCollection.doc(challengeId).delete();
    } catch (e, stackTrace) {
      log('Error deleting challenge: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  // ============================================
  // Challenge Queries
  // ============================================

  @override
  Future<List<ChallengeEntity>> getGroupChallenges(String groupId) async {
    try {
      final querySnapshot = await _challengesCollection
          .where('groupId', isEqualTo: groupId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ChallengeModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      log('Error getting group challenges: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<ChallengeEntity>> getActiveChallenges(String groupId) async {
    try {
      final querySnapshot = await _challengesCollection
          .where('groupId', isEqualTo: groupId)
          .where('status', isEqualTo: 'active')
          .orderBy('startDate', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => ChallengeModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      log('Error getting active challenges: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<ChallengeEntity>> getCompletedChallenges(String groupId) async {
    try {
      final querySnapshot = await _challengesCollection
          .where('groupId', isEqualTo: groupId)
          .where('status', isEqualTo: 'completed')
          .orderBy('endDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ChallengeModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      log('Error getting completed challenges: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<ChallengeEntity>> getUpcomingChallenges(String groupId) async {
    try {
      final querySnapshot = await _challengesCollection
          .where('groupId', isEqualTo: groupId)
          .where('status', isEqualTo: 'draft')
          .orderBy('startDate', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => ChallengeModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      log('Error getting upcoming challenges: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  // ============================================
  // Participation Operations
  // ============================================

  @override
  Future<String> joinChallenge({
    required String challengeId,
    required String cpId,
    required String groupId,
    required int goalValue,
  }) async {
    try {
      // Use transaction to ensure atomic operations
      return await _firestore.runTransaction((transaction) async {
        // Create participation document
        final participationId = '${challengeId}_$cpId';
        final participationRef =
            _participationsCollection.doc(participationId);

        final now = DateTime.now();
        final participation = ChallengeParticipationModel(
          id: participationId,
          challengeId: challengeId,
          cpId: cpId,
          groupId: groupId,
          goalValue: goalValue,
          joinedAt: now,
          lastUpdateAt: now,
        );

        transaction.set(participationRef, participation.toFirestore());

        // Update challenge: increment participant count and add to participants array
        final challengeRef = _challengesCollection.doc(challengeId);
        transaction.update(challengeRef, {
          'participantCount': FieldValue.increment(1),
          'participants': FieldValue.arrayUnion([cpId]),
        });

        return participationId;
      });
    } catch (e, stackTrace) {
      log('Error joining challenge: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> leaveChallenge({
    required String challengeId,
    required String cpId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final participationId = '${challengeId}_$cpId';
        final participationRef =
            _participationsCollection.doc(participationId);

        transaction.update(participationRef, {
          'status': 'quit',
        });

        // Update challenge: decrement participant count and remove from participants array
        final challengeRef = _challengesCollection.doc(challengeId);
        transaction.update(challengeRef, {
          'participantCount': FieldValue.increment(-1),
          'participants': FieldValue.arrayRemove([cpId]),
        });
      });
    } catch (e, stackTrace) {
      log('Error leaving challenge: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<ChallengeParticipationEntity?> getParticipation({
    required String challengeId,
    required String cpId,
  }) async {
    try {
      final participationId = '${challengeId}_$cpId';
      final doc = await _participationsCollection.doc(participationId).get();

      if (!doc.exists) return null;

      return ChallengeParticipationModel.fromFirestore(doc);
    } catch (e, stackTrace) {
      log('Error getting participation: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<ChallengeParticipationEntity>> getChallengeParticipants(
    String challengeId,
  ) async {
    try {
      final querySnapshot = await _participationsCollection
          .where('challengeId', isEqualTo: challengeId)
          .get();

      return querySnapshot.docs
          .map((doc) => ChallengeParticipationModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      log('Error getting challenge participants: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<ChallengeParticipationEntity>> getActiveParticipants(
    String challengeId,
  ) async {
    try {
      final querySnapshot = await _participationsCollection
          .where('challengeId', isEqualTo: challengeId)
          .where('status', isEqualTo: 'active')
          .get();

      return querySnapshot.docs
          .map((doc) => ChallengeParticipationModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      log('Error getting active participants: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<ChallengeParticipationEntity>> getUserActiveChallenges(
    String cpId,
  ) async {
    try {
      final querySnapshot = await _participationsCollection
          .where('cpId', isEqualTo: cpId)
          .where('status', isEqualTo: 'active')
          .orderBy('joinedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ChallengeParticipationModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      log('Error getting user active challenges: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  // ============================================
  // Progress Operations
  // ============================================

  @override
  Future<void> updateProgress({
    required String challengeId,
    required String cpId,
    required int newCurrentValue,
    required int newProgress,
  }) async {
    try {
      final participationId = '${challengeId}_$cpId';
      await _participationsCollection.doc(participationId).update({
        'currentValue': newCurrentValue,
        'progress': newProgress,
        'lastUpdateAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e, stackTrace) {
      log('Error updating progress: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> recordDailyActivity({
    required String challengeId,
    required String cpId,
  }) async {
    try {
      final participationId = '${challengeId}_$cpId';
      final now = DateTime.now();

      await _participationsCollection.doc(participationId).update({
        'dailyLog': FieldValue.arrayUnion([Timestamp.fromDate(now)]),
        'lastUpdateAt': Timestamp.fromDate(now),
      });
    } catch (e, stackTrace) {
      log('Error recording daily activity: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> completeParticipation({
    required String challengeId,
    required String cpId,
  }) async {
    try {
      final participationId = '${challengeId}_$cpId';
      await _participationsCollection.doc(participationId).update({
        'status': 'completed',
        'completedAt': Timestamp.fromDate(DateTime.now()),
        'progress': 100,
      });
    } catch (e, stackTrace) {
      log('Error completing participation: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  // ============================================
  // Leaderboard & Rankings
  // ============================================

  @override
  Future<List<ChallengeParticipationEntity>> getLeaderboard({
    required String challengeId,
    int limit = 10,
  }) async {
    try {
      final querySnapshot = await _participationsCollection
          .where('challengeId', isEqualTo: challengeId)
          .where('status', isEqualTo: 'active')
          .orderBy('progress', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => ChallengeParticipationModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      log('Error getting leaderboard: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updateRankings(String challengeId) async {
    try {
      // Get all active participants sorted by progress
      final participants = await getActiveParticipants(challengeId);
      participants.sort((a, b) => b.progress.compareTo(a.progress));

      // Update rank for each participant
      final batch = _firestore.batch();
      for (int i = 0; i < participants.length; i++) {
        final participationRef =
            _participationsCollection.doc(participants[i].id);
        batch.update(participationRef, {'rank': i + 1});
      }

      await batch.commit();
    } catch (e, stackTrace) {
      log('Error updating rankings: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  // ============================================
  // Statistics
  // ============================================

  @override
  Future<ChallengeStatsEntity> getChallengeStats(String challengeId) async {
    try {
      final participants = await getChallengeParticipants(challengeId);
      final activeParticipants = participants
          .where((p) => p.status == ParticipationStatus.active)
          .toList();
      final completedParticipants = participants
          .where((p) => p.status == ParticipationStatus.completed)
          .toList();

      final totalCount = participants.length;
      final activeCount = activeParticipants.length;
      final completedCount = completedParticipants.length;

      // Calculate completion rate
      final completionRate =
          totalCount > 0 ? (completedCount / totalCount) * 100 : 0.0;

      // Calculate average progress
      double averageProgress = 0.0;
      if (activeParticipants.isNotEmpty) {
        final totalProgress =
            activeParticipants.fold<int>(0, (sum, p) => sum + p.progress);
        averageProgress = totalProgress / activeParticipants.length;
      }

      // Get top 5 participants
      final topParticipants = await getLeaderboard(
        challengeId: challengeId,
        limit: 5,
      );

      return ChallengeStatsEntity(
        challengeId: challengeId,
        participantCount: totalCount,
        activeParticipantCount: activeCount,
        completedParticipantCount: completedCount,
        completionRate: completionRate,
        averageProgress: averageProgress,
        topParticipants: topParticipants,
        lastCalculatedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      log('Error getting challenge stats: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> getParticipantCount(String challengeId) async {
    try {
      final challenge = await getChallengeById(challengeId);
      return challenge?.participantCount ?? 0;
    } catch (e, stackTrace) {
      log('Error getting participant count: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<double> getAverageProgress(String challengeId) async {
    try {
      final participants = await getActiveParticipants(challengeId);
      if (participants.isEmpty) return 0.0;

      final totalProgress =
          participants.fold<int>(0, (sum, p) => sum + p.progress);
      return totalProgress / participants.length;
    } catch (e, stackTrace) {
      log('Error getting average progress: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  // ============================================
  // Challenge Updates/Feed
  // ============================================

  @override
  Future<String> createChallengeUpdate(ChallengeUpdateEntity update) async {
    try {
      final model = ChallengeUpdateModel.fromEntity(update);
      final docRef = await _updatesCollection.add(model.toFirestore());
      return docRef.id;
    } catch (e, stackTrace) {
      log('Error creating challenge update: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<ChallengeUpdateEntity>> getChallengeUpdates({
    required String challengeId,
    int limit = 20,
  }) async {
    try {
      final querySnapshot = await _updatesCollection
          .where('challengeId', isEqualTo: challengeId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => ChallengeUpdateModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      log('Error getting challenge updates: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  // ============================================
  // Challenge Management
  // ============================================

  @override
  Future<void> incrementParticipantCount(String challengeId) async {
    try {
      await _challengesCollection.doc(challengeId).update({
        'participantCount': FieldValue.increment(1),
      });
    } catch (e, stackTrace) {
      log('Error incrementing participant count: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> decrementParticipantCount(String challengeId) async {
    try {
      await _challengesCollection.doc(challengeId).update({
        'participantCount': FieldValue.increment(-1),
      });
    } catch (e, stackTrace) {
      log('Error decrementing participant count: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> addParticipantToChallenge({
    required String challengeId,
    required String cpId,
  }) async {
    try {
      await _challengesCollection.doc(challengeId).update({
        'participants': FieldValue.arrayUnion([cpId]),
      });
    } catch (e, stackTrace) {
      log('Error adding participant to challenge: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> removeParticipantFromChallenge({
    required String challengeId,
    required String cpId,
  }) async {
    try {
      await _challengesCollection.doc(challengeId).update({
        'participants': FieldValue.arrayRemove([cpId]),
      });
    } catch (e, stackTrace) {
      log('Error removing participant from challenge: $e',
          stackTrace: stackTrace);
      rethrow;
    }
  }
}

