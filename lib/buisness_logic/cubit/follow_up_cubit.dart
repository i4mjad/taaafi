import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
part 'follow_up_state.dart';

class FollowUpCubit extends Cubit<FollowUpState> {
  FollowUpCubit() : super(FollowUpInitial());
}
