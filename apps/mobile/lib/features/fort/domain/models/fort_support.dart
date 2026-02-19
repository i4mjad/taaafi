/// Support event sent between users in groups (Phase 4).
class FortSupport {
  final String id;
  final String senderId;
  final String receiverId;
  final FortSupportType type;
  final DateTime createdAt;
  final DateTime expiresAt;

  const FortSupport({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.type,
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory FortSupport.fromJson(Map<String, dynamic> json) {
    return FortSupport(
      id: json['id'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      receiverId: json['receiverId'] as String? ?? '',
      type: FortSupportType.fromString(json['type'] as String? ?? 'encouragement'),
      createdAt: json['createdAt'] is DateTime
          ? json['createdAt'] as DateTime
          : DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] is DateTime
          ? json['expiresAt'] as DateTime
          : DateTime.parse(json['expiresAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'receiverId': receiverId,
        'type': type.name,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      };
}

enum FortSupportType {
  encouragement,
  prayer,
  strengthBoost;

  static FortSupportType fromString(String value) {
    return FortSupportType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FortSupportType.encouragement,
    );
  }
}
