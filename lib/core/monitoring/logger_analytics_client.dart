import 'dart:async';
import 'dart:developer';

import 'package:reboot_app_3/core/monitoring/analytics_client.dart';

class LoggerAnalyticsClient implements AnalyticsClient {
  const LoggerAnalyticsClient();

  static const _name = 'Event';

  @override
  Future<void> identifyUser(String userId) async {
    log('identifyUser($userId)', name: _name);
  }

  @override
  Future<void> resetUser() async {
    log('resetUser', name: _name);
  }

  @override
  Future<void> trackAppOpened() async {
    log('trackAppOpened', name: _name);
  }

  @override
  Future<void> trackOnboarding() async {
    log('trackOnboarding', name: _name);
  }

  @override
  Future<void> trackOnboardingStart() async {
    log('trackOnboardingStart', name: _name);
  }

  @override
  Future<void> trackOnboardingFinish() async {
    log('trackOnboardingFinish', name: _name);
  }

  @override
  Future<void> trackNewFollowUpAdded() async {
    log('trackNewFollowUpAdded', name: _name);
  }

  @override
  Future<void> trackFollowUpUpdated() async {
    log('trackFollowUpUpdated', name: _name);
  }

  @override
  Future<void> trackFollowUpRemoved() async {
    log('trackFollowUpRemoved', name: _name);
  }

  @override
  Future<void> trackAppClosed() async {
    log('trackAppClosed', name: _name);
  }

  @override
  Future<void> trackUserLogin() async {
    log('trackUserLogin', name: _name);
  }

  @override
  Future<void> trackUserLogout() async {
    log('trackUserLogout', name: _name);
  }

  @override
  Future<void> trackUserSignup() async {
    log('trackUserSignup', name: _name);
  }

  @override
  Future<void> trackUserUpdateProfile() async {
    log('trackUserUpdateProfile', name: _name);
  }

  @override
  Future<void> trackUserDeleteAccount() async {
    log('trackUserDeleteAccount', name: _name);
  }

  @override
  Future<void> trackScreenView(String routeName, String action) async {
    log('trackScreenView($routeName, $action)', name: 'Navigation');
  }
}
