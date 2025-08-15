int focusScore(
    {required int minutesDistract,
    required int minutesTotal,
    required int pickups}) {
  if (minutesTotal == 0) return 100;
  final r = minutesDistract / minutesTotal; // 0..1
  final pp = (pickups / 50.0).clamp(0, 1); // 50 pickups = max penalty
  final base = 100.0 * (1.0 - 0.7 * r - 0.3 * pp);
  return base.clamp(0.0, 100.0).round();
}
