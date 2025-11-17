import '../entities/group_update_entity.dart';

/// Preset templates for quick update posting
/// These provide common update types that users can select without typing
class UpdatePresetTemplates {
  /// Get all available preset templates
  static List<UpdatePresetTemplate> getAllPresets() {
    return [
      // Support requests
      UpdatePresetTemplate(
        id: 'need_help',
        type: UpdateType.needHelp,
        titleKey: 'preset-need-help-title',
        contentKey: 'preset-need-help-content',
        icon: '🆘',
        category: PresetCategory.support,
      ),
      UpdatePresetTemplate(
        id: 'need_support',
        type: UpdateType.needSupport,
        titleKey: 'preset-need-support-title',
        contentKey: 'preset-need-support-content',
        icon: '🤝',
        category: PresetCategory.support,
      ),
      UpdatePresetTemplate(
        id: 'feeling_weak',
        type: UpdateType.struggle,
        titleKey: 'preset-feeling-weak-title',
        contentKey: 'preset-feeling-weak-content',
        icon: '😔',
        category: PresetCategory.support,
      ),
      UpdatePresetTemplate(
        id: 'urges',
        type: UpdateType.struggle,
        titleKey: 'preset-urges-title',
        contentKey: 'preset-urges-content',
        icon: '⚠️',
        category: PresetCategory.support,
      ),

      // Progress updates
      UpdatePresetTemplate(
        id: 'doing_well',
        type: UpdateType.progress,
        titleKey: 'preset-doing-well-title',
        contentKey: 'preset-doing-well-content',
        icon: '💪',
        category: PresetCategory.progress,
      ),
      UpdatePresetTemplate(
        id: 'milestone_reached',
        type: UpdateType.milestone,
        titleKey: 'preset-milestone-title',
        contentKey: 'preset-milestone-content',
        icon: '🏆',
        category: PresetCategory.progress,
      ),
      UpdatePresetTemplate(
        id: 'clean_streak',
        type: UpdateType.celebration,
        titleKey: 'preset-clean-streak-title',
        contentKey: 'preset-clean-streak-content',
        icon: '🔥',
        category: PresetCategory.progress,
      ),

      // Check-ins
      UpdatePresetTemplate(
        id: 'daily_checkin',
        type: UpdateType.checkin,
        titleKey: 'preset-daily-checkin-title',
        contentKey: 'preset-daily-checkin-content',
        icon: '✅',
        category: PresetCategory.checkin,
      ),
      UpdatePresetTemplate(
        id: 'weekly_checkin',
        type: UpdateType.checkin,
        titleKey: 'preset-weekly-checkin-title',
        contentKey: 'preset-weekly-checkin-content',
        icon: '📅',
        category: PresetCategory.checkin,
      ),

      // Encouragement (gender-aware)
      UpdatePresetTemplate(
        id: 'encourage_others',
        type: UpdateType.encouragement,
        titleKey: 'preset-encourage-title',
        contentKey: 'preset-encourage-content', // Will be suffixed with -male/-female
        icon: '💚',
        category: PresetCategory.encouragement,
        isGenderAware: true,
      ),
      UpdatePresetTemplate(
        id: 'share_tip',
        type: UpdateType.general,
        titleKey: 'preset-share-tip-title',
        contentKey: 'preset-share-tip-content',
        icon: '💡',
        category: PresetCategory.encouragement,
      ),

      // Celebrations
      UpdatePresetTemplate(
        id: 'grateful',
        type: UpdateType.celebration,
        titleKey: 'preset-grateful-title',
        contentKey: 'preset-grateful-content',
        icon: '🙏',
        category: PresetCategory.celebration,
      ),
      UpdatePresetTemplate(
        id: 'victory',
        type: UpdateType.celebration,
        titleKey: 'preset-victory-title',
        contentKey: 'preset-victory-content',
        icon: '🎉',
        category: PresetCategory.celebration,
      ),
    ];
  }

  /// Get presets by category
  static List<UpdatePresetTemplate> getPresetsByCategory(
    PresetCategory category,
  ) {
    return getAllPresets()
        .where((preset) => preset.category == category)
        .toList();
  }

  /// Get preset by ID
  static UpdatePresetTemplate? getPresetById(String id) {
    try {
      return getAllPresets().firstWhere((preset) => preset.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get all preset categories
  static List<PresetCategory> getAllCategories() {
    return PresetCategory.values;
  }

  /// Get category display name (localization key)
  static String getCategoryDisplayKey(PresetCategory category) {
    switch (category) {
      case PresetCategory.support:
        return 'preset-category-support';
      case PresetCategory.progress:
        return 'preset-category-progress';
      case PresetCategory.checkin:
        return 'preset-category-checkin';
      case PresetCategory.encouragement:
        return 'preset-category-encouragement';
      case PresetCategory.celebration:
        return 'preset-category-celebration';
    }
  }
}

/// Preset template for updates
class UpdatePresetTemplate {
  final String id;
  final UpdateType type;
  final String titleKey; // Localization key for title
  final String contentKey; // Localization key for content (will have -male/-female suffix if isGenderAware)
  final String icon; // Emoji icon
  final PresetCategory category;
  final bool isGenderAware; // If true, contentKey will be suffixed with -male/-female

  const UpdatePresetTemplate({
    required this.id,
    required this.type,
    required this.titleKey,
    required this.contentKey,
    required this.icon,
    required this.category,
    this.isGenderAware = false,
  });
}

/// Category for grouping presets
enum PresetCategory {
  support, // Need help/support
  progress, // Progress updates
  checkin, // Regular check-ins
  encouragement, // Encouraging others
  celebration, // Celebrating wins
}

