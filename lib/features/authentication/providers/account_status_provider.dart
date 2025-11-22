import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  pendingDeletion,
}

@riverpod
AccountStatus accountStatus(Ref ref) {
  final userDocAsync = ref.watch(userDocumentsNotifierProvider);
  final userAsync = ref.watch(userNotifierProvider);

  // If either provider is still loading, return loading status
  if (userDocAsync.isLoading || userAsync.isLoading) {
    print('🔄 ACCOUNT STATUS: Loading...');
    return AccountStatus.loading;
  }

  return userDocAsync.when(
    data: (doc) {
      return userAsync.when(
        data: (user) {
          print('=== ACCOUNT STATUS CHECK ===');
          print('📧 User email: ${user?.email}');
          print('🔐 User UID: ${user?.uid}');
          print('📱 Provider data: ${user?.providerData.map((p) => p.providerId).join(', ')}');
          
          // If no user is logged in, return ok (this will be handled by auth routing)
          if (user == null) {
            print('✅ ACCOUNT STATUS: OK (No user logged in)');
            return AccountStatus.ok;
          }

          // If no document exists, user needs to complete registration
          if (doc == null) {
            print('⚠️ ACCOUNT STATUS: needCompleteRegistration (No document)');
            return AccountStatus.needCompleteRegistration;
          }

          // Check if account deletion is pending
          if (doc.isRequestedToBeDeleted == true) {
            print('⚠️ ACCOUNT STATUS: pendingDeletion');
            return AccountStatus.pendingDeletion;
          }

          // Check email verification first (only for logged in users)
          // Exclude users that only have Apple as their authentication provider
          // or Apple users without email (due to privacy settings or legacy configuration)
          final hasOnlyAppleProvider = user.providerData.length == 1 &&
              user.providerData.first.providerId == 'apple.com';
          final isAppleUserWithoutEmail = user.providerData
                  .any((provider) => provider.providerId == 'apple.com') &&
              (user.email == null || user.email!.isEmpty);

          if (!user.emailVerified &&
              user.providerData
                  .any((provider) => provider.providerId == 'password') &&
              !hasOnlyAppleProvider &&
              !isAppleUserWithoutEmail) {
            print('⚠️ ACCOUNT STATUS: needEmailVerification');
            return AccountStatus.needEmailVerification;
          }

          // Check if user document has missing data or is legacy
          final notifier = ref.read(userDocumentsNotifierProvider.notifier);
          final hasMissing = notifier.hasMissingData(doc);
          final isLegacy = notifier.isLegacyUserDocument(doc);
          
          if (hasMissing || isLegacy) {
            print('⚠️ ACCOUNT STATUS: needConfirmDetails');
            print('   - Has missing data: $hasMissing');
            print('   - Is legacy document: $isLegacy');
            return AccountStatus.needConfirmDetails;
          }

          print('✅ ACCOUNT STATUS: OK (All checks passed)');
          return AccountStatus.ok;
        },
        error: (error, __) {
          print('❌ ACCOUNT STATUS: needCompleteRegistration (User error: $error)');
          return AccountStatus.needCompleteRegistration;
        },
        loading: () {
          print('🔄 ACCOUNT STATUS: Loading (User data)');
          return AccountStatus.loading;
        },
      );
    },
    error: (error, __) {
      print('❌ ACCOUNT STATUS: needCompleteRegistration (Document error: $error)');
      return AccountStatus.needCompleteRegistration;
    },
    loading: () {
      print('🔄 ACCOUNT STATUS: Loading (Document data)');
      return AccountStatus.loading;
    },
  );
}
