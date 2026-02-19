/// Configuration for app blocking features (Phase 3).
class BlockerConfig {
  final bool fortressHoursEnabled;
  final bool usageBudgetsEnabled;
  final bool focusSessionsEnabled;

  const BlockerConfig({
    this.fortressHoursEnabled = false,
    this.usageBudgetsEnabled = false,
    this.focusSessionsEnabled = false,
  });

  factory BlockerConfig.fromJson(Map<String, dynamic> json) {
    return BlockerConfig(
      fortressHoursEnabled: json['fortressHoursEnabled'] as bool? ?? false,
      usageBudgetsEnabled: json['usageBudgetsEnabled'] as bool? ?? false,
      focusSessionsEnabled: json['focusSessionsEnabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'fortressHoursEnabled': fortressHoursEnabled,
        'usageBudgetsEnabled': usageBudgetsEnabled,
        'focusSessionsEnabled': focusSessionsEnabled,
      };
}
