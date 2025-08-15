import 'package:cloud_firestore/cloud_firestore.dart';

class AccountDeleteRequest {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final Timestamp requestedAt;
  final String reasonId;
  final String? reasonDetails;
  final String reasonCategory;
  final bool isCanceled;
  final bool isProcessed;
  final Timestamp? canceledAt;
  final Timestamp? processedAt;
  final String? processedBy;
  final String? adminNotes;

  AccountDeleteRequest({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.requestedAt,
    required this.reasonId,
    this.reasonDetails,
    required this.reasonCategory,
    this.isCanceled = false,
    this.isProcessed = false,
    this.canceledAt,
    this.processedAt,
    this.processedBy,
    this.adminNotes,
  });

  factory AccountDeleteRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AccountDeleteRequest(
      id: doc.id,
      userId: data['userId'],
      userEmail: data['userEmail'],
      userName: data['userName'],
      requestedAt: data['requestedAt'],
      reasonId: data['reasonId'],
      reasonDetails: data['reasonDetails'],
      reasonCategory: data['reasonCategory'],
      isCanceled: data['isCanceled'] ?? false,
      isProcessed: data['isProcessed'] ?? false,
      canceledAt: data['canceledAt'],
      processedAt: data['processedAt'],
      processedBy: data['processedBy'],
      adminNotes: data['adminNotes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'requestedAt': requestedAt,
      'reasonId': reasonId,
      'reasonDetails': reasonDetails,
      'reasonCategory': reasonCategory,
      'isCanceled': isCanceled,
      'isProcessed': isProcessed,
      'canceledAt': canceledAt,
      'processedAt': processedAt,
      'processedBy': processedBy,
      'adminNotes': adminNotes,
    };
  }

  AccountDeleteRequest copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? userName,
    Timestamp? requestedAt,
    String? reasonId,
    String? reasonDetails,
    String? reasonCategory,
    bool? isCanceled,
    bool? isProcessed,
    Timestamp? canceledAt,
    Timestamp? processedAt,
    String? processedBy,
    String? adminNotes,
  }) {
    return AccountDeleteRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      requestedAt: requestedAt ?? this.requestedAt,
      reasonId: reasonId ?? this.reasonId,
      reasonDetails: reasonDetails ?? this.reasonDetails,
      reasonCategory: reasonCategory ?? this.reasonCategory,
      isCanceled: isCanceled ?? this.isCanceled,
      isProcessed: isProcessed ?? this.isProcessed,
      canceledAt: canceledAt ?? this.canceledAt,
      processedAt: processedAt ?? this.processedAt,
      processedBy: processedBy ?? this.processedBy,
      adminNotes: adminNotes ?? this.adminNotes,
    );
  }
}