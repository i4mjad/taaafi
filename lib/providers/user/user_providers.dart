import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/viewmodels/user_viewmodel.dart';

final userViewModelStateNotifierProvider = StateNotifierProvider((ref) {
  return UserViewModel();
});
