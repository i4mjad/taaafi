import 'package:flutter/material.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';

final followUpColors = {
  FollowUpType.relapse: Colors.grey,
  FollowUpType.pornOnly: Color(0xFF9575CD),
  FollowUpType.mastOnly: Color(0xFFFFB74D),
  FollowUpType.slipUp: Color(0xFFFF7F7F),
  FollowUpType.none: Colors.green,
};

final followUpNamesColors = {
  FollowUpType.relapse.name: Colors.grey,
  FollowUpType.pornOnly.name: Color(0xFF9575CD),
  FollowUpType.mastOnly.name: Color(0xFFFFB74D),
  FollowUpType.slipUp.name: Color(0xFFFF7F7F),
  FollowUpType.none.name: Colors.green,
};
