part of 'follow_up_bloc.dart';

abstract class FollowUpState extends Equatable {
  const FollowUpState();

  @override
  List<Object> get props => [];
}

class FollowUpInitial extends FollowUpState {}

class FollowUpLoading extends FollowUpState {
  final List<Day> userRelapses;

  FollowUpLoading({this.userRelapses});

  @override
  List<Object> get props => [userRelapses];
}

class FollowUpLoaded extends FollowUpState {}
