class GroupInvitationEntity {
  final String id;
  final String groupId;
  final String groupName;
  final String inviterName;
  final DateTime invitedAt;
  final String? groupDescription;
  final int memberCount;
  final String groupType; // 'public' or 'private'

  const GroupInvitationEntity({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.inviterName,
    required this.invitedAt,
    this.groupDescription,
    required this.memberCount,
    required this.groupType,
  });

  factory GroupInvitationEntity.fromJson(Map<String, dynamic> json) {
    return GroupInvitationEntity(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      groupName: json['groupName'] as String,
      inviterName: json['inviterName'] as String,
      invitedAt: DateTime.parse(json['invitedAt'] as String),
      groupDescription: json['groupDescription'] as String?,
      memberCount: json['memberCount'] as int,
      groupType: json['groupType'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'groupName': groupName,
      'inviterName': inviterName,
      'invitedAt': invitedAt.toIso8601String(),
      'groupDescription': groupDescription,
      'memberCount': memberCount,
      'groupType': groupType,
    };
  }
}
