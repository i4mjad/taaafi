import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:reboot_app_3/bloc_provider.dart';
import 'package:reboot_app_3/data/models/CalenderDay.dart';
import 'package:reboot_app_3/presentation/blocs/follow_your_reboot_bloc.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/calender/calender_data_model.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/day_of_week_relapses/day_of_week_relapses_widget.dart';
import 'package:reboot_app_3/shared/components/snackbar.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class RebootCalender extends StatelessWidget {
  const RebootCalender({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = CustomBlocProvider.of<FollowYourRebootBloc>(context);
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(right: 16, left: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            //mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context).translate('reboot-calender'),
                  style: kSubTitlesStyle.copyWith(color: theme.hintColor)),
              SizedBox(
                height: 8,
              ),
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.45,
                decoration: BoxDecoration(
                    color: mainGrayColor,
                    borderRadius: BorderRadius.circular(15)),
                child: FutureBuilder(
                  future: bloc.getCalenderData(),
                  initialData: [
                    new CalenderDay("relapse", DateTime.now(), Colors.black)
                  ],
                  builder: (BuildContext context,
                      AsyncSnapshot<List<CalenderDay>> snapshot) {
                    return SfCalendar(
                      backgroundColor: theme.cardColor,
                      onTap: (CalendarTapDetails details) async {
                        DateTime date = details.date;
                        DateTime firstDate = await bloc.getFirstDate();

                        dateChecker(firstDate, date, context, bloc);
                      },
                      view: CalendarView.month,
                      headerStyle: CalendarHeaderStyle(
                          textAlign: TextAlign.center,
                          backgroundColor: theme.cardColor,
                          textStyle: kSubTitlesStyle.copyWith(
                              color: theme.primaryColor)),
                      dataSource: CalenderDataSource(snapshot.data),
                      monthViewSettings: MonthViewSettings(
                        //showAgenda: true,
                        agendaStyle: AgendaStyle(),
                        appointmentDisplayMode:
                            MonthAppointmentDisplayMode.indicator,
                      ),
                      allowAppointmentResize: true,
                    );
                  },
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class GeneralStats extends StatelessWidget {
  const GeneralStats({
    Key key,
    @required this.lang,
  }) : super(key: key);

  final String lang;

  @override
  Widget build(BuildContext context) {
    final bloc = CustomBlocProvider.of<FollowYourRebootBloc>(context);
    final theme = Theme.of(context);
    return Container(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                width: (MediaQuery.of(context).size.width - 40) / 2 - 6,
                height: MediaQuery.of(context).size.height * 0.21,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.5),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: lang == 'ar'
                              ? Alignment.topRight
                              : Alignment.topLeft,
                          child: CircleAvatar(
                            minRadius: 18,
                            maxRadius: 20,
                            backgroundColor: Colors.green.withOpacity(0.3),
                            child: Icon(
                              Iconsax.medal,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: 8.0, top: 3, left: 8),
                          child: Text(
                            AppLocalizations.of(context)
                                .translate('highest-streak'),
                            style: kSubTitlesStyle.copyWith(
                                fontSize: 16, color: Colors.green, height: 1),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    FutureBuilder(
                      future: bloc.getHighestStreak(),
                      initialData: "0",
                      builder:
                          (BuildContext context, AsyncSnapshot<String> sh) {
                        if (sh.hasData) {
                          return Text(
                            sh.data,
                            style:
                                kPageTitleStyle.copyWith(color: Colors.green),
                          );
                        } else {
                          return CircularProgressIndicator();
                        }
                      },
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(12),
                width: (MediaQuery.of(context).size.width - 40) / 2 - 6,
                height: MediaQuery.of(context).size.height * 0.21,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.5),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: CircleAvatar(
                            minRadius: 18,
                            maxRadius: 20,
                            backgroundColor: Colors.blue.withOpacity(0.3),
                            child: Icon(
                              Iconsax.ranking,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: 8.0, top: 3, left: 8),
                          child: Text(
                            AppLocalizations.of(context)
                                .translate('relapses-count'),
                            style: kSubTitlesStyle.copyWith(
                                fontSize: 14, color: Colors.blue, height: 1),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    FutureBuilder(
                      future: bloc.getTotalDaysWithoutRelapse(),
                      initialData: "0",
                      builder:
                          (BuildContext context, AsyncSnapshot<String> sh) {
                        return Text(
                          sh.data,
                          style: kPageTitleStyle.copyWith(color: Colors.blue),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: 12,
          ),
          Column(
            children: [
              //dublicate this
              Row(
                children: [
                  Icon(Iconsax.calendar_tick),
                  SizedBox(
                    width: 8,
                  ),
                  Text(
                    AppLocalizations.of(context).translate("total-days"),
                    style: kHeadlineStyle.copyWith(
                        fontWeight: FontWeight.w400,
                        fontSize: 18,
                        color: theme.primaryColor),
                  ),
                  FutureBuilder(
                    future: bloc.getTotalDaysFromBegining(),
                    initialData: "0",
                    builder: (BuildContext context, AsyncSnapshot<String> sh) {
                      return Text(
                        sh.data,
                        style: kHeadlineStyle.copyWith(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(
                height: 8,
              ),
              Row(
                children: [
                  Icon(Iconsax.emoji_sad),
                  SizedBox(
                    width: 8,
                  ),
                  Text(
                    AppLocalizations.of(context).translate("relapses-number"),
                    style: kHeadlineStyle.copyWith(
                        fontWeight: FontWeight.w400, fontSize: 18),
                  ),
                  FutureBuilder(
                    future: bloc.getRelapsesCount(),
                    initialData: "0",
                    builder: (BuildContext context, AsyncSnapshot<String> sh) {
                      return Text(
                        sh.requireData,
                        style: kHeadlineStyle.copyWith(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RelapsesByDayOfWeek extends StatelessWidget {
  RelapsesByDayOfWeek({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = CustomBlocProvider.of<FollowYourRebootBloc>(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context).translate('relapses-by-day-of-week'),
            style: kSubTitlesStyle.copyWith(color: theme.hintColor)),
        SizedBox(
          height: 8,
        ),
        Container(
          padding: EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.5,
          width: MediaQuery.of(context).size.width - 40,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12.5),
          ),
          child: FutureBuilder(
            future: bloc.getRelapsesByDayOfWeek(),
            initialData: new DayOfWeekRelapses(
              new DayOfWeekRelapsesDetails(0, 0),
              new DayOfWeekRelapsesDetails(0, 0),
              new DayOfWeekRelapsesDetails(0, 0),
              new DayOfWeekRelapsesDetails(0, 0),
              new DayOfWeekRelapsesDetails(0, 0),
              new DayOfWeekRelapsesDetails(0, 0),
              new DayOfWeekRelapsesDetails(0, 0),
            ),
            builder: (context, AsyncSnapshot<DayOfWeekRelapses> snapshot) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          AppLocalizations.of(context)
                              .translate('relapses-number'),
                          style:
                              kSubTitlesStyle.copyWith(color: theme.hintColor)),
                      Text("3",
                          style:
                              kSubTitlesStyle.copyWith(color: theme.hintColor)),
                    ],
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  DayOfWeekWidget(
                    day: "sun",
                    percentage: snapshot.data.sunRelapses.relapsesPercentage,
                    count: snapshot.data.sunRelapses.relapsesCount,
                  ),
                  DayOfWeekWidget(
                    day: "mon",
                    percentage: snapshot.data.monRelapses.relapsesPercentage,
                    count: snapshot.data.monRelapses.relapsesCount,
                  ),
                  DayOfWeekWidget(
                    day: "tue",
                    percentage: snapshot.data.tueRelapses.relapsesPercentage,
                    count: snapshot.data.tueRelapses.relapsesCount,
                  ),
                  DayOfWeekWidget(
                    day: "wed",
                    percentage: snapshot.data.wedRelapses.relapsesPercentage,
                    count: snapshot.data.wedRelapses.relapsesCount,
                  ),
                  DayOfWeekWidget(
                    day: "thu",
                    percentage: snapshot.data.thuRelapses.relapsesPercentage,
                    count: snapshot.data.thuRelapses.relapsesCount,
                  ),
                  DayOfWeekWidget(
                    day: "fri",
                    percentage: snapshot.data.friRelapses.relapsesPercentage,
                    count: snapshot.data.friRelapses.relapsesCount,
                  ),
                  DayOfWeekWidget(
                    day: "sat",
                    percentage: snapshot.data.satRelapses.relapsesPercentage,
                    count: snapshot.data.satRelapses.relapsesCount,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class DayOfWeekWidget extends StatelessWidget {
  DayOfWeekWidget({Key key, this.day, this.percentage, this.count})
      : super(key: key);

  final percentage;
  final count;
  final day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: MediaQuery.of(context).size.width - 56,
      child: Row(
        children: [
          Text(AppLocalizations.of(context).translate(day),
              style: kSubTitlesStyle.copyWith(
                  color: theme.hintColor, fontSize: 12)),
          Container(
            padding: EdgeInsets.only(right: 4, left: 4),
            width: MediaQuery.of(context).size.width - 200,
            child: LinearProgressIndicator(
              backgroundColor: Colors.grey[400],
              value: percentage,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
          Text(
            "${count}",
            style: kSubTitlesStyle.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}

String getTodaysDateString() {
  final DateTime now = DateTime.now();
  final DateFormat formatter = DateFormat('yyyy-MM-dd');
  final String today = formatter.format(now);
  return today;
}

changeDateEvent(
    String date, BuildContext context, FollowYourRebootBloc bloc) async {
  final trimedDate = date.trim();
  final theme = Theme.of(context);
  showModalBottomSheet(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                    decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(50)),
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
                    style: kPageTitleStyle.copyWith(
                        fontSize: 26, color: theme.primaryColor),
                  ),
                ],
              ),
              SizedBox(
                height: 8,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      bloc.addSuccess(date);
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context);
                      getSnackBar(context, "free-day-recorded");
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width / 4 - 24,
                      height: 100,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12.5),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.25),
                          width: 0.25,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "😍",
                            style: TextStyle(fontSize: 22),
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Text(
                            AppLocalizations.of(context).translate("free-day"),
                            style: kSubTitlesStyle.copyWith(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      bloc.addRelapse(date);
                      HapticFeedback.mediumImpact();
                      getSnackBar(context, "relapse-recorded");
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width / 4 - 24,
                      height: 100,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12.5),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.25),
                          width: 0.25,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "😒",
                            style: TextStyle(fontSize: 22),
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Text(
                            AppLocalizations.of(context).translate("relapse"),
                            style: kSubTitlesStyle.copyWith(
                                color: theme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      bloc.addWatchOnly(date);
                      HapticFeedback.mediumImpact();
                      getSnackBar(context, "pornonly-recorded");
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width / 4 - 24,
                      height: 100,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12.5),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.25),
                          width: 0.25,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "😥",
                            style: TextStyle(fontSize: 22),
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Text(
                            AppLocalizations.of(context).translate("porn-only"),
                            textAlign: TextAlign.center,
                            style: kSubTitlesStyle.copyWith(
                                color: theme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      bloc.addMastOnly(date);
                      HapticFeedback.mediumImpact();
                      getSnackBar(context, "mastonly-recorded");
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width / 4 - 24,
                      height: 100,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12.5),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.25),
                          width: 0.25,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "😪",
                            style: TextStyle(fontSize: 22),
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Text(
                            AppLocalizations.of(context).translate("mast-only"),
                            textAlign: TextAlign.center,
                            style: kSubTitlesStyle.copyWith(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
              SizedBox(
                height: 18,
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: MediaQuery.of(context).size.width - 40,
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.primaryColor, width: 0.25),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context).translate("cancel"),
                      style: kSubTitlesStyle.copyWith(
                        color: theme.primaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        );
      });
}

dateChecker(DateTime firstDate, DateTime date, BuildContext context,
    FollowYourRebootBloc bloc) {
  if (dayWithinRange(firstDate, date)) {
    final dateStr = date.toString().substring(0, 10);
    changeDateEvent(dateStr, context, bloc);
  } else {
    outOfRangeAlert(context);
  }
}

outOfRangeAlert(BuildContext context) {
  HapticFeedback.mediumImpact();
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
                      borderRadius: BorderRadius.circular(30),
                    ),
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

bool dayWithinRange(DateTime firstDate, DateTime date) {
  final today = DateTime.now();
  return date.isAfter(firstDate) && date.isBefore(today);
}
