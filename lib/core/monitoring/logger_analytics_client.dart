import 'dart:async';
import 'dart:developer';

import 'package:reboot_app_3/core/monitoring/analytics_client.dart';

class LoggerAnalyticsClient implements AnalyticsClient {
  const LoggerAnalyticsClient();

  static const _name = 'Event';

  @override
  Future<void> trackAppOpened() async {
    log('trackAppOpened', name: _name);
  }

  @override
  Future<void> trackOnboarding() async {
    log('trackOnboarding', name: _name);
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
}
