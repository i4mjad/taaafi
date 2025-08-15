import 'package:cloud_firestore/cloud_firestore.dart';

class EmotionModel {
  final String id;
  final String emotionEmoji;
  final String emotionName;
  final DateTime date;

  EmotionModel({
    required this.id,
    required this.emotionEmoji,
    required this.emotionName,
    required this.date,
  });

  factory EmotionModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EmotionModel(
      id: doc.id,
      emotionEmoji: data['emotionEmoji'] ?? '',
      emotionName: data['emotionName'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'emotionEmoji': emotionEmoji,
      'emotionName': emotionName,
      'date': date,
    };
  }

  EmotionModel copyWith({
    String? id,
    String? emotionEmoji,
    String? emotionName,
    DateTime? date,
  }) {
    return EmotionModel(
      id: id ?? this.id,
      emotionEmoji: emotionEmoji ?? this.emotionEmoji,
      emotionName: emotionName ?? this.emotionName,
      date: date ?? this.date,
    );
  }
}
