import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:reboot_app_3/features/vault/data/data_restoration/data_restoration_repository.dart';
import 'package:reboot_app_3/features/vault/data/data_restoration/data_restoration_service.dart';
import 'package:reboot_app_3/features/vault/data/data_restoration/migration_data_model.dart';

part 'data_restoration_notifier.g.dart';

/// Provider for the DataRestorationRepository
@Riverpod(keepAlive: true)
DataRestorationRepository dataRestorationRepository(Ref ref) {
  return DataRestorationRepository(FirebaseFirestore.instance, ref);
}

/// Provider for the DataRestorationService
@Riverpod(keepAlive: true)
DataRestorationService dataRestorationService(Ref ref) {
  return DataRestorationService(ref.watch(dataRestorationRepositoryProvider));
}

/// Provider to check if data restoration button should be shown
@riverpod
Future<bool> shouldShowDataRestorationButton(Ref ref) async {
  final service = ref.watch(dataRestorationServiceProvider);
  return await service.shouldShowDataRestorationButton();
}

/// State class for data restoration
class DataRestorationState {
  final MigrationStatus status;
  final MigrationData? migrationData;
  final String? errorMessage;
  final double progress;

  const DataRestorationState({
    required this.status,
    this.migrationData,
    this.errorMessage,
    this.progress = 0.0,
  });

  DataRestorationState copyWith({
    MigrationStatus? status,
    MigrationData? migrationData,
    String? errorMessage,
    double? progress,
  }) {
    return DataRestorationState(
      status: status ?? this.status,
      migrationData: migrationData ?? this.migrationData,
      errorMessage: errorMessage ?? this.errorMessage,
      progress: progress ?? this.progress,
    );
  }

  bool get isLoading => status == MigrationStatus.checking || 
                       status == MigrationStatus.migrating ||
                       status == MigrationStatus.removingDuplicates;

  bool get hasError => status == MigrationStatus.error;
  bool get hasIssues => migrationData?.hasAnyIssues == true;
  bool get isComplete => status == MigrationStatus.success || 
                        (status == MigrationStatus.noIssues && migrationData?.isMigrationComplete == true);
}

/// Notifier for managing data restoration state
@riverpod
class DataRestorationNotifier extends _$DataRestorationNotifier {
  DataRestorationService get service => ref.read(dataRestorationServiceProvider);

  @override
  DataRestorationState build() {
    return const DataRestorationState(status: MigrationStatus.checking);
  }

  /// Performs initial migration analysis
  Future<void> analyzeMigrationStatus() async {
    state = state.copyWith(
      status: MigrationStatus.checking,
      errorMessage: null,
    );

    try {
      final migrationData = await service.analyzeMigrationStatus();
      final progress = service.calculateMigrationProgress(migrationData);

      if (migrationData.hasAnyIssues) {
        state = state.copyWith(
          status: MigrationStatus.issuesFound,
          migrationData: migrationData,
          progress: progress,
        );
      } else {
        state = state.copyWith(
          status: MigrationStatus.noIssues,
          migrationData: migrationData,
          progress: 100.0,
        );
        
        // Mark as checked if no issues found
        await service.markAsCheckedForDataLoss();
      }
    } catch (e) {
      state = state.copyWith(
        status: MigrationStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Migrates missing data for a specific category
  Future<void> migrateMissingDataForCategory({
    required String category,
    required List<String> missingDates,
  }) async {
    if (missingDates.isEmpty) return;

    state = state.copyWith(status: MigrationStatus.migrating);

    try {
      await service.migrateMissingDataForCategory(
        category: category,
        missingDates: missingDates,
      );

      // Re-analyze after migration
      await _reAnalyzeAfterOperation();
    } catch (e) {
      state = state.copyWith(
        status: MigrationStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Removes duplicates for a specific category
  Future<void> removeDuplicatesForCategory({
    required String category,
    required List<String> duplicateDates,
  }) async {
    if (duplicateDates.isEmpty) return;

    state = state.copyWith(status: MigrationStatus.removingDuplicates);

    try {
      await service.removeDuplicatesForCategory(
        category: category,
        duplicateDates: duplicateDates,
      );

      // Re-analyze after operation
      await _reAnalyzeAfterOperation();
    } catch (e) {
      state = state.copyWith(
        status: MigrationStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Performs complete migration for all categories
  Future<void> performCompleteMigration() async {
    state = state.copyWith(status: MigrationStatus.migrating);

    try {
      final updatedMigrationData = await service.performCompleteMigration();
      final progress = service.calculateMigrationProgress(updatedMigrationData);

      state = state.copyWith(
        status: MigrationStatus.success,
        migrationData: updatedMigrationData,
        progress: progress,
      );
    } catch (e) {
      state = state.copyWith(
        status: MigrationStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Removes all duplicates across all categories
  Future<void> removeAllDuplicates() async {
    final migrationData = state.migrationData;
    if (migrationData == null) return;

    state = state.copyWith(status: MigrationStatus.removingDuplicates);

    try {
      await service.removeAllDuplicates(migrationData);
      await _reAnalyzeAfterOperation();
    } catch (e) {
      state = state.copyWith(
        status: MigrationStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Marks as checked without performing migration (when no issues found)
  Future<void> markAsCheckedForDataLoss() async {
    try {
      await service.markAsCheckedForDataLoss();
      state = state.copyWith(status: MigrationStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: MigrationStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Retries the last operation
  Future<void> retry() async {
    await analyzeMigrationStatus();
  }

  /// Resets the state
  void reset() {
    state = const DataRestorationState(status: MigrationStatus.checking);
  }

  /// Helper method to re-analyze migration status after operations
  Future<void> _reAnalyzeAfterOperation() async {
    try {
      final updatedMigrationData = await service.analyzeMigrationStatus();
      final progress = service.calculateMigrationProgress(updatedMigrationData);

      if (updatedMigrationData.hasAnyIssues) {
        state = state.copyWith(
          status: MigrationStatus.issuesFound,
          migrationData: updatedMigrationData,
          progress: progress,
        );
      } else {
        // Mark as checked and complete
        await service.markAsCheckedForDataLoss();
        state = state.copyWith(
          status: MigrationStatus.success,
          migrationData: updatedMigrationData,
          progress: 100.0,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: MigrationStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Gets migration summary text
  String getMigrationSummary() {
    final migrationData = state.migrationData;
    if (migrationData == null) return '';
    
    return service.getMigrationSummary(migrationData);
  }

  /// Gets category display name
  String getCategoryDisplayName(String category) {
    return service.getCategoryDisplayName(category);
  }
}
