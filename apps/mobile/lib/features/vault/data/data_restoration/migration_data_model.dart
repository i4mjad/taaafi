/// Model representing migration status for a specific category
class CategoryMigrationStatus {
  final List<String> legacy;
  final List<String> migrated;
  final List<String> missing;
  final List<String> duplicates;
  final int duplicateCount;
  final Map<String, int> dateCount;
  final List<DuplicateDetail> duplicateDetails;
  final int totalEntries;
  final int uniqueEntries;

  CategoryMigrationStatus({
    required this.legacy,
    required this.migrated,
    required this.missing,
    required this.duplicates,
    required this.duplicateCount,
    required this.dateCount,
    required this.duplicateDetails,
    required this.totalEntries,
    required this.uniqueEntries,
  });

  bool get hasMissingData => missing.isNotEmpty;
  bool get hasDuplicates => duplicates.isNotEmpty;
  bool get hasIssues => hasMissingData || hasDuplicates;
}

/// Model for duplicate details
class DuplicateDetail {
  final String date;
  final int count;
  final int extras;

  DuplicateDetail({
    required this.date,
    required this.count,
    required this.extras,
  });
}

/// Overall migration data for all categories
class MigrationData {
  final CategoryMigrationStatus relapses;
  final CategoryMigrationStatus mastOnly;
  final CategoryMigrationStatus pornOnly;

  MigrationData({
    required this.relapses,
    required this.mastOnly,
    required this.pornOnly,
  });

  int getTotalMissingCount() {
    return relapses.missing.length + mastOnly.missing.length + pornOnly.missing.length;
  }

  int getTotalFollowupsCount() {
    return relapses.migrated.length + mastOnly.migrated.length + pornOnly.migrated.length;
  }

  int getTotalDuplicatesCount() {
    return relapses.duplicateCount + mastOnly.duplicateCount + pornOnly.duplicateCount;
  }

  bool get isMigrationComplete => getTotalMissingCount() == 0;
  bool get hasLegacyData => relapses.legacy.isNotEmpty || mastOnly.legacy.isNotEmpty || pornOnly.legacy.isNotEmpty;
  bool get hasAnyIssues => relapses.hasIssues || mastOnly.hasIssues || pornOnly.hasIssues;
}

/// Migration status enum
enum MigrationStatus {
  checking,
  noIssues,
  issuesFound,
  migrating,
  removingDuplicates,
  success,
  error,
}
