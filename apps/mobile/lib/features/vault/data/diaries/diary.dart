import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity_task.dart';

class Diary {
  final String id;
  final String title;
  final String plainText;
  final DateTime date;
  final List<dynamic>? formattedContent;
  final DateTime? updatedAt;
  final List<String> linkedTaskIds;
  final List<OngoingActivityTask> linkedTasks;

  Diary(
    this.id,
    this.title,
    this.plainText,
    this.date, {
    this.formattedContent,
    this.updatedAt,
    this.linkedTaskIds = const [],
    this.linkedTasks = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'plainText': plainText,
        'date': date.toIso8601String(),
        'formattedContent': formattedContent,
        'updatedAt': updatedAt?.toIso8601String(),
        'linkedTaskIds': linkedTaskIds,
      };

  factory Diary.fromJson(Map<String, dynamic> json) => Diary(
        json['id'] as String,
        json['title'] as String,
        json['plainText'] as String,
        DateTime.parse(json['date'] as String),
        formattedContent: json['formattedContent'] as List<dynamic>?,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
        linkedTaskIds: (json['linkedTaskIds'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );

  Diary copyWith({
    String? id,
    String? title,
    String? plainText,
    DateTime? date,
    List<dynamic>? formattedContent,
    DateTime? updatedAt,
    List<String>? linkedTaskIds,
  }) {
    return Diary(
      id ?? this.id,
      title ?? this.title,
      plainText ?? this.plainText,
      date ?? this.date,
      formattedContent: formattedContent ?? this.formattedContent,
      updatedAt: updatedAt ?? this.updatedAt,
      linkedTaskIds: linkedTaskIds ?? this.linkedTaskIds,
    );
  }
}
