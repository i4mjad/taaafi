part of 'follow_up_cubit.dart';

@immutable
abstract class FollowUpState {}

class FollowUpInitial extends FollowUpState {}

class FollowUpLoading extends FollowUpState {
  final List<Day> userRelapses;

  FollowUpLoading({this.userRelapses});
}
