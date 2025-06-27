import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';
import 'package:reboot_app_3/features/authentication/providers/user_provider.dart';

part 'account_status_provider.g.dart';

enum AccountStatus {
  loading,
  ok,
  needCompleteRegistration,
  needConfirmDetails,
  needEmailVerification,
}

@riverpod
AccountStatus accountStatus(AccountStatusRef ref) {
  final userDocAsync = ref.watch(userDocumentsNotifierProvider);
  final userAsync = ref.watch(userNotifierProvider);

  // If either provider is still loading, return loading status
  if (userDocAsync.isLoading || userAsync.isLoading) {
    return AccountStatus.loading;
  }

  return userDocAsync.when(
    data: (doc) {
      return userAsync.when(
        data: (user) {
          // If no user is logged in, return ok (this will be handled by auth routing)
          if (user == null) {
            return AccountStatus.ok;
          }

          // If no document exists, user needs to complete registration
          if (doc == null) {
            return AccountStatus.needCompleteRegistration;
          }

          // Check email verification first (only for logged in users)
          // Exclude users that only have Apple as their authentication provider
          final hasOnlyAppleProvider = user.providerData.length == 1 &&
              user.providerData.first.providerId == 'apple.com';

          if (!user.emailVerified &&
              user.providerData
                  .any((provider) => provider.providerId == 'password') &&
              !hasOnlyAppleProvider) {
            return AccountStatus.needEmailVerification;
          }

          // Check if user document has missing data or is legacy
          final notifier = ref.read(userDocumentsNotifierProvider.notifier);
          if (notifier.hasMissingData(doc) ||
              notifier.isLegacyUserDocument(doc)) {
            return AccountStatus.needConfirmDetails;
          }

          return AccountStatus.ok;
        },
        error: (_, __) => AccountStatus.needCompleteRegistration,
        loading: () => AccountStatus.loading, // Still loading user data
      );
    },
    error: (_, __) => AccountStatus.needCompleteRegistration,
    loading: () => AccountStatus.loading, // Still loading document data
  );
}
