import 'package:flutter/material.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:reboot_app_3/core/localization/localization.dart';

part 'community_notifier.g.dart';

/// Notifier for managing community feature state
@riverpod
class CommunityNotifier extends _$CommunityNotifier {
  @override
  FutureOr<int> build() {
    // Initial state is empty
    return 1;
  }

  /// Records user interest in the community feature
  /// This method calls the service to record interest and handles the UI feedback.
  Future<void> recordInterest(BuildContext context) async {
    state = const AsyncLoading();

    try {
      final serviceAsyncValue = ref.read(communityServiceProvider);

      if (serviceAsyncValue.hasError) {
        throw serviceAsyncValue.error!;
      }

      if (!serviceAsyncValue.hasValue) {
        throw Exception('Service not initialized');
      }

      final service = serviceAsyncValue.value!;
      final wasRecorded = await service.recordInterest();

      if (context.mounted) {
        if (wasRecorded) {
          _showSuccessMessage(context);
        } else {
          _showAlreadyRecordedMessage(context);
        }
      }

      state = const AsyncData(0);
    } catch (e, st) {
      state = AsyncError(e, st);

      if (context.mounted) {
        _showErrorMessage(context);
      }
    }
  }

  void _showSuccessMessage(BuildContext context) {
    final theme = AppTheme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).translate('interest_recorded_success'),
        ),
        backgroundColor: theme.success[500],
      ),
    );
  }

  void _showAlreadyRecordedMessage(BuildContext context) {
    final theme = AppTheme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).translate('interest_already_recorded'),
        ),
        backgroundColor: theme.warn[500],
      ),
    );
  }

  void _showErrorMessage(BuildContext context) {
    final theme = AppTheme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).translate('error_recording_interest'),
        ),
        backgroundColor: theme.error[500],
      ),
    );
  }
}
