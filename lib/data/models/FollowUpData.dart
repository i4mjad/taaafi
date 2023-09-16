import 'package:cloud_firestore/cloud_firestore.dart';

class FollowUpData {
  FollowUpData(
    this.userFirstDate,
    this.relapses,
    this.pornWithoutMasterbation,
    this.masterbationWithoutPorn,
  );

  Timestamp userFirstDate;
  List<String> relapses;
  List<String> pornWithoutMasterbation;
  List<String> masterbationWithoutPorn;

  FollowUpData.fromSnapshot(DocumentSnapshot snapshot) {
    userFirstDate = snapshot['userFirstDate'];
    relapses = List<String>.from(snapshot['userRelapses']);
    pornWithoutMasterbation =
        List<String>.from(snapshot['userWatchingWithoutMasturbating']);
    masterbationWithoutPorn =
        List<String>.from(snapshot['userMasturbatingWithoutWatching']);
  }

  static FollowUpData Missing = new FollowUpData(Timestamp.now(), [], [], []);
}

class CheckUpData {
  String highestStreak;
  String noRelapsesDays;
  String totalDays;
  String relapsesCount;

  CheckUpData(this.highestStreak, this.noRelapsesDays, this.totalDays,
      this.relapsesCount);

  Map<String, dynamic> toJson() => {
        'highestStreak': highestStreak,
        'noRelapsesDays': noRelapsesDays,
        'totalDays': totalDays,
        'relapsesCount': relapsesCount
      };
}
