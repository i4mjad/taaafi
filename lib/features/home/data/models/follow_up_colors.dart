import 'package:flutter/material.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';

final followUpColors = {
  FollowUpType.relapse: Colors.grey,
  FollowUpType.pornOnly: Colors.purple,
  FollowUpType.mastOnly: Color(0xFFD9AF9B),
  FollowUpType.slipUp: Color(0xFF5F8A8D),
  FollowUpType.none: Colors.green,
};

final followUpNamesColors = {
  FollowUpType.relapse.name: Colors.grey,
  FollowUpType.pornOnly.name: Colors.purple,
  FollowUpType.mastOnly.name: Color(0xFFD9AF9B),
  FollowUpType.slipUp.name: Color(0xFF5F8A8D),
  FollowUpType.none.name: Colors.green,
};
