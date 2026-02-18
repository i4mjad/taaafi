import 'package:cloud_firestore/cloud_firestore.dart';

enum BanType {
  user_ban,
  device_ban,
  feature_ban,
}

enum BanScope {
  app_wide,
  feature_specific,
}

enum BanSeverity {
  temporary,
  permanent,
}

class RelatedContent {
  final String
      type; // 'user', 'report', 'post', 'comment', 'message', 'group', 'other'
  final String id;
  final String? title;
  final Map<String, dynamic>? metadata;

  const RelatedContent({
    required this.type,
    required this.id,
    this.title,
    this.metadata,
  });

  factory RelatedContent.fromMap(Map<String, dynamic> map) {
    return RelatedContent(
      type: map['type'] as String,
      id: map['id'] as String,
      title: map['title'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'id': id,
      'title': title,
      'metadata': metadata,
    };
  }
}

class Ban {
  final String id;
  final String userId;
  final BanType type;
  final BanScope scope;
  final String reason;
  final String? description;
  final BanSeverity severity;
  final String issuedBy; // Admin UID or email
  final DateTime issuedAt;
  final DateTime? expiresAt; // null for permanent bans
  final bool isActive;
  final List<String>? restrictedFeatures; // Array of feature unique names
  final List<String>? restrictedDevices; // Array of device IDs
  final List<String>? deviceIds; // User's device IDs at time of ban
  final RelatedContent? relatedContent;

  const Ban({
    required this.id,
    required this.userId,
    required this.type,
    required this.scope,
    required this.reason,
    this.description,
    required this.severity,
    required this.issuedBy,
    required this.issuedAt,
    this.expiresAt,
    required this.isActive,
    this.restrictedFeatures,
    this.restrictedDevices,
    this.deviceIds,
    this.relatedContent,
  });

  factory Ban.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Ban(
      id: doc.id,
      userId: data['userId'] as String,
      type: BanType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => BanType.user_ban,
      ),
      scope: BanScope.values.firstWhere(
        (e) => e.name == data['scope'],
        orElse: () => BanScope.app_wide,
      ),
      reason: data['reason'] as String,
      description: data['description'] as String?,
      severity: BanSeverity.values.firstWhere(
        (e) => e.name == data['severity'],
        orElse: () => BanSeverity.permanent,
      ),
      issuedBy: data['issuedBy'] as String,
      issuedAt: (data['issuedAt'] as Timestamp).toDate(),
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] as bool? ?? true,
      restrictedFeatures: data['restrictedFeatures'] != null
          ? List<String>.from(data['restrictedFeatures'])
          : null,
      restrictedDevices: data['restrictedDevices'] != null
          ? List<String>.from(data['restrictedDevices'])
          : null,
      deviceIds: data['deviceIds'] != null
          ? List<String>.from(data['deviceIds'])
          : null,
      relatedContent: data['relatedContent'] != null
          ? RelatedContent.fromMap(data['relatedContent'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'scope': scope.name,
      'reason': reason,
      'description': description,
      'severity': severity.name,
      'issuedBy': issuedBy,
      'issuedAt': Timestamp.fromDate(issuedAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'isActive': isActive,
      'restrictedFeatures': restrictedFeatures,
      'restrictedDevices': restrictedDevices,
      'deviceIds': deviceIds,
      'relatedContent': relatedContent?.toMap(),
    };
  }

  bool get isExpired {
    if (expiresAt == null) return false; // Permanent bans never expire
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isCurrentlyActive {
    return isActive && !isExpired;
  }

  Ban copyWith({
    String? id,
    String? userId,
    BanType? type,
    BanScope? scope,
    String? reason,
    String? description,
    BanSeverity? severity,
    String? issuedBy,
    DateTime? issuedAt,
    DateTime? expiresAt,
    bool? isActive,
    List<String>? restrictedFeatures,
    List<String>? restrictedDevices,
    List<String>? deviceIds,
    RelatedContent? relatedContent,
  }) {
    return Ban(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      scope: scope ?? this.scope,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      issuedBy: issuedBy ?? this.issuedBy,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      restrictedFeatures: restrictedFeatures ?? this.restrictedFeatures,
      restrictedDevices: restrictedDevices ?? this.restrictedDevices,
      deviceIds: deviceIds ?? this.deviceIds,
      relatedContent: relatedContent ?? this.relatedContent,
    );
  }
}
