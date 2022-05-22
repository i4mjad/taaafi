import 'package:cloud_firestore/cloud_firestore.dart';

class FollowUpData {
  FollowUpData(
    this.startingDate,
    this.relapses,
    this.pornWithoutMasterbation,
    this.masterbationWithoutPorn,
  );

  Timestamp startingDate;
  List<dynamic> relapses;
  List<dynamic> pornWithoutMasterbation;
  List<dynamic> masterbationWithoutPorn;

  FollowUpData.fromSnapshot(DocumentSnapshot snapshot) {
    startingDate = snapshot['startingDate'];
    relapses = snapshot['userRelapses'];
    pornWithoutMasterbation = snapshot['userWatchingWithoutMasturbating'];
    masterbationWithoutPorn = snapshot['userMasturbatingWithoutWatching'];
  }
}
