import 'package:reboot_app_3/features/vault/data/data_restoration/data_restoration_repository.dart';
import 'package:reboot_app_3/features/vault/data/data_restoration/migration_data_model.dart';

/// Service that contains business logic for data restoration and migration
class DataRestorationService {
  final DataRestorationRepository _repository;

  DataRestorationService(this._repository);

  /// Checks if the data restoration button should be shown
  Future<bool> shouldShowDataRestorationButton() async {
    return await _repository.shouldShowDataRestorationButton();
  }

  /// Analyzes migration status and returns comprehensive data
  Future<MigrationData> analyzeMigrationStatus() async {
    return await _repository.analyzeMigrationStatus();
  }

  /// Migrates missing data for a specific category
  Future<void> migrateMissingDataForCategory({
    required String category,
    required List<String> missingDates,
  }) async {
    if (missingDates.isEmpty) return;

    final followUpType = _mapCategoryToFollowUpType(category);
    await _repository.createMissingFollowUps(
      missingDates: missingDates,
      followUpType: followUpType,
    );
  }

  /// Removes duplicates for a specific category
  Future<void> removeDuplicatesForCategory({
    required String category,
    required List<String> duplicateDates,
  }) async {
    if (duplicateDates.isEmpty) return;

    final followUpType = _mapCategoryToFollowUpType(category);
    await _repository.removeDuplicatesForCategory(
      duplicateDates: duplicateDates,
      followUpType: followUpType,
    );
  }

  /// Migrates all missing data across all categories
  Future<void> migrateAllMissingData(MigrationData migrationData) async {
    // Migrate relapses
    if (migrationData.relapses.missing.isNotEmpty) {
      await migrateMissingDataForCategory(
        category: 'relapses',
        missingDates: migrationData.relapses.missing,
      );
    }

    // Migrate mastOnly
    if (migrationData.mastOnly.missing.isNotEmpty) {
      await migrateMissingDataForCategory(
        category: 'mastOnly',
        missingDates: migrationData.mastOnly.missing,
      );
    }

    // Migrate pornOnly
    if (migrationData.pornOnly.missing.isNotEmpty) {
      await migrateMissingDataForCategory(
        category: 'pornOnly',
        missingDates: migrationData.pornOnly.missing,
      );
    }
  }

  /// Removes all duplicates across all categories
  Future<void> removeAllDuplicates(MigrationData migrationData) async {
    // Remove duplicates for relapses
    if (migrationData.relapses.duplicates.isNotEmpty) {
      await removeDuplicatesForCategory(
        category: 'relapses',
        duplicateDates: migrationData.relapses.duplicates,
      );
    }

    // Remove duplicates for mastOnly
    if (migrationData.mastOnly.duplicates.isNotEmpty) {
      await removeDuplicatesForCategory(
        category: 'mastOnly',
        duplicateDates: migrationData.mastOnly.duplicates,
      );
    }

    // Remove duplicates for pornOnly
    if (migrationData.pornOnly.duplicates.isNotEmpty) {
      await removeDuplicatesForCategory(
        category: 'pornOnly',
        duplicateDates: migrationData.pornOnly.duplicates,
      );
    }
  }

  /// Marks the user as having checked for data loss
  Future<void> markAsCheckedForDataLoss() async {
    await _repository.markAsCheckedForDataLoss();
  }

  /// Performs a complete migration check and fix if needed
  Future<MigrationData> performCompleteMigration() async {
    // First, analyze the current status
    final migrationData = await analyzeMigrationStatus();

    // If there are missing entries, migrate them
    if (migrationData.getTotalMissingCount() > 0) {
      await migrateAllMissingData(migrationData);
    }

    // If there are duplicates, remove them
    if (migrationData.getTotalDuplicatesCount() > 0) {
      await removeAllDuplicates(migrationData);
    }

    // Re-analyze to get updated status
    final updatedMigrationData = await analyzeMigrationStatus();

    // Mark as checked regardless of whether there were issues
    await markAsCheckedForDataLoss();

    return updatedMigrationData;
  }

  /// Validates migration prerequisites
  bool validateMigrationPrerequisites(MigrationData migrationData) {
    // Check if there's any legacy data to migrate
    return migrationData.hasLegacyData;
  }

  /// Gets a summary of migration status
  String getMigrationSummary(MigrationData migrationData) {
    final totalMissing = migrationData.getTotalMissingCount();
    final totalDuplicates = migrationData.getTotalDuplicatesCount();
    final totalFollowups = migrationData.getTotalFollowupsCount();

    if (totalMissing == 0 && totalDuplicates == 0) {
      return 'Migration complete. $totalFollowups follow-ups found.';
    }

    final issues = <String>[];
    if (totalMissing > 0) {
      issues.add('$totalMissing missing entries');
    }
    if (totalDuplicates > 0) {
      issues.add('$totalDuplicates duplicate entries');
    }

    return 'Issues found: ${issues.join(', ')}. $totalFollowups total follow-ups.';
  }

  /// Maps UI category names to follow-up types
  String _mapCategoryToFollowUpType(String category) {
    switch (category) {
      case 'relapses':
        return 'relapse';
      case 'mastOnly':
        return 'mastOnly';
      case 'pornOnly':
        return 'pornOnly';
      default:
        throw ArgumentError('Unknown category: $category');
    }
  }

  /// Gets user-friendly category names
  String getCategoryDisplayName(String category) {
    switch (category) {
      case 'relapses':
        return 'Relapses';
      case 'mastOnly':
        return 'Masturbation Only';
      case 'pornOnly':
        return 'Porn Only';
      default:
        return category;
    }
  }

  /// Calculates migration progress percentage
  double calculateMigrationProgress(MigrationData migrationData) {
    final totalLegacy = migrationData.relapses.legacy.length +
        migrationData.mastOnly.legacy.length +
        migrationData.pornOnly.legacy.length;

    if (totalLegacy == 0) return 100.0;

    final totalMigrated = migrationData.relapses.uniqueEntries +
        migrationData.mastOnly.uniqueEntries +
        migrationData.pornOnly.uniqueEntries;

    return (totalMigrated / totalLegacy * 100).clamp(0.0, 100.0);
  }
}
