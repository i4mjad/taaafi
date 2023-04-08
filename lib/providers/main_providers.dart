// Define providers
import 'package:cloud_firestore/cloud_firestore.dart';
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

final userDocStreamProvider = StreamProvider.autoDispose<DocumentSnapshot>((ref) {
  final user = ref.watch(authStateChangesProvider).asData.value;
  if (user == null) {
    return Stream.value(null);
  } else {
    return FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();
  }
});
