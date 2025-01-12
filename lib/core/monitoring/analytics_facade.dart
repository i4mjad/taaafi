import 'package:reboot_app_3/core/monitoring/analytics_client.dart';
import 'package:reboot_app_3/core/monitoring/google_analytics_client.dart';
import 'package:reboot_app_3/core/monitoring/logger_analytics_client.dart';
import 'package:reboot_app_3/core/monitoring/mixpanel_analytics_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'analytics_facade.g.dart';

@Riverpod(keepAlive: true)
AnalyticsFacade analyticsFacade(AnalyticsFacadeRef ref) {
  final clients = <AnalyticsClient>[
    LoggerAnalyticsClient(),
    ref.read(googleAnalyticsClientProvider),
  ];

  // TODO: This seems costly, commented for now to figure out if it's needed
  // ref.listen(
  //   mixpanelAnalyticsClientProvider,
  //   (previous, next) {
  //     if (next.hasValue) {
  //       clients.add(next.value!);
  //     }
  //   },
  // );

  return AnalyticsFacade(clients);
}

class AnalyticsFacade implements AnalyticsClient {
  const AnalyticsFacade(this.clients);
  final List<AnalyticsClient> clients;

  @override
  Future<void> identifyUser(String userId) => _dispatch(
        (c) => c.identifyUser(userId),
      );

  @override
  Future<void> resetUser() => _dispatch(
        (c) => c.resetUser(),
      );

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

  @override
  Future<void> trackScreenView(String routeName, String action) => _dispatch(
        (c) => c.trackScreenView(routeName, action),
      );

  @override
  Future<void> trackUserResetDataStarted() {
    return _dispatch(
      (c) => c.trackUserResetDataStarted(),
    );
  }

  @override
  Future<void> trackUserResetDataFinished() => _dispatch(
        (c) => c.trackUserResetDataFinished(),
      );

  @override
  Future<void> trackActivityFetchStarted() => _dispatch(
        (c) => c.trackActivityFetchStarted(),
      );

  @override
  Future<void> trackActivityFetchFinished() => _dispatch(
        (c) => c.trackActivityFetchFinished(),
      );

  @override
  Future<void> trackActivityFetchFailed() => _dispatch(
        (c) => c.trackActivityFetchFailed(),
      );

  @override
  Future<void> trackActivityDeleteFailed() => _dispatch(
        (c) => c.trackActivityDeleteFailed(),
      );

  @override
  Future<void> trackActivityDeleteFinished() => _dispatch(
        (c) => c.trackActivityDeleteFinished(),
      );

  @override
  Future<void> trackActivityDeleteStarted() => _dispatch(
        (c) => c.trackActivityDeleteStarted(),
      );

  @override
  Future<void> trackActivitySubscriptionFailed() => _dispatch(
        (c) => c.trackActivitySubscriptionFailed(),
      );

  @override
  Future<void> trackActivitySubscriptionFinished() => _dispatch(
        (c) => c.trackActivitySubscriptionFinished(),
      );

  @override
  Future<void> trackActivitySubscriptionStarted() => _dispatch(
        (c) => c.trackActivitySubscriptionStarted(),
      );

  @override
  Future<void> trackActivityUpdateFailed() => _dispatch(
        (c) => c.trackActivityUpdateFailed(),
      );

  @override
  Future<void> trackActivityUpdateFinished() => _dispatch(
        (c) => c.trackActivityUpdateFinished(),
      );

  @override
  Future<void> trackActivityUpdateStarted() => _dispatch(
        (c) => c.trackActivityUpdateStarted(),
      );

  @override
  Future<void> trackProgressCalculationFailed() => _dispatch(
        (c) => c.trackProgressCalculationFailed(),
      );

  @override
  Future<void> trackProgressCalculationFinished() => _dispatch(
        (c) => c.trackProgressCalculationFinished(),
      );

  @override
  Future<void> trackProgressCalculationStarted() => _dispatch(
        (c) => c.trackProgressCalculationStarted(),
      );

  @override
  Future<void> trackTaskCompletionFailed() => _dispatch(
        (c) => c.trackTaskCompletionFailed(),
      );

  @override
  Future<void> trackTaskCompletionFinished() => _dispatch(
        (c) => c.trackTaskCompletionFinished(),
      );

  @override
  Future<void> trackTaskCompletionStarted() => _dispatch(
        (c) => c.trackTaskCompletionStarted(),
      );

  Future<void> _dispatch(
      Future<void> Function(AnalyticsClient client) work) async {
    for (var client in clients) {
      await work(client);
    }
  }
}
