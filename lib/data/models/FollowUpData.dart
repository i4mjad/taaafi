import 'package:cloud_firestore/cloud_firestore.dart';

class FollowUpData {
  FollowUpData(
    this.userFirstDate,
    this.relapses,
    this.pornWithoutMasterbation,
    this.masterbationWithoutPorn,
  );

  Timestamp userFirstDate;
  List<dynamic> relapses;
  List<dynamic> pornWithoutMasterbation;
  List<dynamic> masterbationWithoutPorn;

  FollowUpData.fromSnapshot(DocumentSnapshot snapshot) {
    userFirstDate = snapshot['userFirstDate'];
    relapses = snapshot['userRelapses'];
    pornWithoutMasterbation = snapshot['userWatchingWithoutMasturbating'];
    masterbationWithoutPorn = snapshot['userMasturbatingWithoutWatching'];
  }

  static FollowUpData Missing = new FollowUpData(Timestamp.now(), [], [], []);
}
