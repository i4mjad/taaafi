import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:reboot_app_3/Model/Relapse.dart';
import 'package:reboot_app_3/data/follow_up_repository.dart';
part 'follow_up_state.dart';

class FollowUpCubit extends Cubit<FollowUpState> {
  final FollowUpRepository followUpRepository;
  FollowUpCubit(this.followUpRepository) : super(FollowUpInitial());

}
