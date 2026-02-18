import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:reboot_app_3/features/authentication/data/models/user_document.dart';
import 'package:reboot_app_3/features/authentication/application/migration_service.dart';

part 'migration_state_notifier.freezed.dart';
part 'migration_state_notifier.g.dart';

@freezed
class MigrationState with _$MigrationState {
  const factory MigrationState.initial() = _Initial;
  const factory MigrationState.loading() = _Loading;
  const factory MigrationState.success() = _Success;
  const factory MigrationState.error(String message) = _Error;
}

@riverpod
class MigrationStateNotifier extends _$MigrationStateNotifier {
  late final MigrationService _migrationService;

  @override
  MigrationState build() {
    _migrationService = ref.watch(migrationServiceProvider);
    return const MigrationState.initial();
  }

  Future<bool> migrateUser(UserDocument userDocument) async {
    state = const MigrationState.loading();

    try {
      await _migrationService.migrateToNewDocuemntStrcture(userDocument);
      state = const MigrationState.success();
      return true;
    } catch (e) {
      print('Error during migration: $e');
      state = const MigrationState.error("something-went-wrong");
      return false;
    }
  }
}
