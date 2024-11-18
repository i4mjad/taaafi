import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/monitoring/analytics_client.dart';
import 'package:reboot_app_3/core/monitoring/logger_analytics_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'analytics_facade.g.dart';

@Riverpod(keepAlive: true)
AnalyticsFacade analyticsFacade(Ref ref) {
  return const AnalyticsFacade([
    if (!kReleaseMode) LoggerAnalyticsClient(),
  ]);
}

class AnalyticsFacade implements AnalyticsClient {
  const AnalyticsFacade(this.clients);
  final List<AnalyticsClient> clients;

  @override
  Future<void> trackAppOpened() => _dispatch(
        (c) => c.trackAppOpened(),
      );

  @override
  Future<void> trackFollowUpRemoved() => _dispatch(
        (c) => c.trackFollowUpRemoved(),
      );

  @override
  Future<void> trackFollowUpUpdated() => _dispatch(
        (c) => c.trackFollowUpUpdated(),
      );

  @override
  Future<void> trackNewFollowUpAdded() => _dispatch(
        (c) => c.trackNewFollowUpAdded(),
      );

  @override
  Future<void> trackOnboarding() => _dispatch(
        (c) => c.trackOnboarding(),
      );

  @override
  Future<void> trackAppClosed() => _dispatch(
        (c) => c.trackAppClosed(),
      );

  @override
  Future<void> trackOnboardingStart() => _dispatch(
        (c) => c.trackOnboardingStart(),
      );

  @override
  Future<void> trackOnboardingFinish() => _dispatch(
        (c) => c.trackOnboardingFinish(),
      );

  @override
  Future<void> trackUserLogin() => _dispatch(
        (c) => c.trackUserLogin(),
      );

  @override
  Future<void> trackUserLogout() => _dispatch(
        (c) => c.trackUserLogout(),
      );

  @override
  Future<void> trackUserSignup() => _dispatch(
        (c) => c.trackUserSignup(),
      );

  @override
  Future<void> trackUserUpdateProfile() => _dispatch(
        (c) => c.trackUserUpdateProfile(),
      );

  @override
  Future<void> trackUserDeleteAccount() => _dispatch(
        (c) => c.trackUserDeleteAccount(),
      );

  Future<void> _dispatch(
      Future<void> Function(AnalyticsClient client) work) async {
    for (var client in clients) {
      await work(client);
    }
  }
}
