/// Category-level usage data for a single day.
class UsageSummary {
  final DateTime date;
  final List<UsageCategory> categories;
  final int totalScreenTimeMinutes;
  final int pickups;

  const UsageSummary({
    required this.date,
    required this.categories,
    required this.totalScreenTimeMinutes,
    required this.pickups,
  });

  /// Percentage of 24h spent on screen.
  double get screenTimePercentage =>
      (totalScreenTimeMinutes / (24 * 60)).clamp(0.0, 1.0);

  factory UsageSummary.empty(DateTime date) => UsageSummary(
        date: date,
        categories: [],
        totalScreenTimeMinutes: 0,
        pickups: 0,
      );

  factory UsageSummary.fromJson(Map<String, dynamic> json) {
    final cats = (json['categories'] as List<dynamic>?)
            ?.map((c) => UsageCategory.fromJson(c as Map<String, dynamic>))
            .toList() ??
        [];
    return UsageSummary(
      date: json['date'] is DateTime
          ? json['date'] as DateTime
          : DateTime.parse(json['date'] as String),
      categories: cats,
      totalScreenTimeMinutes: (json['totalScreenTimeMinutes'] as num?)?.toInt() ?? 0,
      pickups: (json['pickups'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'categories': categories.map((c) => c.toJson()).toList(),
        'totalScreenTimeMinutes': totalScreenTimeMinutes,
        'pickups': pickups,
      };
}

/// A single usage category (e.g. social media, entertainment).
class UsageCategory {
  final UsageCategoryType type;
  final int minutes;

  const UsageCategory({
    required this.type,
    required this.minutes,
  });

  factory UsageCategory.fromJson(Map<String, dynamic> json) {
    return UsageCategory(
      type: UsageCategoryType.fromString(json['type'] as String? ?? 'other'),
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'minutes': minutes,
      };
}

enum UsageCategoryType {
  socialMedia,
  entertainment,
  games,
  productivity,
  communication,
  education,
  health,
  news,
  other;

  /// Translation key for display.
  String get translationKey => 'fort_category_$name';

  static UsageCategoryType fromString(String value) {
    return UsageCategoryType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UsageCategoryType.other,
    );
  }
}
