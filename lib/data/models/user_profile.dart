class FollowUpData {
  String startingDate;
  List<String> relapses;
  List<String> pornWithoutMasterbation;
  List<String> masterbationWithoutPorn;

  FollowUpData.fromMap(Map<String, dynamic> json) {
    startingDate = json['startingDate'];
    relapses = json['userRelapses'];
    pornWithoutMasterbation = json['userWatchingWithoutMasturbating'];
    masterbationWithoutPorn = json['userMasturbatingWithoutWatching'];
  }
}
