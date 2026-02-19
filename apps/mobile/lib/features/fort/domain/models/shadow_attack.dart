/// A shadow attack event on the fort (Phase 2).
class ShadowAttack {
  final String id;
  final DateTime triggeredAt;
  final ShadowAttackStatus status;
  final DateTime? resolvedAt;

  const ShadowAttack({
    required this.id,
    required this.triggeredAt,
    required this.status,
    this.resolvedAt,
  });

  factory ShadowAttack.fromJson(Map<String, dynamic> json) {
    return ShadowAttack(
      id: json['id'] as String? ?? '',
      triggeredAt: json['triggeredAt'] is DateTime
          ? json['triggeredAt'] as DateTime
          : DateTime.parse(json['triggeredAt'] as String),
      status: ShadowAttackStatus.fromString(json['status'] as String? ?? 'pending'),
      resolvedAt: json['resolvedAt'] != null
          ? (json['resolvedAt'] is DateTime
              ? json['resolvedAt'] as DateTime
              : DateTime.parse(json['resolvedAt'] as String))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'triggeredAt': triggeredAt.toIso8601String(),
        'status': status.name,
        'resolvedAt': resolvedAt?.toIso8601String(),
      };
}

enum ShadowAttackStatus {
  pending,
  defended,
  breached;

  static ShadowAttackStatus fromString(String value) {
    return ShadowAttackStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ShadowAttackStatus.pending,
    );
  }
}
