import 'dart:developer';

import 'package:reboot_app_3/core/monitoring/analytics_client.dart';

class LoggerAnalyticsClient implements AnalyticsClient {
  @override
  Future<void> trackScreenView(String routeName, String action) async {
    log('Tracked screen view: $routeName, $action');
  }

  @override
  Future<void> identifyUser(String userId) async {
    log('Identified user: $userId');
  }

  @override
  Future<void> resetUser() async {
    log('Reset user');
  }

  // Activity tracking
  @override
  Future<void> trackActivityDeleteFailed() async =>
      log('Activity delete failed');

  @override
  Future<void> trackActivityDeleteFinished() async =>
      log('Activity delete finished');

  @override
  Future<void> trackActivityDeleteStarted() async =>
      log('Activity delete started');

  @override
  Future<void> trackActivityFetchFailed() async => log('Activity fetch failed');

  @override
  Future<void> trackActivityFetchFinished() async =>
      log('Activity fetch finished');

  @override
  Future<void> trackActivityFetchStarted() async =>
      log('Activity fetch started');

  @override
  Future<void> trackActivitySubscriptionFailed() async =>
      log('Activity subscription failed');

  @override
  Future<void> trackActivitySubscriptionFinished() async =>
      log('Activity subscription finished');

  @override
  Future<void> trackActivitySubscriptionStarted() async =>
      log('Activity subscription started');

  @override
  Future<void> trackActivityUpdateFailed() async =>
      log('Activity update failed');

  @override
  Future<void> trackActivityUpdateFinished() async =>
      log('Activity update finished');

  @override
  Future<void> trackActivityUpdateStarted() async =>
      log('Activity update started');

  // App lifecycle
  @override
  Future<void> trackAppClosed() async => log('App closed');

  @override
  Future<void> trackAppOpened() async => log('App opened');

  // Follow up tracking
  @override
  Future<void> trackFollowUpRemoved() async => log('Follow up removed');

  @override
  Future<void> trackFollowUpUpdated() async => log('Follow up updated');

  @override
  Future<void> trackNewFollowUpAdded() async => log('New follow up added');

  // Onboarding
  @override
  Future<void> trackOnboarding() async => log('Onboarding tracked');

  @override
  Future<void> trackOnboardingFinish() async => log('Onboarding finished');

  @override
  Future<void> trackOnboardingStart() async => log('Onboarding started');

  // Progress tracking
  @override
  Future<void> trackProgressCalculationFailed() async =>
      log('Progress calculation failed');

  @override
  Future<void> trackProgressCalculationFinished() async =>
      log('Progress calculation finished');

  @override
  Future<void> trackProgressCalculationStarted() async =>
      log('Progress calculation started');

  // Task completion
  @override
  Future<void> trackTaskCompletionFailed() async =>
      log('Task completion failed');

  @override
  Future<void> trackTaskCompletionFinished() async =>
      log('Task completion finished');

  @override
  Future<void> trackTaskCompletionStarted() async =>
      log('Task completion started');

  // User actions
  @override
  Future<void> trackUserDeleteAccount() async => log('User deleted account');

  @override
  Future<void> trackUserLogin() async => log('User logged in');

  @override
  Future<void> trackUserLogout() async => log('User logged out');

  @override
  Future<void> trackUserResetDataFinished() async =>
      log('User reset data finished');

  @override
  Future<void> trackUserResetDataStarted() async =>
      log('User reset data started');

  @override
  Future<void> trackUserSignup() async => log('User signed up');

  @override
  Future<void> trackUserUpdateProfile() async => log('User updated profile');
}
