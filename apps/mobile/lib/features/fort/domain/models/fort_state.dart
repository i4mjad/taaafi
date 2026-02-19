import 'package:reboot_app_3/features/fort/domain/models/fort_zone.dart';

/// The complete state of a user's fort.
class FortState {
  final int level;
  final int xp;
  final int xpForNextLevel;
  final Map<FortZoneType, FortZone> zones;
  final List<FortInhabitant> inhabitants;
  final FortSeason season;

  const FortState({
    required this.level,
    required this.xp,
    required this.xpForNextLevel,
    required this.zones,
    required this.inhabitants,
    required this.season,
  });

  double get levelProgress =>
      xpForNextLevel > 0 ? (xp / xpForNextLevel).clamp(0.0, 1.0) : 0.0;

  factory FortState.initial() => FortState(
        level: 1,
        xp: 0,
        xpForNextLevel: 200,
        zones: {
          for (final type in FortZoneType.values)
            type: FortZone(type: type, tier: 1, progress: 0.0),
        },
        inhabitants: [FortInhabitant.guardian],
        season: FortSeason.current(),
      );

  factory FortState.fromJson(Map<String, dynamic> json) {
    final zonesMap = <FortZoneType, FortZone>{};
    if (json['zones'] is Map) {
      for (final entry in (json['zones'] as Map).entries) {
        final type = FortZoneType.fromString(entry.key as String);
        zonesMap[type] =
            FortZone.fromJson(entry.value as Map<String, dynamic>);
      }
    }
    // Ensure all zone types exist
    for (final type in FortZoneType.values) {
      zonesMap.putIfAbsent(type, () => FortZone(type: type, tier: 1, progress: 0.0));
    }

    final inhabitantNames = (json['inhabitants'] as List<dynamic>?)
            ?.map((e) => FortInhabitant.fromString(e as String))
            .toList() ??
        [FortInhabitant.guardian];

    return FortState(
      level: (json['level'] as num?)?.toInt() ?? 1,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      xpForNextLevel: (json['xpForNextLevel'] as num?)?.toInt() ?? 200,
      zones: zonesMap,
      inhabitants: inhabitantNames,
      season: FortSeason.fromString(json['season'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'level': level,
        'xp': xp,
        'xpForNextLevel': xpForNextLevel,
        'zones': zones.map((k, v) => MapEntry(k.name, v.toJson())),
        'inhabitants': inhabitants.map((i) => i.name).toList(),
        'season': season.name,
      };
}

enum FortInhabitant {
  guardian,   // الحارس — default (free)
  scholar,    // العالم — Library Tier 3
  gardener,   // البستاني — Garden Tier 3
  watchman,   // الرقيب — Watchtower Tier 3
  imam,       // الإمام — Prayer Room Tier 3
  healer,     // الطبيب — Fort Level 20
  storyteller, // الراوي — Fort Level 40
  commander;  // القائد — Fort Level 60

  String get translationKey => 'fort_inhabitant_$name';

  static FortInhabitant fromString(String value) {
    return FortInhabitant.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FortInhabitant.guardian,
    );
  }
}

enum FortSeason {
  spring,
  summer,
  autumn,
  winter,
  ramadan,
  eid;

  String get translationKey => 'fort_season_$name';

  static FortSeason fromString(String value) {
    return FortSeason.values.firstWhere(
      (e) => e.name == value,
      orElse: () => current(),
    );
  }

  /// Determine the current season based on the month.
  static FortSeason current() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return FortSeason.spring;
    if (month >= 6 && month <= 8) return FortSeason.summer;
    if (month >= 9 && month <= 11) return FortSeason.autumn;
    return FortSeason.winter;
  }
}
