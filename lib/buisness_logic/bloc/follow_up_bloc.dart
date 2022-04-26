import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:reboot_app_3/Model/Relapse.dart';

part 'follow_up_event.dart';
part 'follow_up_state.dart';

class FollowUpBloc extends Bloc<FollowUpEvent, FollowUpState> {
  FollowUpBloc() : super(FollowUpLoading()) {
    on<FollowUpEvent>((event, emit) {
      // TODO: implement event handler
      // if (event is LoadRelapses) {
      //   yield * _mapLoadRelapsesToState();
      // }
    });
  }
}
