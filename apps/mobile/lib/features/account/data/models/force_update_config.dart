import 'package:cloud_firestore/cloud_firestore.dart';

class ForceUpdateConfig {
  final String minimumVersion;
  final String enforcement; // "optional" | "forced"
  final DateTime? forceAfterDate;
  final int dismissCooldownHours;
  final Map<String, String> title;
  final Map<String, String> message;
  final bool enabled;

  const ForceUpdateConfig({
    required this.minimumVersion,
    required this.enforcement,
    this.forceAfterDate,
    this.dismissCooldownHours = 24,
    required this.title,
    required this.message,
    required this.enabled,
  });

  bool get isCurrentlyForced {
    if (enforcement == 'forced') return true;
    if (forceAfterDate != null && DateTime.now().isAfter(forceAfterDate!)) {
      return true;
    }
    return false;
  }

  factory ForceUpdateConfig.fromMap(Map<String, dynamic> data) {
    return ForceUpdateConfig(
      minimumVersion: data['minimumVersion'] as String? ?? '0.0.0',
      enforcement: data['enforcement'] as String? ?? 'optional',
      forceAfterDate: data['forceAfterDate'] != null
          ? (data['forceAfterDate'] as Timestamp).toDate()
          : null,
      dismissCooldownHours: data['dismissCooldownHours'] as int? ?? 24,
      title: _parseLocalizedMap(data['title']),
      message: _parseLocalizedMap(data['message']),
      enabled: data['enabled'] as bool? ?? false,
    );
  }

  static Map<String, String> _parseLocalizedMap(dynamic data) {
    if (data is Map) {
      return {
        'ar': data['ar']?.toString() ?? '',
        'en': data['en']?.toString() ?? '',
      };
    }
    return {'ar': '', 'en': ''};
  }
}
