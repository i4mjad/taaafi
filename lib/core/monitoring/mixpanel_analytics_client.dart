import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:reboot_app_3/core/monitoring/analytics_client.dart';
import 'package:reboot_app_3/features/authentication/data/repositories/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'mixpanel_analytics_client.g.dart';

class MixpanelAnalyticsClient implements AnalyticsClient {
  const MixpanelAnalyticsClient(this._mixpanel);
  final Mixpanel _mixpanel;

  @override
  Future<void> identifyUser(String userId) async {
    await _mixpanel.identify(userId);
  }

  @override
  Future<void> resetUser() async {
    await _mixpanel.reset();
  }

  @override
  Future<void> trackAppClosed() async {
    await _mixpanel.track('App Closed');
  }

  @override
  Future<void> trackAppOpened() async {
    await _mixpanel.track('App Opened');
  }

  @override
  Future<void> trackFollowUpRemoved() async {
    await _mixpanel.track('Follow Up Removed');
  }

  @override
  Future<void> trackFollowUpUpdated() async {
    await _mixpanel.track('Follow Up Updated');
  }

  @override
  Future<void> trackNewFollowUpAdded() async {
    await _mixpanel.track('New Follow Up Added');
  }

  @override
  Future<void> trackOnboarding() async {
    await _mixpanel.track('Onboarding');
  }

  @override
  Future<void> trackOnboardingFinish() async {
    await _mixpanel.track('Onboarding Finish');
  }

  @override
  Future<void> trackOnboardingStart() async {
    await _mixpanel.track('Onboarding Start');
  }

  @override
  Future<void> trackScreenView(String routeName, String action) async {
    await _mixpanel.track('Screen View',
        properties: {'name': routeName, 'action': action});
  }

  @override
  Future<void> trackUserDeleteAccount() async {
    await _mixpanel.track('User Delete Account');
  }

  @override
  Future<void> trackUserLogin() async {
    await _mixpanel.track('User Login');
  }

  @override
  Future<void> trackUserLogout() async {
    await _mixpanel.track('User Logout');
  }

  @override
  Future<void> trackUserSignup() async {
    await _mixpanel.track('User Signup');
  }

  @override
  Future<void> trackUserUpdateProfile() async {
    await _mixpanel.track('User Update Profile');
  }

  @override
  Future<void> trackUserResetDataStarted() async {
    await _mixpanel.track('User Reset Data Started');
  }

  @override
  Future<void> trackUserResetDataFinished() async {
    await _mixpanel.track('User Reset Data Finished');
  }

  @override
  Future<void> trackActivityFetchStarted() async {
    await _mixpanel.track('Activity Fetch Started');
  }

  @override
  Future<void> trackActivityFetchFinished() async {
    await _mixpanel.track('Activity Fetch Finished');
  }

  @override
  Future<void> trackActivityFetchFailed() async {
    await _mixpanel.track('Activity Fetch Failed');
  }

  @override
  Future<void> trackActivitySubscriptionStarted() async {
    await _mixpanel.track('Activity Subscription Started');
  }

  @override
  Future<void> trackActivitySubscriptionFinished() async {
    await _mixpanel.track('Activity Subscription Finished');
  }

  @override
  Future<void> trackActivitySubscriptionFailed() async {
    await _mixpanel.track('Activity Subscription Failed');
  }

  @override
  Future<void> trackProgressCalculationStarted() async {
    await _mixpanel.track('Progress Calculation Started');
  }

  @override
  Future<void> trackProgressCalculationFinished() async {
    await _mixpanel.track('Progress Calculation Finished');
  }

  @override
  Future<void> trackProgressCalculationFailed() async {
    await _mixpanel.track('Progress Calculation Failed');
  }

  @override
  Future<void> trackTaskCompletionStarted() async {
    await _mixpanel.track('Task Completion Started');
  }

  @override
  Future<void> trackTaskCompletionFinished() async {
    await _mixpanel.track('Task Completion Finished');
  }

  @override
  Future<void> trackTaskCompletionFailed() async {
    await _mixpanel.track('Task Completion Failed');
  }

  @override
  Future<void> trackActivityUpdateStarted() async {
    await _mixpanel.track('Activity Update Started');
  }

  @override
  Future<void> trackActivityDeleteFailed() async {
    await _mixpanel.track('Activity Delete Failed');
  }

  @override
  Future<void> trackActivityDeleteFinished() async {
    await _mixpanel.track('Activity Delete Finished');
  }

  @override
  Future<void> trackActivityDeleteStarted() async {
    await _mixpanel.track('Activity Delete Started');
  }

  @override
  Future<void> trackActivityUpdateFailed() async {
    await _mixpanel.track('Activity Update Failed');
  }

  @override
  Future<void> trackActivityUpdateFinished() async {
    await _mixpanel.track('Activity Update Finished');
  }
}

@Riverpod(keepAlive: true)
Future<MixpanelAnalyticsClient> mixpanelAnalyticsClient(
    MixpanelAnalyticsClientRef ref) async {
  final mixpanel = await ref.read(mixpanelProvider.future);
  return MixpanelAnalyticsClient(mixpanel);
}

@Riverpod(keepAlive: true)
Future<Mixpanel> mixpanel(MixpanelRef ref) async {
  return await Mixpanel.init(
    "ac8731373dcf0a35a44d43ab1e3ea5f1",
    trackAutomaticEvents: true,
  );
}

@Riverpod(keepAlive: true)
Future<void> sentryUserInit(SentryUserInitRef ref) async {
  final user = ref.read(authRepositoryProvider).currentUser;
  Sentry.configureScope(
    (scope) => scope.setUser(SentryUser(
        id: user?.uid != null ? user!.uid : "User not found",
        email: user?.email != null ? user!.email : "User email not found")),
  );
}
