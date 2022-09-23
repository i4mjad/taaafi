class DayOfWeekRelapses {
  final DayOfWeekRelapsesDetails sunRelapses;
  final DayOfWeekRelapsesDetails monRelapses;
  final DayOfWeekRelapsesDetails tueRelapses;
  final DayOfWeekRelapsesDetails wedRelapses;
  final DayOfWeekRelapsesDetails thuRelapses;
  final DayOfWeekRelapsesDetails friRelapses;
  final DayOfWeekRelapsesDetails satRelapses;
  final String totalRelapses;
  DayOfWeekRelapses(
      this.sunRelapses,
      this.monRelapses,
      this.tueRelapses,
      this.wedRelapses,
      this.thuRelapses,
      this.friRelapses,
      this.satRelapses,
      this.totalRelapses);
}

class DayOfWeekRelapsesDetails {
  final double relapsesPercentage;
  final int relapsesCount;

  DayOfWeekRelapsesDetails(this.relapsesPercentage, this.relapsesCount);
}
