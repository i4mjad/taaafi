import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';

/// Extended follow-up model for analytics
class AnalyticsFollowUp extends FollowUpModel {
  final List<String> triggers;
  final int? moodRating; // -5 to +5
  final String? notes;
  final int? hourOfDay; // 0-23 for risk clock

  AnalyticsFollowUp({
    required String id,
    required FollowUpType type,
    required DateTime time,
    this.triggers = const [],
    this.moodRating,
    this.notes,
    int? hourOfDay,
  })  : hourOfDay = hourOfDay ?? time.hour,
        super(id: id, type: type, time: time);

  /// Create from FollowUpModel with additional analytics data
  factory AnalyticsFollowUp.fromFollowUp(
    FollowUpModel followUp, {
    List<String>? triggers,
    int? moodRating,
    String? notes,
  }) {
    return AnalyticsFollowUp(
      id: followUp.id,
      type: followUp.type,
      time: followUp.time,
      triggers: triggers ?? [],
      moodRating: moodRating,
      notes: notes,
      hourOfDay: followUp.time.hour,
    );
  }

  /// Create from Firestore document
  factory AnalyticsFollowUp.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final baseFollowUp = FollowUpModel.fromDoc(doc);

    return AnalyticsFollowUp(
      id: baseFollowUp.id,
      type: baseFollowUp.type,
      time: baseFollowUp.time,
      triggers: List<String>.from(data['triggers'] ?? []),
      moodRating: data['moodRating'] as int?,
      notes: data['notes'] as String?,
      hourOfDay: baseFollowUp.time.hour,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final baseMap = super.toMap();
    return {
      ...baseMap,
      'triggers': triggers,
      'moodRating': moodRating,
      'notes': notes,
    };
  }

  AnalyticsFollowUp copyWith({
    String? id,
    FollowUpType? type,
    DateTime? time,
    List<String>? triggers,
    int? moodRating,
    String? notes,
  }) {
    return AnalyticsFollowUp(
      id: id ?? this.id,
      type: type ?? this.type,
      time: time ?? this.time,
      triggers: triggers ?? this.triggers,
      moodRating: moodRating ?? this.moodRating,
      notes: notes ?? this.notes,
    );
  }
}

/// Common triggers for analytics
class CommonTriggers {
  static const List<String> triggers = [
    'stress',
    'boredom',
    'loneliness',
    'late-night',
    'social-media',
    'tiredness',
    'anger',
    'celebration',
    'anxiety',
    'depression',
  ];

  static String getLocalizedTrigger(
      String trigger, String Function(String) translate) {
    return translate('trigger-$trigger');
  }
}
