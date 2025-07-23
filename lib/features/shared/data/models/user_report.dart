import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportStatus {
  pending,
  inProgress,
  waitingForAdminResponse,
  closed,
  finalized
}

class UserReport {
  final String id;
  final String uid;
  final DateTime time;
  final String reportTypeId; // Reference to reportTypes collection
  final ReportStatus status;
  final String initialMessage;
  final DateTime lastUpdated;
  final int messagesCount;

  const UserReport({
    required this.id,
    required this.uid,
    required this.time,
    required this.reportTypeId,
    required this.status,
    required this.initialMessage,
    required this.lastUpdated,
    this.messagesCount = 0,
  });

  factory UserReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserReport(
      id: doc.id,
      uid: data['uid'] as String,
      time: (data['time'] as Timestamp).toDate(),
      reportTypeId: data['reportTypeId'] as String,
      status: ReportStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ReportStatus.pending,
      ),
      initialMessage: data['initialMessage'] as String,
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      messagesCount: data['messagesCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'time': Timestamp.fromDate(time),
      'reportTypeId': reportTypeId,
      'status': status.name,
      'initialMessage': initialMessage,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'messagesCount': messagesCount,
    };
  }

  UserReport copyWith({
    String? id,
    String? uid,
    DateTime? time,
    String? reportTypeId,
    ReportStatus? status,
    String? initialMessage,
    DateTime? lastUpdated,
    int? messagesCount,
  }) {
    return UserReport(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      time: time ?? this.time,
      reportTypeId: reportTypeId ?? this.reportTypeId,
      status: status ?? this.status,
      initialMessage: initialMessage ?? this.initialMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      messagesCount: messagesCount ?? this.messagesCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserReport &&
        other.id == id &&
        other.uid == uid &&
        other.time == time &&
        other.reportTypeId == reportTypeId &&
        other.status == status &&
        other.initialMessage == initialMessage &&
        other.lastUpdated == lastUpdated &&
        other.messagesCount == messagesCount;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        uid.hashCode ^
        time.hashCode ^
        reportTypeId.hashCode ^
        status.hashCode ^
        initialMessage.hashCode ^
        lastUpdated.hashCode ^
        messagesCount.hashCode;
  }
}

class ReportMessage {
  final String id;
  final String reportId;
  final String senderId; // uid for user, 'admin' for admin
  final String senderRole; // 'user' or 'admin'
  final String message;
  final DateTime timestamp;
  final bool isRead;

  const ReportMessage({
    required this.id,
    required this.reportId,
    required this.senderId,
    required this.senderRole,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  factory ReportMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportMessage(
      id: doc.id,
      reportId: data['reportId'] as String,
      senderId: data['senderId'] as String,
      senderRole: data['senderRole'] as String,
      message: data['message'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reportId': reportId,
      'senderId': senderId,
      'senderRole': senderRole,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }

  ReportMessage copyWith({
    String? id,
    String? reportId,
    String? senderId,
    String? senderRole,
    String? message,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return ReportMessage(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      senderId: senderId ?? this.senderId,
      senderRole: senderRole ?? this.senderRole,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}
