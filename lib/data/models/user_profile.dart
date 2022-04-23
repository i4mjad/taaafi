class FollowUpData {
  String startingDate;
  List<String> relapses;
  List<String> pornWithoutMasterbation;
  List<String> masterbationWithoutPorn;

  FollowUpData.fromSnapshot(Map<String, dynamic> snapshot) {
    startingDate = snapshot['startingDate'];
    relapses = snapshot['userRelapses'];
    pornWithoutMasterbation = snapshot['userWatchingWithoutMasturbating'];
    masterbationWithoutPorn = snapshot['userMasturbatingWithoutWatching'];
  }
}
