import 'package:flutter/material.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/bloc_provider.dart';
import 'package:reboot_app_3/presentation/blocs/follow_your_reboot_bloc.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';

class DayOfWeekRelapsesWidget extends StatelessWidget {
  const DayOfWeekRelapsesWidget();

  @override
  Widget build(BuildContext context) {
    final bloc = CustomBlocProvider.of<FollowYourRebootBloc>(context);
    return Container(
      padding: EdgeInsets.all(20),
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.225,
      decoration: BoxDecoration(
          color: accentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.5)),
      //two lines of days
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          //first line of days
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              //sunday
              Column(
                children: [
                  FutureBuilder(
                    future: bloc.getRelapsesByDayOfWeek(),
                    initialData: null,
                    builder: (BuildContext context,
                        AsyncSnapshot<DayOfWeekRelapses> streak) {
                      return Text(
                        streak.data.sunRelapses ?? "0",
                        style: kSubTitlesStyle.copyWith(
                            height: 1, color: lightPrimaryColor),
                      );
                    },
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Text(
                    AppLocalizations.of(context).translate("sun"),
                    style: kSubTitlesStyle.copyWith(
                        fontSize: 12, color: lightPrimaryColor, height: 1),
                  ),
                ],
              ),
              Column(
                children: [
                  FutureBuilder(
                    future: bloc.getRelapsesByDayOfWeek(),
                    initialData: null,
                    builder: (BuildContext context,
                        AsyncSnapshot<DayOfWeekRelapses> streak) {
                      return Text(
                        streak.data.monRelapses,
                        style: kSubTitlesStyle.copyWith(
                            height: 1, color: lightPrimaryColor),
                      );
                    },
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Text(
                    AppLocalizations.of(context).translate("mon"),
                    style: kSubTitlesStyle.copyWith(
                        fontSize: 12, color: lightPrimaryColor, height: 1),
                  )
                ],
              ),
              Column(
                children: [
                  Text(
                    "0-",
                    style: kSubTitlesStyle.copyWith(
                        height: 1, color: lightPrimaryColor),
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Text(
                    AppLocalizations.of(context).translate("tue"),
                    style: kSubTitlesStyle.copyWith(
                        fontSize: 12, color: lightPrimaryColor, height: 1),
                  )
                ],
              ),
              Column(
                children: [
                  Text(
                    "00",
                    style: kSubTitlesStyle.copyWith(
                        height: 1, color: lightPrimaryColor),
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Text(
                    AppLocalizations.of(context).translate("wed"),
                    style: kSubTitlesStyle.copyWith(
                        fontSize: 12, color: lightPrimaryColor, height: 1),
                  )
                ],
              ),
            ],
          ),
          //space
          SizedBox(
            height: 28,
          ),
          //second line of days
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text(
                    "00",
                    style: kSubTitlesStyle.copyWith(
                        height: 1, color: lightPrimaryColor),
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Text(
                    AppLocalizations.of(context).translate("thu"),
                    style: kSubTitlesStyle.copyWith(
                        fontSize: 12, color: lightPrimaryColor, height: 1),
                  )
                ],
              ),
              Column(
                children: [
                  Text(
                    "00",
                    style: kSubTitlesStyle.copyWith(
                        height: 1, color: lightPrimaryColor),
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Text(
                    AppLocalizations.of(context).translate("fri"),
                    style: kSubTitlesStyle.copyWith(
                        fontSize: 12, color: lightPrimaryColor, height: 1),
                  )
                ],
              ),
              Column(
                children: [
                  Text(
                    "00",
                    style: kSubTitlesStyle.copyWith(
                        height: 1, color: lightPrimaryColor),
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Text(
                    AppLocalizations.of(context).translate("sat"),
                    style: kSubTitlesStyle.copyWith(
                        fontSize: 12, color: lightPrimaryColor, height: 1),
                  )
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  DayOfWeekRelapses dailyStatistics(List<dynamic> userRelapses) {
    var sat = [];
    var sun = [];
    var mon = [];
    var tue = [];
    var wed = [];
    var thu = [];
    var fri = [];

    for (var strDate in userRelapses) {
      final date = DateTime.parse(strDate);
      final dayOfWeek = date.weekday;

      if (dayOfWeek == 7) {
        sun.add(date);
      } else if (dayOfWeek == 1) {
        mon.add(date);
      } else if (dayOfWeek == 2) {
        tue.add(date);
      } else if (dayOfWeek == 3) {
        wed.add(date);
      } else if (dayOfWeek == 4) {
        thu.add(date);
      } else if (dayOfWeek == 5) {
        fri.add(date);
      } else if (dayOfWeek == 6) {
        sat.add(date);
      }
    }

    final satLength = (sat.length).toString();
    final sunLength = (sun.length).toString();
    final monLength = (mon.length).toString();
    final tueLength = (tue.length).toString();
    final wedLength = (wed.length).toString();
    final thuLength = (thu.length).toString();
    final friLength = (fri.length).toString();

    final dayOfWeekRelapses = DayOfWeekRelapses(satLength, sunLength, monLength,
        tueLength, wedLength, thuLength, friLength);
    return dayOfWeekRelapses;
  }
}

class DayOfWeekRelapses {
  final String sunRelapses;
  final String monRelapses;
  final String tueRelapses;
  final String wedRelapses;
  final String thuRelapses;
  final String friRelapses;
  final String satRelapses;

  DayOfWeekRelapses(this.sunRelapses, this.monRelapses, this.tueRelapses,
      this.wedRelapses, this.thuRelapses, this.friRelapses, this.satRelapses);
}
