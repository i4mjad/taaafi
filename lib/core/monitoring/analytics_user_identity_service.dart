import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/monitoring/analytics_facade.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'analytics_user_identity_service.g.dart';

class AnalyticsUserIdentityService {
  AnalyticsUserIdentityService(this.ref) {
    ref.listen<AsyncValue<User?>>(authStateChangeStreamProvider,
        (previous, next) {
      final user = next.value;
      if (user != null) {
        ref.read(analyticsFacadeProvider).identifyUser(user.uid);
      } else {
        ref.read(analyticsFacadeProvider).resetUser();
      }
    });
  }
  final Ref ref;
}

@Riverpod(keepAlive: true)
AnalyticsUserIdentityService analyticsUserIdentityService(Ref ref) {
  return AnalyticsUserIdentityService(ref);
}

final authStateChangeStreamProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});
