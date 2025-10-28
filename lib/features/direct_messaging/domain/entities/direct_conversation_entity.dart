/// Entity representing a direct conversation between two Community Profiles
class DirectConversationEntity {
  final String id;
  final List<String> participantCpIds; // Always 2 participants
  final String? lastMessage;
  final DateTime lastActivityAt;
  final Map<String, int> unreadBy; // cpId -> unread count
  final List<String> mutedBy; // cpIds who muted this conversation
  final List<String> archivedBy; // cpIds who archived this conversation
  final List<String> deletedFor; // cpIds who soft-deleted this conversation
  final DateTime createdAt;
  final String createdByCpId;

  const DirectConversationEntity({
    required this.id,
    required this.participantCpIds,
    this.lastMessage,
    required this.lastActivityAt,
    required this.unreadBy,
    required this.mutedBy,
    required this.archivedBy,
    required this.deletedFor,
    required this.createdAt,
    required this.createdByCpId,
  });

  /// Get the other participant's CP ID
  String getOtherParticipantCpId(String myCpId) {
    return participantCpIds.firstWhere(
      (cpId) => cpId != myCpId,
      orElse: () => '',
    );
  }

  /// Check if conversation is muted by a specific user
  bool isMutedBy(String cpId) => mutedBy.contains(cpId);

  /// Check if conversation is archived by a specific user
  bool isArchivedBy(String cpId) => archivedBy.contains(cpId);

  /// Check if conversation is deleted for a specific user
  bool isDeletedFor(String cpId) => deletedFor.contains(cpId);

  /// Get unread count for a specific user
  int getUnreadCount(String cpId) => unreadBy[cpId] ?? 0;

  /// Check if user has unread messages
  bool hasUnread(String cpId) => getUnreadCount(cpId) > 0;

  DirectConversationEntity copyWith({
    String? id,
    List<String>? participantCpIds,
    String? lastMessage,
    DateTime? lastActivityAt,
    Map<String, int>? unreadBy,
    List<String>? mutedBy,
    List<String>? archivedBy,
    List<String>? deletedFor,
    DateTime? createdAt,
    String? createdByCpId,
  }) {
    return DirectConversationEntity(
      id: id ?? this.id,
      participantCpIds: participantCpIds ?? this.participantCpIds,
      lastMessage: lastMessage ?? this.lastMessage,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      unreadBy: unreadBy ?? this.unreadBy,
      mutedBy: mutedBy ?? this.mutedBy,
      archivedBy: archivedBy ?? this.archivedBy,
      deletedFor: deletedFor ?? this.deletedFor,
      createdAt: createdAt ?? this.createdAt,
      createdByCpId: createdByCpId ?? this.createdByCpId,
    );
  }
}
