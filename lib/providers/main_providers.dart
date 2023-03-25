// Define providers
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/shared/components/app-themes.dart';
import 'package:reboot_app_3/shared/services/auth_service.dart';

final googleAuthenticationServiceProvider =
    Provider<GoogleAuthenticationService>((ref) {
  return GoogleAuthenticationService(FirebaseAuth.instance);
});

final authStateChangesProvider = StreamProvider.autoDispose<User>((ref) {
  return ref.watch(googleAuthenticationServiceProvider).authStateChanges;
});

final customThemeProvider = ChangeNotifierProvider<CustomTheme>((ref) {
  return CustomTheme();
});
