import 'package:cloud_firestore/cloud_firestore.dart';

class Diary {
  final String id;
  final String title;
  final String plainText;
  final String? formattedContent; // Delta JSON string
  final DateTime date;
  final DateTime? updatedAt;

  Diary(
    this.id,
    this.title,
    this.plainText,
    this.date, {
    this.formattedContent,
    this.updatedAt,
  });

  // Helper method to create from Firestore data
  factory Diary.fromFirestore(String id, Map<String, dynamic> data) {
    return Diary(
      id,
      data['title'] as String,
      data['body'] as String, // For backwards compatibility
      (data['timestamp'] as Timestamp).toDate(),
      formattedContent: data['formattedContent'] as String?,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Helper method to convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': plainText, // Keep the plain text for backwards compatibility
      'formattedContent': formattedContent,
      'timestamp': date,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }
}
