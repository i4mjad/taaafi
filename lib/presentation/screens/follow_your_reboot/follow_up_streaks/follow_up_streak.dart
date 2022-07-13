import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/bloc_provider.dart';
import 'package:reboot_app_3/presentation/blocs/follow_your_reboot_bloc.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/follow_your_reboot_widgets.dart';
import 'package:reboot_app_3/shared/components/snackbar.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';

class FollowUpStreaks extends StatelessWidget {
  const FollowUpStreaks({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = CustomBlocProvider.of<FollowYourRebootBloc>(context);
    final theme = Theme.of(context);
    return Container(
      child: Padding(
        padding: EdgeInsets.only(right: 16.0, left: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).translate('current-streak'),
                style: kSubTitlesStyle.copyWith(color: theme.hintColor)),
            SizedBox(
              height: 8,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.27,
                      height: 150,
                      decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.3),
                          border: Border.all(width: 0.25, color: Colors.green),
                          borderRadius: BorderRadius.circular(15)),
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
                                  color: Colors.green,
                                  fontSize: 35,
                                ),
                              );
                            },
                          ),
                          Text(
                            AppLocalizations.of(context)
                                .translate('free-relapse-days'),
                            style: kSubTitlesStyle.copyWith(
                                fontSize: 14, color: theme.hintColor),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: 8,
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.27,
                  height: 150,
                  decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.orange, width: 0.25)),
                  child: Container(
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
                                    color: Colors.orangeAccent, fontSize: 35),
                              );
                            }),
                        Text(
                          AppLocalizations.of(context)
                              .translate('free-mast-days'),
                          style: kSubTitlesStyle.copyWith(
                              fontSize: 14, color: theme.hintColor),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 8,
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.27,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.3),
                    border: Border.all(color: Colors.purple, width: 0.25),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FutureBuilder(
                          future: bloc.getNoPornStreak(),
                          initialData: 0,
                          builder: (BuildContext context,
                              AsyncSnapshot<int> snapshot) {
                            return Text(
                              snapshot.data.toString(),
                              style: kPageTitleStyle.copyWith(
                                color: Colors.purple,
                                fontSize: 35,
                              ),
                            );
                          }),
                      Text(
                        AppLocalizations.of(context)
                            .translate('free-porn-days'),
                        style: kSubTitlesStyle.copyWith(
                            fontSize: 14, color: theme.hintColor),
                        textAlign: TextAlign.center,
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
                      HapticFeedback.mediumImpact();
                      changeDateEvent(getTodaysDateString(), context, bloc);
                    },
                    child: Container(
                      width: (MediaQuery.of(context).size.width),
                      height: 60,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
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
                                color: theme.primaryColor,
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

  changeDateEvent(
    String date, BuildContext context, FollowYourRebootBloc bloc) async {
    final trimedDate = date.trim();
    final theme = Theme.of(context);
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
                      style: kPageTitleStyle.copyWith(fontSize: 26, color: theme.primaryColor),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Icon(
                        Iconsax.close_circle,
                        color: theme.primaryColor,
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
                        bloc.addRelapse(date);
                        Navigator.pop(context);
                        getSnackBar(context, "relapse-recorded");
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
                        bloc.addSuccess(date);
                        Navigator.pop(context);
                        getSnackBar(context, "free-day-recorded");
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
                        bloc.addWatchOnly(date);
                        Navigator.pop(context);
                        getSnackBar(context, "pornonly-recorded");
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
                        bloc.addMastOnly(date);
                        Navigator.pop(context);
                        getSnackBar(context, "mastonly-recorded");
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
}
