import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:reboot_app_3/Shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/Shared/localization/localization.dart';

void outOfRangeAlert(BuildContext context) {
  showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 5,
                    width: MediaQuery.of(context).size.width * 0.1,
                    decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(30)),
                  )
                ],
              ),
              SizedBox(
                height: 12,
              ),
              CircleAvatar(
                backgroundColor: Colors.red.withOpacity(0.2),
                child: Icon(
                  Iconsax.warning_2,
                  color: Colors.red,
                ),
              ),
              SizedBox(
                height: 4,
              ),
              Text(
                AppLocalizations.of(context).translate("out-of-range"),
                style:
                    kPageTitleStyle.copyWith(color: Colors.red, fontSize: 24),
              ),
              SizedBox(
                height: 8,
              ),
              Text(
                AppLocalizations.of(context).translate('out-of-range-p'),
                style: kSubTitlesStyle.copyWith(
                    color: Colors.black.withOpacity(0.7),
                    fontWeight: FontWeight.normal,
                    fontSize: 18),
              ),
              SizedBox(
                height: 30,
              )
            ],
          ),
        );
      });
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

String getTodaysDateString() {
  final DateTime now = DateTime.now();
  final DateFormat formatter = DateFormat('yyyy-MM-dd');
  final String today = formatter.format(now);
  return today;
}
