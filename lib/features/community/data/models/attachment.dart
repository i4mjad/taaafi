import 'package:cloud_firestore/cloud_firestore.dart';

/// Base attachment class with common fields
abstract class Attachment {
  final String id;
  final String type;
  final String schemaVersion;
  final DateTime createdAt;
  final String createdByCpId;
  final String status; // "active"|"expired"|"revoked"|"deleted"

  const Attachment({
    required this.id,
    required this.type,
    required this.schemaVersion,
    required this.createdAt,
    required this.createdByCpId,
    required this.status,
  });

  Map<String, dynamic> toFirestore();
  
  Map<String, dynamic> toSummary();
}

/// Image attachment model
class ImageAttachment extends Attachment {
  final String storagePath;
  final String downloadUrl;
  final int width;
  final int height;
  final int sizeBytes;
  final String thumbnailUrl;
  final String contentHash;

  const ImageAttachment({
    required super.id,
    required super.schemaVersion,
    required super.createdAt,
    required super.createdByCpId,
    required super.status,
    required this.storagePath,
    required this.downloadUrl,
    required this.width,
    required this.height,
    required this.sizeBytes,
    required this.thumbnailUrl,
    required this.contentHash,
  }) : super(type: 'image');

  factory ImageAttachment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ImageAttachment(
      id: doc.id,
      schemaVersion: data['schemaVersion'] ?? '1.0',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdByCpId: data['createdByCpId'],
      status: data['status'] ?? 'active',
      storagePath: data['storagePath'],
      downloadUrl: data['downloadUrl'],
      width: data['width'],
      height: data['height'],
      sizeBytes: data['sizeBytes'],
      thumbnailUrl: data['thumbnailUrl'],
      contentHash: data['contentHash'],
    );
  }

  @override
  Map<String, dynamic> toFirestore() => {
        'type': type,
        'schemaVersion': schemaVersion,
        'createdAt': Timestamp.fromDate(createdAt),
        'createdByCpId': createdByCpId,
        'status': status,
        'storagePath': storagePath,
        'downloadUrl': downloadUrl,
        'width': width,
        'height': height,
        'sizeBytes': sizeBytes,
        'thumbnailUrl': thumbnailUrl,
        'contentHash': contentHash,
      };

  @override
  Map<String, dynamic> toSummary() => {
        'id': id,
        'type': type,
        'thumbnailUrl': thumbnailUrl,
      };
}

/// Poll option model
class PollOption {
  final String id;
  final String text;

  const PollOption({
    required this.id,
    required this.text,
  });

  factory PollOption.fromMap(Map<String, dynamic> map) => PollOption(
        id: map['id'],
        text: map['text'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
      };
}

/// Poll attachment model
class PollAttachment extends Attachment {
  // Static fields
  final String question;
  final List<PollOption> options;
  final String selectionMode; // "single"|"multi"
  final DateTime? closesAt;
  final String ownerCpId;

  // Aggregates
  final int totalVotes;
  final List<int> optionCounts;
  final bool isClosed;

  const PollAttachment({
    required super.id,
    required super.schemaVersion,
    required super.createdAt,
    required super.createdByCpId,
    required super.status,
    required this.question,
    required this.options,
    required this.selectionMode,
    this.closesAt,
    required this.ownerCpId,
    required this.totalVotes,
    required this.optionCounts,
    required this.isClosed,
  }) : super(type: 'poll');

  factory PollAttachment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return PollAttachment(
      id: doc.id,
      schemaVersion: data['schemaVersion'] ?? '1.0',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdByCpId: data['createdByCpId'],
      status: data['status'] ?? 'active',
      question: data['question'],
      options: (data['options'] as List<dynamic>)
          .map((option) => PollOption.fromMap(option as Map<String, dynamic>))
          .toList(),
      selectionMode: data['selectionMode'],
      closesAt: (data['closesAt'] as Timestamp?)?.toDate(),
      ownerCpId: data['ownerCpId'],
      totalVotes: data['totalVotes'] ?? 0,
      optionCounts: List<int>.from(data['optionCounts'] ?? []),
      isClosed: data['isClosed'] ?? false,
    );
  }

  @override
  Map<String, dynamic> toFirestore() => {
        'type': type,
        'schemaVersion': schemaVersion,
        'createdAt': Timestamp.fromDate(createdAt),
        'createdByCpId': createdByCpId,
        'status': status,
        'question': question,
        'options': options.map((option) => option.toMap()).toList(),
        'selectionMode': selectionMode,
        'closesAt': closesAt != null ? Timestamp.fromDate(closesAt!) : null,
        'ownerCpId': ownerCpId,
        'totalVotes': totalVotes,
        'optionCounts': optionCounts,
        'isClosed': isClosed,
      };

  @override
  Map<String, dynamic> toSummary() => {
        'id': id,
        'type': type,
        'title': question,
      };
}

/// Group snapshot model for group invites
class GroupSnapshot {
  final String name;
  final String gender;
  final int capacity;
  final int memberCount;
  final String joinMethod;
  final bool plusOnly;

  const GroupSnapshot({
    required this.name,
    required this.gender,
    required this.capacity,
    required this.memberCount,
    required this.joinMethod,
    required this.plusOnly,
  });

  factory GroupSnapshot.fromMap(Map<String, dynamic> map) => GroupSnapshot(
        name: map['name'],
        gender: map['gender'],
        capacity: map['capacity'],
        memberCount: map['memberCount'],
        joinMethod: map['joinMethod'],
        plusOnly: map['plusOnly'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'gender': gender,
        'capacity': capacity,
        'memberCount': memberCount,
        'joinMethod': joinMethod,
        'plusOnly': plusOnly,
      };
}

/// Group invite attachment model
class GroupInviteAttachment extends Attachment {
  final String inviterCpId;
  final String groupId;
  final GroupSnapshot groupSnapshot;
  final String inviteJoinCode;
  final DateTime expiresAt;

  const GroupInviteAttachment({
    required super.id,
    required super.schemaVersion,
    required super.createdAt,
    required super.createdByCpId,
    required super.status,
    required this.inviterCpId,
    required this.groupId,
    required this.groupSnapshot,
    required this.inviteJoinCode,
    required this.expiresAt,
  }) : super(type: 'group_invite');

  factory GroupInviteAttachment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return GroupInviteAttachment(
      id: doc.id,
      schemaVersion: data['schemaVersion'] ?? '1.0',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdByCpId: data['createdByCpId'],
      status: data['status'] ?? 'active',
      inviterCpId: data['inviterCpId'],
      groupId: data['groupId'],
      groupSnapshot: GroupSnapshot.fromMap(data['groupSnapshot'] as Map<String, dynamic>),
      inviteJoinCode: data['inviteJoinCode'],
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
    );
  }

  @override
  Map<String, dynamic> toFirestore() => {
        'type': type,
        'schemaVersion': schemaVersion,
        'createdAt': Timestamp.fromDate(createdAt),
        'createdByCpId': createdByCpId,
        'status': status,
        'inviterCpId': inviterCpId,
        'groupId': groupId,
        'groupSnapshot': groupSnapshot.toMap(),
        'inviteJoinCode': inviteJoinCode,
        'expiresAt': Timestamp.fromDate(expiresAt),
      };

  @override
  Map<String, dynamic> toSummary() => {
        'id': id,
        'type': type,
        'groupName': groupSnapshot.name,
      };
}

/// Poll vote model for subcollection: forumPosts/{postId}/pollVotes/{cpId}
class PollVote {
  final String cpId;
  final List<String> selectedOptionIds;
  final DateTime votedAt;

  const PollVote({
    required this.cpId,
    required this.selectedOptionIds,
    required this.votedAt,
  });

  factory PollVote.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return PollVote(
      cpId: doc.id,
      selectedOptionIds: List<String>.from(data['selectedOptionIds'] ?? []),
      votedAt: (data['votedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'selectedOptionIds': selectedOptionIds,
        'votedAt': Timestamp.fromDate(votedAt),
      };
}
