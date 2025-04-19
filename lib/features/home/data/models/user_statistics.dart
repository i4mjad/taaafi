class UserStatisticsModel {
  final int daysWithoutRelapse;
  final int totalDaysFromFirstDate;
  final int longestRelapseStreak;

  UserStatisticsModel({
    required this.daysWithoutRelapse,
    required this.totalDaysFromFirstDate,
    required this.longestRelapseStreak,
  });
}
