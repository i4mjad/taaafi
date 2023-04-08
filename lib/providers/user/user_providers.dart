
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:reboot_app_3/data/models/UserProfile.dart';
import 'package:reboot_app_3/repository/user_context.dart';
import 'package:reboot_app_3/viewmodels/user_viewmodel.dart';

final userViewModelProvider =
    StateNotifierProvider<UserViewModel, UserProfile>((ref) {
  final userContext = GetIt.I<IUserContext>();
  return UserViewModel(userContext);
});
