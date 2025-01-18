import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:reboot_app_3/core/monitoring/analytics_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'google_analytics_client.g.dart';

class GoogleAnalyticsClient implements AnalyticsClient {
  final FirebaseAnalytics _analytics;

  GoogleAnalyticsClient(this._analytics);

  @override
  Future<void> trackScreenView(String routeName, String action) async {
    await _analytics.logScreenView(
      screenName: routeName,
      screenClass: action,
    );
  }

  @override
  Future<void> identifyUser(String userId) async {
    await _analytics.setUserId(id: userId);
  }

  @override
  Future<void> resetUser() async {
    await _analytics.setUserId(id: null);
  }

  // Activity tracking
  @override
  Future<void> trackActivityDeleteFailed() async => _analytics.logEvent(
        name: 'activity_delete_failed',
      );

  @override
  Future<void> trackActivityDeleteFinished() async => _analytics.logEvent(
        name: 'activity_delete_finished',
      );

  @override
  Future<void> trackActivityDeleteStarted() async => _analytics.logEvent(
        name: 'activity_delete_started',
      );

  @override
  Future<void> trackActivityFetchFailed() async => _analytics.logEvent(
        name: 'activity_fetch_failed',
      );

  @override
  Future<void> trackActivityFetchFinished() async => _analytics.logEvent(
        name: 'activity_fetch_finished',
      );

  @override
  Future<void> trackActivityFetchStarted() async => _analytics.logEvent(
        name: 'activity_fetch_started',
      );

  @override
  Future<void> trackActivitySubscriptionFailed() async => _analytics.logEvent(
        name: 'activity_subscription_failed',
      );

  @override
  Future<void> trackActivitySubscriptionFinished() async => _analytics.logEvent(
        name: 'activity_subscription_finished',
      );

  @override
  Future<void> trackActivitySubscriptionStarted() async => _analytics.logEvent(
        name: 'activity_subscription_started',
      );

  @override
  Future<void> trackActivityUpdateFailed() async => _analytics.logEvent(
        name: 'activity_update_failed',
      );

  @override
  Future<void> trackActivityUpdateFinished() async => _analytics.logEvent(
        name: 'activity_update_finished',
      );

  @override
  Future<void> trackActivityUpdateStarted() async => _analytics.logEvent(
        name: 'activity_update_started',
      );

  // App lifecycle
  @override
  Future<void> trackAppClosed() async => _analytics.logEvent(
        name: 'app_closed',
      );

  @override
  Future<void> trackAppOpened() async => _analytics.logEvent(
        name: 'app_opened',
      );

  // Follow up tracking
  @override
  Future<void> trackFollowUpRemoved() async => _analytics.logEvent(
        name: 'follow_up_removed',
      );

  @override
  Future<void> trackFollowUpUpdated() async => _analytics.logEvent(
        name: 'follow_up_updated',
      );

  @override
  Future<void> trackNewFollowUpAdded() async => _analytics.logEvent(
        name: 'new_follow_up_added',
      );

  // Onboarding
  @override
  Future<void> trackOnboarding() async => _analytics.logEvent(
        name: 'onboarding',
      );

  @override
  Future<void> trackOnboardingFinish() async => _analytics.logEvent(
        name: 'onboarding_finish',
      );

  @override
  Future<void> trackOnboardingStart() async => _analytics.logEvent(
        name: 'onboarding_start',
      );

  // Progress tracking
  @override
  Future<void> trackProgressCalculationFailed() async => _analytics.logEvent(
        name: 'progress_calculation_failed',
      );

  @override
  Future<void> trackProgressCalculationFinished() async => _analytics.logEvent(
        name: 'progress_calculation_finished',
      );

  @override
  Future<void> trackProgressCalculationStarted() async => _analytics.logEvent(
        name: 'progress_calculation_started',
      );

  // Task completion
  @override
  Future<void> trackTaskCompletionFailed() async => _analytics.logEvent(
        name: 'task_completion_failed',
      );

  @override
  Future<void> trackTaskCompletionFinished() async => _analytics.logEvent(
        name: 'task_completion_finished',
      );

  @override
  Future<void> trackTaskCompletionStarted() async => _analytics.logEvent(
        name: 'task_completion_started',
      );

  // User actions
  @override
  Future<void> trackUserDeleteAccount() async => _analytics.logEvent(
        name: 'user_delete_account',
      );

  @override
  Future<void> trackUserLogin() async => _analytics.logEvent(
        name: 'login',
      );

  @override
  Future<void> trackUserLogout() async => _analytics.logEvent(
        name: 'logout',
      );

  @override
  Future<void> trackUserResetDataFinished() async => _analytics.logEvent(
        name: 'user_reset_data_finished',
      );

  @override
  Future<void> trackUserResetDataStarted() async => _analytics.logEvent(
        name: 'user_reset_data_started',
      );

  @override
  Future<void> trackUserSignup() async => _analytics.logEvent(
        name: 'sign_up',
      );

  @override
  Future<void> trackUserUpdateProfile() async => _analytics.logEvent(
        name: 'user_update_profile',
      );
}

@Riverpod(keepAlive: true)
GoogleAnalyticsClient googleAnalyticsClient(GoogleAnalyticsClientRef ref) {
  return GoogleAnalyticsClient(ref.watch(firebaseAnalyticsProvider));
}

@Riverpod(keepAlive: true)
FirebaseAnalytics firebaseAnalytics(FirebaseAnalyticsRef ref) {
  return FirebaseAnalytics.instance;
}
