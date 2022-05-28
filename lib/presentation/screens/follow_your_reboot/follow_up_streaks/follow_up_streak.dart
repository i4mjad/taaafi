import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/bloc_provider.dart';
import 'package:reboot_app_3/presentation/blocs/follow_your_reboot_bloc.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/follow_your_reboot_widgets.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';

class FollowUpStreaks extends StatelessWidget {
  const FollowUpStreaks({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = CustomBlocProvider.of<FollowYourRebootBloc>(context);
    return Container(
      child: Padding(
        padding: EdgeInsets.only(right: 16.0, left: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).translate('current-streak'),
                style: kSubTitlesStyle),
            SizedBox(
              height: 8,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.27,
                  height: 150,
                  decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            FutureBuilder(
                              future: bloc.getRelapseStreak(),
                              initialData: 0,
                              builder: (BuildContext context,
                                  AsyncSnapshot<int> streak) {
                                return Text(
                                  streak.data.toString(),
                                  style: kPageTitleStyle.copyWith(
                                    color: Colors.red,
                                    fontSize: 35,
                                  ),
                                );
                              },
                            ),
                            Text(
                              AppLocalizations.of(context)
                                  .translate('free-relapse-days'),
                              style: kSubTitlesStyle.copyWith(
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 8,
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.27,
                  height: 150,
                  decoration: BoxDecoration(
                      color: Colors.orangeAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            FutureBuilder(
                                future: bloc.getNoMastsStreak(),
                                initialData: 0,
                                builder: (BuildContext context,
                                    AsyncSnapshot<int> snapshot) {
                                  return Text(snapshot.data.toString(),
                                      style: kPageTitleStyle.copyWith(
                                          color: Colors.orangeAccent));
                                }),
                            Text(
                              AppLocalizations.of(context)
                                  .translate('free-mast-days'),
                              style: kSubTitlesStyle.copyWith(
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 8,
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.27,
                  height: 150,
                  decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            FutureBuilder(
                                future: bloc.getNoMastsStreak(),
                                initialData: 0,
                                builder: (BuildContext context,
                                    AsyncSnapshot<int> snapshot) {
                                  return Text(
                                    snapshot.data.toString(),
                                    style: kPageTitleStyle.copyWith(
                                        color: Colors.purple),
                                  );
                                }),
                            Text(
                              AppLocalizations.of(context)
                                  .translate('free-porn-days'),
                              style: kSubTitlesStyle.copyWith(
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 16,
            ),
            Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      changeDateEvent(getTodaysDateString(), context);
                    },
                    child: Container(
                      width: (MediaQuery.of(context).size.width),
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: .25,
                            blurRadius: 7,
                            offset: Offset(0, 2), // changes position of shadow
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context)
                                .translate('daily-follow-up'),
                            style: kSubTitlesStyle.copyWith(
                                fontSize: 20,
                                color: primaryColor,
                                fontWeight: FontWeight.w400,
                                height: 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  changeDateEvent(String date, BuildContext context) async {
    final trimedDate = date.trim();
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(left: 20.0, right: 20, top: 8, bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 5,
                      width: MediaQuery.of(context).size.width * 0.1,
                      color: Colors.black12,
                    )
                  ],
                ),
                SizedBox(
                  height: 12,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      trimedDate,
                      style: kPageTitleStyle.copyWith(fontSize: 26),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Icon(
                        Iconsax.close_circle,
                        color: Colors.black26,
                        size: 32,
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context).translate("how-is-this-day"),
                      style: kPageTitleStyle.copyWith(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
                SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    //relapse
                    GestureDetector(
                      onTap: () {
                        // setState(() {
                        //   if (!userRelapses.contains(trimedDate)) {
                        //     //
                        //     userRelapses.add(trimedDate);
                        //     database.collection("users").doc(user.uid).update({
                        //       "userRelapses": userRelapses,
                        //     });
                        //   }

                        //   if (!userMasturbatingWithoutWatching
                        //       .contains(trimedDate)) {
                        //     userMasturbatingWithoutWatching.add(trimedDate);
                        //     database.collection("users").doc(user.uid).update({
                        //       "userMasturbatingWithoutWatching":
                        //           userMasturbatingWithoutWatching,
                        //     });
                        //   }

                        //   if (!userWatchingWithoutMasturbating
                        //       .contains(trimedDate)) {
                        //     userWatchingWithoutMasturbating.add(trimedDate);
                        //     database.collection("users").doc(user.uid).update({
                        //       "userWatchingWithoutMasturbating":
                        //           userWatchingWithoutMasturbating,
                        //     });
                        //   }
                        // });
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width / 2.5,
                        height: 100,
                        decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.5),
                            border: Border.all(color: Colors.red)),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context).translate("relapse"),
                            style: kSubTitlesStyle.copyWith(
                                color: Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                    //success
                    GestureDetector(
                      onTap: () {
                        // setState(() {
                        //   userWatchingWithoutMasturbating.remove(trimedDate);
                        //   userMasturbatingWithoutWatching.remove(trimedDate);
                        //   userRelapses.remove(trimedDate);
                        // });

                        // final userData =
                        //     database.collection("users").doc(user.uid);

                        // userData.update({
                        //   "userRelapses": userRelapses,
                        //   "userWatchingWithoutMasturbating":
                        //       userWatchingWithoutMasturbating,
                        //   "userMasturbatingWithoutWatching":
                        //       userMasturbatingWithoutWatching
                        // });

                        // if (userRelapses.length == 0) {
                        //   userData
                        //       .update({"userRelapses": FieldValue.delete()});
                        // }

                        // if (userWatchingWithoutMasturbating.length == 0) {
                        //   userData.update({
                        //     "userWatchingWithoutMasturbating":
                        //         FieldValue.delete()
                        //   });
                        // }

                        // if (userMasturbatingWithoutWatching.length == 0) {
                        //   userData.update({
                        //     "userMasturbatingWithoutWatching":
                        //         FieldValue.delete()
                        //   });
                        // }

                        Navigator.pop(context);
                        //
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width / 2.5,
                        height: 100,
                        decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.5),
                            border: Border.all(color: Colors.green)),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context).translate("free-day"),
                            style: kSubTitlesStyle.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                                fontSize: 16),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: 18,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    //only porn
                    GestureDetector(
                      onTap: () {
                        // setState(() {
                        //   userWatchingWithoutMasturbating.add(trimedDate);
                        //   database.collection("users").doc(user.uid).update({
                        //     "userWatchingWithoutMasturbating":
                        //         userWatchingWithoutMasturbating
                        //   });
                        // });
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width / 2.5,
                        height: 100,
                        decoration: BoxDecoration(
                            color: Colors.deepPurple.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.5),
                            border: Border.all(color: Colors.deepPurple)),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context).translate("porn-only"),
                            textAlign: TextAlign.center,
                            style: kSubTitlesStyle.copyWith(
                                color: Colors.deepPurple,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                    //only mast
                    GestureDetector(
                      onTap: () {
                        // setState(() {
                        //   userMasturbatingWithoutWatching.add(trimedDate);
                        //   database.collection("users").doc(user.uid).update({
                        //     "userMasturbatingWithoutWatching":
                        //         userMasturbatingWithoutWatching
                        //   });
                        // });
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width / 2.5,
                        height: 100,
                        decoration: BoxDecoration(
                            color: Colors.orangeAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.5),
                            border: Border.all(color: Colors.orangeAccent)),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context).translate("mast-only"),
                            textAlign: TextAlign.center,
                            style: kSubTitlesStyle.copyWith(
                                color: Colors.orangeAccent,
                                fontWeight: FontWeight.w600,
                                fontSize: 16),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
              ],
            ),
          );
        });
  }

  //   void dateChecker(DateTime date) {
  //   //get the range of the dates from the first recorded date until today

  //   //check if the date clicked is within the range, if yes pass it to the function, if not inform the user
  //   if (dayWithinRange(date)) {
  //     final dateStr = date.toString().substring(0, 11);
  //     this.changeDateEvent(dateStr, context);
  //   } else {
  //     outOfRangeAlert(context);
  //   }
  // }
}
