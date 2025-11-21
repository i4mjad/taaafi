import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/referral_verification_entity.dart';

class ChecklistItemModel extends ChecklistItemEntity {
  const ChecklistItemModel({
    required super.completed,
    super.completedAt,
    super.current,
    super.groupId,
    super.activityId,
    super.uniqueUsers,
  });

  factory ChecklistItemModel.fromMap(Map<String, dynamic> map) {
    return ChecklistItemModel(
      completed: map['completed'] as bool? ?? false,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      current: map['current'] as int?,
      groupId: map['groupId'] as String?,
      activityId: map['activityId'] as String?,
      uniqueUsers: map['uniqueUsers'] != null
          ? List<String>.from(map['uniqueUsers'] as List)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'completed': completed,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      if (current != null) 'current': current,
      if (groupId != null) 'groupId': groupId,
      if (activityId != null) 'activityId': activityId,
      if (uniqueUsers != null) 'uniqueUsers': uniqueUsers,
    };
  }

  ChecklistItemEntity toEntity() {
    return ChecklistItemEntity(
      completed: completed,
      completedAt: completedAt,
      current: current,
      groupId: groupId,
      activityId: activityId,
      uniqueUsers: uniqueUsers,
    );
  }
}

class ReferralVerificationModel extends ReferralVerificationEntity {
  const ReferralVerificationModel({
    required super.userId,
    required super.referrerId,
    required super.referralCode,
    required super.signupDate,
    required super.currentTier,
    required super.accountAge7Days,
    required super.forumPosts3,
    required super.interactions5,
    required super.groupJoined,
    required super.groupMessages3,
    required super.activityStarted,
    required super.verificationStatus,
    super.verifiedAt,
    super.fraudScore,
    super.fraudFlags,
    super.isBlocked,
    super.blockedReason,
    super.blockedAt,
    super.rewardAwarded,
    super.rewardAwardedAt,
    required super.lastCheckedAt,
    required super.updatedAt,
  });

  /// Create from Firestore document
  factory ReferralVerificationModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final checklistData = data['checklist'] as Map<String, dynamic>;

    return ReferralVerificationModel(
      userId: doc.id,
      referrerId: data['referrerId'] as String,
      referralCode: data['referralCode'] as String,
      signupDate: (data['signupDate'] as Timestamp).toDate(),
      currentTier: data['currentTier'] as String? ?? 'none',
      accountAge7Days: ChecklistItemModel.fromMap(
          checklistData['accountAge7Days'] as Map<String, dynamic>),
      forumPosts3: ChecklistItemModel.fromMap(
          checklistData['forumPosts3'] as Map<String, dynamic>),
      interactions5: ChecklistItemModel.fromMap(
          checklistData['interactions5'] as Map<String, dynamic>),
      groupJoined: ChecklistItemModel.fromMap(
          checklistData['groupJoined'] as Map<String, dynamic>),
      groupMessages3: ChecklistItemModel.fromMap(
          checklistData['groupMessages3'] as Map<String, dynamic>),
      activityStarted: ChecklistItemModel.fromMap(
          checklistData['activityStarted'] as Map<String, dynamic>),
      verificationStatus: data['verificationStatus'] as String? ?? 'pending',
      verifiedAt: data['verifiedAt'] != null
          ? (data['verifiedAt'] as Timestamp).toDate()
          : null,
      fraudScore: data['fraudScore'] as int? ?? 0,
      fraudFlags: data['fraudFlags'] != null
          ? List<String>.from(data['fraudFlags'] as List)
          : [],
      isBlocked: data['isBlocked'] as bool? ?? false,
      blockedReason: data['blockedReason'] as String?,
      blockedAt: data['blockedAt'] != null
          ? (data['blockedAt'] as Timestamp).toDate()
          : null,
      rewardAwarded: data['rewardAwarded'] as bool? ?? false,
      rewardAwardedAt: data['rewardAwardedAt'] != null
          ? (data['rewardAwardedAt'] as Timestamp).toDate()
          : null,
      lastCheckedAt: (data['lastCheckedAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'referrerId': referrerId,
      'referralCode': referralCode,
      'signupDate': Timestamp.fromDate(signupDate),
      'currentTier': currentTier,
      'checklist': {
        'accountAge7Days': _checklistItemToMap(accountAge7Days),
        'forumPosts3': _checklistItemToMap(forumPosts3),
        'interactions5': _checklistItemToMap(interactions5),
        'groupJoined': _checklistItemToMap(groupJoined),
        'groupMessages3': _checklistItemToMap(groupMessages3),
        'activityStarted': _checklistItemToMap(activityStarted),
      },
      'verificationStatus': verificationStatus,
      'verifiedAt':
          verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'fraudScore': fraudScore,
      'fraudFlags': fraudFlags,
      'isBlocked': isBlocked,
      'blockedReason': blockedReason,
      'blockedAt': blockedAt != null ? Timestamp.fromDate(blockedAt!) : null,
      'rewardAwarded': rewardAwarded,
      'rewardAwardedAt':
          rewardAwardedAt != null ? Timestamp.fromDate(rewardAwardedAt!) : null,
      'lastCheckedAt': Timestamp.fromDate(lastCheckedAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Helper method to convert checklist item to map
  Map<String, dynamic> _checklistItemToMap(ChecklistItemEntity entity) {
    return {
      'completed': entity.completed,
      'completedAt': entity.completedAt != null
          ? Timestamp.fromDate(entity.completedAt!)
          : null,
      if (entity.current != null) 'current': entity.current,
      if (entity.groupId != null) 'groupId': entity.groupId,
      if (entity.activityId != null) 'activityId': entity.activityId,
      if (entity.uniqueUsers != null) 'uniqueUsers': entity.uniqueUsers,
    };
  }

  /// Convert to domain entity
  ReferralVerificationEntity toEntity() {
    return ReferralVerificationEntity(
      userId: userId,
      referrerId: referrerId,
      referralCode: referralCode,
      signupDate: signupDate,
      currentTier: currentTier,
      accountAge7Days: accountAge7Days,
      forumPosts3: forumPosts3,
      interactions5: interactions5,
      groupJoined: groupJoined,
      groupMessages3: groupMessages3,
      activityStarted: activityStarted,
      verificationStatus: verificationStatus,
      verifiedAt: verifiedAt,
      fraudScore: fraudScore,
      fraudFlags: fraudFlags,
      isBlocked: isBlocked,
      blockedReason: blockedReason,
      blockedAt: blockedAt,
      rewardAwarded: rewardAwarded,
      rewardAwardedAt: rewardAwardedAt,
      lastCheckedAt: lastCheckedAt,
      updatedAt: updatedAt,
    );
  }
}

