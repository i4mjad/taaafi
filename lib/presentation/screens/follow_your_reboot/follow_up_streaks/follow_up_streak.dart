import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reboot_app_3/bloc_provider.dart';
import 'package:reboot_app_3/presentation/blocs/follow_your_reboot_bloc.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/follow_your_reboot_widgets.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';

class FollowUpStreaks extends StatelessWidget {
  FollowUpStreaks({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = CustomBlocProvider.of<FollowYourRebootBloc>(context);
    final theme = Theme.of(context);
    return StreamBuilder(
      stream: bloc.streamUserDoc(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
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
                              border:
                                  Border.all(width: 0.25, color: Colors.green),
                              borderRadius: BorderRadius.circular(15)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              FutureBuilder(
                                future: bloc.getRelapseStreak(),
                                initialData: 0,
                                builder: (BuildContext context,
                                    AsyncSnapshot<int> snapshot) {
                                  switch (snapshot.connectionState) {
                                    // Uncompleted State
                                    case ConnectionState.none:
                                    case ConnectionState.waiting:
                                      return Center(
                                          child: CircularProgressIndicator());

                                    default:
                                      // Completed with error

                                      if (snapshot.hasError) {
                                        return Center(
                                          child:
                                              Text(snapshot.error.toString()),
                                        );
                                      }
                                  }
                                  return Text(
                                    snapshot.data.toString(),
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
                          border:
                              Border.all(color: Colors.orange, width: 0.25)),
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
                                        color: Colors.orangeAccent,
                                        fontSize: 35),
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
                                offset:
                                    Offset(0, 2), // changes position of shadow
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
      },
    );
  }
}
