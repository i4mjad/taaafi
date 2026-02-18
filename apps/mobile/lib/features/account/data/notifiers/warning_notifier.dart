import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/warning.dart';
import '../repositories/warning_repository.dart';

part 'warning_notifier.g.dart';

/// Notifier for managing warning state with real-time updates
@riverpod
class WarningNotifier extends _$WarningNotifier {
  @override
  Future<List<Warning>> build(String userId) async {
    final repository = ref.watch(warningRepositoryProvider);
    return await repository.getUserWarnings(userId);
  }

  /// Refresh warning data
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(warningRepositoryProvider);
      return await repository.getUserWarnings(userId);
    });
  }

  /// Check if user has critical warnings
  Future<bool> hasCriticalWarnings() async {
    final warnings = await future;
    return warnings
        .any((warning) => warning.severity == WarningSeverity.critical);
  }

  /// Get high priority warnings
  Future<List<Warning>> getHighPriorityWarnings() async {
    final warnings = await future;
    return warnings
        .where((warning) =>
            warning.severity == WarningSeverity.high ||
            warning.severity == WarningSeverity.critical)
        .toList();
  }

  /// Mark warning as read
  Future<void> markWarningAsRead(String warningId) async {
    final repository = ref.read(warningRepositoryProvider);
    await repository.markWarningAsRead(warningId);
    refresh(); // Refresh state after update
  }
}

/// Notifier for current user warnings
@riverpod
class CurrentUserWarningNotifier extends _$CurrentUserWarningNotifier {
  @override
  Future<List<Warning>> build() async {
    final repository = ref.watch(warningRepositoryProvider);
    return await repository.getCurrentUserWarnings();
  }

  /// Refresh current user warning data
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(warningRepositoryProvider);
      return await repository.getCurrentUserWarnings();
    });
  }

  /// Check if current user has critical warnings
  Future<bool> hasCriticalWarnings() async {
    final warnings = await future;
    return warnings
        .any((warning) => warning.severity == WarningSeverity.critical);
  }

  /// Get high priority warnings for current user
  Future<List<Warning>> getHighPriorityWarnings() async {
    final warnings = await future;
    return warnings
        .where((warning) =>
            warning.severity == WarningSeverity.high ||
            warning.severity == WarningSeverity.critical)
        .toList();
  }

  /// Mark warning as read
  Future<void> markWarningAsRead(String warningId) async {
    final repository = ref.read(warningRepositoryProvider);
    await repository.markWarningAsRead(warningId);
    refresh(); // Refresh state after update
  }
}

/// Stream notifier for real-time warning updates
@riverpod
class WarningStreamNotifier extends _$WarningStreamNotifier {
  @override
  Stream<List<Warning>> build(String userId) {
    final repository = ref.watch(warningRepositoryProvider);
    return repository.watchUserWarnings(userId);
  }
}

/// Stream notifier for current user warning updates
@riverpod
class CurrentUserWarningStreamNotifier
    extends _$CurrentUserWarningStreamNotifier {
  @override
  Stream<List<Warning>> build() {
    final repository = ref.watch(warningRepositoryProvider);
    return repository.watchCurrentUserWarnings();
  }
}
