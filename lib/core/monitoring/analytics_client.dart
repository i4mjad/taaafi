abstract class AnalyticsClient {
  Future<void> trackAppOpened();
  Future<void> trackOnboarding();
  Future<void> trackNewFollowUpAdded();
  Future<void> trackFollowUpUpdated();
  Future<void> trackFollowUpRemoved();
}
