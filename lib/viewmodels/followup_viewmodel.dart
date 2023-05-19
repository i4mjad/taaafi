import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/data/models/FollowUpData.dart';
import 'package:reboot_app_3/di/container.dart';
import 'package:reboot_app_3/repository/follow_up_data_repository.dart';

class FollowUpViewModel extends StateNotifier<FollowUpData> {
  final IFollowUpDataRepository _followUpRepository;

  FollowUpViewModel()
      : _followUpRepository = getIt<IFollowUpDataRepository>(),
        super(FollowUpData.Missing) {
    _followUpRepository.getFollowUpDataStream().listen((followUpData) {
      state = followUpData;
    });
  }
}
