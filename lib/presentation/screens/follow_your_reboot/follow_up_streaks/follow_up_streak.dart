import 'package:flutter/material.dart';
import 'package:reboot_app_3/bloc_provider.dart';
import 'package:reboot_app_3/presentation/blocs/follow_your_reboot_bloc.dart';
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
                      //changeDateEvent(getTodaysDateString());
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
}