class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String reportId;
  final String reportStatus;
  final Map<String, dynamic>? additionalData;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    required this.reportId,
    required this.reportStatus,
    this.additionalData,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool,
      reportId: json['reportId'] as String,
      reportStatus: json['reportStatus'] as String,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'reportId': reportId,
      'reportStatus': reportStatus,
      'additionalData': additionalData,
    };
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? reportId,
    String? reportStatus,
    Map<String, dynamic>? additionalData,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      reportId: reportId ?? this.reportId,
      reportStatus: reportStatus ?? this.reportStatus,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}
