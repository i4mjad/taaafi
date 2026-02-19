/// A single zone within the fort, each with 5 upgrade tiers.
class FortZone {
  final FortZoneType type;
  final int tier; // 1-5
  final double progress; // 0.0-1.0 toward next tier

  const FortZone({
    required this.type,
    required this.tier,
    required this.progress,
  });

  bool get isMaxTier => tier >= 5;

  factory FortZone.fromJson(Map<String, dynamic> json) {
    return FortZone(
      type: FortZoneType.fromString(json['type'] as String? ?? 'walls'),
      tier: (json['tier'] as num?)?.toInt().clamp(1, 5) ?? 1,
      progress: (json['progress'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'tier': tier,
        'progress': progress,
      };
}

enum FortZoneType {
  walls,       // الأسوار — XP from clean days
  garden,      // الحديقة — XP from activity completion
  watchtower,  // برج المراقبة — XP from blocker usage
  library,     // المكتبة — XP from reading content
  prayerRoom;  // المصلى — XP from check-in streak

  String get translationKey => 'fort_zone_$name';

  static FortZoneType fromString(String value) {
    return FortZoneType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FortZoneType.walls,
    );
  }

  /// Tier display names (Arabic-first).
  List<String> get tierTranslationKeys => List.generate(
        5,
        (i) => 'fort_zone_${name}_tier_${i + 1}',
      );
}
