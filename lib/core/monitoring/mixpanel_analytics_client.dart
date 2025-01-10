import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:reboot_app_3/core/monitoring/analytics_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
}

@Riverpod(keepAlive: true)
Future<MixpanelAnalyticsClient> mixpanelAnalyticsClient(
    MixpanelAnalyticsClientRef ref) async {
  final mixpanel = await Mixpanel.init(
    "ac8731373dcf0a35a44d43ab1e3ea5f1",
    trackAutomaticEvents: true,
  );
  return MixpanelAnalyticsClient(mixpanel);
}


// ════════ Exception caught by widgets library ═══════════════════════════════════
// The following StateError was thrown building MyApp(dirty, dependencies: [UncontrolledProviderScope], state: _ConsumerState#e7866):
// Bad state: Tried to call `requireValue` on an `AsyncValue` that has no value: AsyncLoading<MixpanelAnalyticsClient>()

// The relevant error-causing widget was:
//     MyApp MyApp:file:///Users/amjadkhalfan/StudioProjects/ta3afi/lib/main.dart:33:14