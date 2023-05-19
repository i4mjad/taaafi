import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/viewmodels/followup_viewmodel.dart';

final followupViewModelProvider = StateNotifierProvider(
  (ref) {
    return FollowUpViewModel();
  },
);
