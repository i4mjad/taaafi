part of 'follow_up_bloc.dart';

abstract class FollowUpEvent extends Equatable {
  const FollowUpEvent();

  @override
  List<Object> get props => [];
}

class LoadRelapses extends FollowUpEvent {
  final List<Day> userRelapses;

  LoadRelapses(this.userRelapses);

  @override
  List<Object> get props => [userRelapses];
}

class UpdateRelapses extends FollowUpEvent {}

class LoadWatches extends FollowUpEvent {}

class UpdateWatches extends FollowUpEvent {}

class LoadMasts extends FollowUpEvent {}

class UpdateMasts extends FollowUpEvent {}
