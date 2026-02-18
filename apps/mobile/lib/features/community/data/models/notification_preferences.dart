/// Notification Preferences Model
///
/// Represents user's notification preferences for community groups.
class NotificationPreferences {
  /// Whether the user has app notifications enabled at system level
  final bool appNotificationsEnabled;

  /// Whether to receive message notifications from group chats
  final bool messagesNotifications;

  /// Whether to receive challenge notifications (future feature)
  final bool challengesNotifications;

  /// Whether to receive update notifications from groups (future feature)
  final bool updateNotifications;

  const NotificationPreferences({
    required this.appNotificationsEnabled,
    required this.messagesNotifications,
    required this.challengesNotifications,
    required this.updateNotifications,
  });

  /// Default notification preferences for new users
  static const NotificationPreferences defaultPreferences =
      NotificationPreferences(
    appNotificationsEnabled: false, // Will be checked from system
    messagesNotifications: true,
    challengesNotifications: true,
    updateNotifications: true,
  );

  /// Create from JSON/Firestore data
  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      appNotificationsEnabled:
          json['appNotificationsEnabled'] as bool? ?? false,
      messagesNotifications: json['messagesNotifications'] as bool? ?? true,
      challengesNotifications: json['challengesNotifications'] as bool? ?? true,
      updateNotifications: json['updateNotifications'] as bool? ?? true,
    );
  }

  /// Convert to JSON/Firestore data
  Map<String, dynamic> toJson() {
    return {
      'appNotificationsEnabled': appNotificationsEnabled,
      'messagesNotifications': messagesNotifications,
      'challengesNotifications': challengesNotifications,
      'updateNotifications': updateNotifications,
    };
  }

  /// Create a copy with updated fields
  NotificationPreferences copyWith({
    bool? appNotificationsEnabled,
    bool? messagesNotifications,
    bool? challengesNotifications,
    bool? updateNotifications,
  }) {
    return NotificationPreferences(
      appNotificationsEnabled:
          appNotificationsEnabled ?? this.appNotificationsEnabled,
      messagesNotifications:
          messagesNotifications ?? this.messagesNotifications,
      challengesNotifications:
          challengesNotifications ?? this.challengesNotifications,
      updateNotifications: updateNotifications ?? this.updateNotifications,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationPreferences &&
        other.appNotificationsEnabled == appNotificationsEnabled &&
        other.messagesNotifications == messagesNotifications &&
        other.challengesNotifications == challengesNotifications &&
        other.updateNotifications == updateNotifications;
  }

  @override
  int get hashCode {
    return appNotificationsEnabled.hashCode ^
        messagesNotifications.hashCode ^
        challengesNotifications.hashCode ^
        updateNotifications.hashCode;
  }

  @override
  String toString() {
    return 'NotificationPreferences(appNotificationsEnabled: $appNotificationsEnabled, messagesNotifications: $messagesNotifications, challengesNotifications: $challengesNotifications, updateNotifications: $updateNotifications)';
  }
}
