import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';
import 'package:reboot_app_3/features/authentication/providers/user_provider.dart';

part 'account_status_provider.g.dart';

enum AccountStatus {
  ok,
  needCompleteRegistration,
  needConfirmDetails,
  needEmailVerification,
}

@riverpod
AccountStatus accountStatus(AccountStatusRef ref) {
  final userDocAsync = ref.watch(userDocumentsNotifierProvider);
  final userAsync = ref.watch(userNotifierProvider);

  return userDocAsync.when(
    data: (doc) {
      if (doc == null) return AccountStatus.needCompleteRegistration;

      // Check email verification first
      return userAsync.when(
        data: (user) {
          if (user != null && !user.emailVerified) {
            return AccountStatus.needEmailVerification;
          }

          // use same logic as before
          final notifier = ref.read(userDocumentsNotifierProvider.notifier);
          if (notifier.hasMissingData(doc) ||
              notifier.isLegacyUserDocument(doc)) {
            return AccountStatus.needConfirmDetails;
          }
          return AccountStatus.ok;
        },
        error: (_, __) => AccountStatus.needCompleteRegistration,
        loading: () => AccountStatus.ok,
      );
    },
    error: (_, __) => AccountStatus.needCompleteRegistration,
    loading: () => AccountStatus.ok,
  );
}
