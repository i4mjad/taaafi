import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum AttachmentType {
  image,
  video,
  poll,
  link,
  document,
}

class PostAttachment {
  final String id;
  final AttachmentType type;
  final String url;
  final String? thumbnailUrl;
  final String? title;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const PostAttachment({
    required this.id,
    required this.type,
    required this.url,
    this.thumbnailUrl,
    this.title,
    this.description,
    this.metadata,
    required this.createdAt,
  });

  factory PostAttachment.fromJson(Map<String, dynamic> json) {
    return PostAttachment(
      id: json['id'] as String,
      type: AttachmentType.values.byName(json['type'] as String),
      url: json['url'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'title': title,
      'description': description,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

// Extension for getting attachment icons
extension PostAttachmentExtension on PostAttachment {
  IconData get icon {
    switch (type) {
      case AttachmentType.image:
        return LucideIcons.image;
      case AttachmentType.video:
        return LucideIcons.video;
      case AttachmentType.poll:
        return LucideIcons.barChart;
      case AttachmentType.link:
        return LucideIcons.link;
      case AttachmentType.document:
        return LucideIcons.fileText;
    }
  }

  Color get color {
    switch (type) {
      case AttachmentType.image:
        return Colors.blue;
      case AttachmentType.video:
        return Colors.red;
      case AttachmentType.poll:
        return Colors.green;
      case AttachmentType.link:
        return Colors.purple;
      case AttachmentType.document:
        return Colors.orange;
    }
  }

  String get displayName {
    switch (type) {
      case AttachmentType.image:
        return 'Image';
      case AttachmentType.video:
        return 'Video';
      case AttachmentType.poll:
        return 'Poll';
      case AttachmentType.link:
        return 'Link';
      case AttachmentType.document:
        return 'Document';
    }
  }
}

// Poll-specific attachment data
class PollAttachment {
  final String question;
  final List<PollOption> options;
  final bool allowMultipleAnswers;
  final DateTime? expiresAt;

  const PollAttachment({
    required this.question,
    required this.options,
    this.allowMultipleAnswers = false,
    this.expiresAt,
  });

  factory PollAttachment.fromJson(Map<String, dynamic> json) {
    return PollAttachment(
      question: json['question'] as String,
      options: (json['options'] as List)
          .map((option) => PollOption.fromJson(option))
          .toList(),
      allowMultipleAnswers: json['allowMultipleAnswers'] as bool? ?? false,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options.map((option) => option.toJson()).toList(),
      'allowMultipleAnswers': allowMultipleAnswers,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }
}

class PollOption {
  final String id;
  final String text;
  final int votes;

  const PollOption({
    required this.id,
    required this.text,
    this.votes = 0,
  });

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['id'] as String,
      text: json['text'] as String,
      votes: json['votes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'votes': votes,
    };
  }
}
