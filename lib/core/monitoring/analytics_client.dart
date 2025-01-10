abstract class AnalyticsClient {
  Future<void> trackAppOpened();
  Future<void> trackOnboarding();
  Future<void> trackNewFollowUpAdded();
  Future<void> trackFollowUpUpdated();
  Future<void> trackFollowUpRemoved();
  Future<void> trackAppClosed();
  Future<void> trackOnboardingStart();
  Future<void> trackOnboardingFinish();
  Future<void> trackUserLogin();
  Future<void> trackUserLogout();
  Future<void> trackUserSignup();
  Future<void> trackUserUpdateProfile();
  Future<void> trackUserDeleteAccount();
  Future<void> trackScreenView(String routeName, String action);
  Future<void> identifyUser(String userId);
  Future<void> resetUser();
}
