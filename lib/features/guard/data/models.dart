class AppUsage {
  final String id;
  final String label;
  final int minutes;
  AppUsage(this.id, this.label, this.minutes);
}

class UsageSnapshot {
  final List<AppUsage> apps;
  final int pickups;
  final int? notifications;
  final DateTime generatedAt;
  UsageSnapshot(
      {required this.apps,
      required this.pickups,
      this.notifications,
      required this.generatedAt});
}
