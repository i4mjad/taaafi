import 'package:cloud_firestore/cloud_firestore.dart';
import 'ban.dart'; // For RelatedContent class

enum WarningType {
  content_violation,
  inappropriate_behavior,
  spam,
  harassment,
  other,
}

enum WarningSeverity {
  low,
  medium,
  high,
  critical,
}

class Warning {
  final String id;
  final String userId;
  final WarningType type;
  final String reason;
  final String? description;
  final WarningSeverity severity;
  final String issuedBy; // Admin UID or email
  final DateTime issuedAt;
  final bool isActive;
  final List<String>? deviceIds; // User's device IDs at time of warning
  final RelatedContent? relatedContent;
  final String? reportId; // Link to user report if applicable

  const Warning({
    required this.id,
    required this.userId,
    required this.type,
    required this.reason,
    this.description,
    required this.severity,
    required this.issuedBy,
    required this.issuedAt,
    required this.isActive,
    this.deviceIds,
    this.relatedContent,
    this.reportId,
  });

  factory Warning.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Warning(
      id: doc.id,
      userId: data['userId'] as String,
      type: WarningType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => WarningType.other,
      ),
      reason: data['reason'] as String,
      description: data['description'] as String?,
      severity: WarningSeverity.values.firstWhere(
        (e) => e.name == data['severity'],
        orElse: () => WarningSeverity.low,
      ),
      issuedBy: data['issuedBy'] as String,
      issuedAt: (data['issuedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] as bool? ?? true,
      deviceIds: data['deviceIds'] != null
          ? List<String>.from(data['deviceIds'])
          : null,
      relatedContent: data['relatedContent'] != null
          ? RelatedContent.fromMap(data['relatedContent'])
          : null,
      reportId: data['reportId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'reason': reason,
      'description': description,
      'severity': severity.name,
      'issuedBy': issuedBy,
      'issuedAt': Timestamp.fromDate(issuedAt),
      'isActive': isActive,
      'deviceIds': deviceIds,
      'relatedContent': relatedContent?.toMap(),
      'reportId': reportId,
    };
  }

  Warning copyWith({
    String? id,
    String? userId,
    WarningType? type,
    String? reason,
    String? description,
    WarningSeverity? severity,
    String? issuedBy,
    DateTime? issuedAt,
    bool? isActive,
    List<String>? deviceIds,
    RelatedContent? relatedContent,
    String? reportId,
  }) {
    return Warning(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      issuedBy: issuedBy ?? this.issuedBy,
      issuedAt: issuedAt ?? this.issuedAt,
      isActive: isActive ?? this.isActive,
      deviceIds: deviceIds ?? this.deviceIds,
      relatedContent: relatedContent ?? this.relatedContent,
      reportId: reportId ?? this.reportId,
    );
  }
}
