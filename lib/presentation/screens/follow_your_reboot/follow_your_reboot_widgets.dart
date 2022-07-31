import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:reboot_app_3/bloc_provider.dart';
import 'package:reboot_app_3/data/models/CalenderDay.dart';
import 'package:reboot_app_3/presentation/blocs/follow_your_reboot_bloc.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/calender/calender_data_model.dart';
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
    return StreamBuilder(
      stream: bloc.streamUserDoc(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        return Padding(
          padding: EdgeInsets.only(right: 16, left: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                //mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                      AppLocalizations.of(context).translate('reboot-calender'),
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
      },
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
    return StreamBuilder(stream: FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser.uid)
        .snapshots(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {

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
                              alignment:
                              lang == 'ar' ? Alignment.topRight : Alignment.topLeft,
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
                          builder: (BuildContext context, AsyncSnapshot<String> sh) {
                            if (sh.hasData) {
                              return Text(
                                sh.data,
                                style: kPageTitleStyle.copyWith(color: Colors.green),
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
                          builder: (BuildContext context, AsyncSnapshot<String> sh) {
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
              SizedBox(height: 12,),
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
                        AppLocalizations.of(context)
                            .translate("total-days"),
                        style: kHeadlineStyle.copyWith(
                            fontWeight: FontWeight.w400,
                            fontSize: 18,
                            color: theme.primaryColor),
                      ),
                      FutureBuilder(
                        future: bloc.getTotalDaysFromBegining(),
                        initialData: "0",
                        builder: (BuildContext context,
                            AsyncSnapshot<String> sh) {
                          return Text(
                            sh.data,
                            style: kHeadlineStyle.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
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
                        AppLocalizations.of(context)
                            .translate("relapses-number"),
                        style: kHeadlineStyle.copyWith(
                            fontWeight: FontWeight.w400, fontSize: 18),
                      ),
                      FutureBuilder(
                        future: bloc.getRelapsesCount(),
                        initialData: "0",
                        builder: (BuildContext context,
                            AsyncSnapshot<String> sh) {
                          return Text(
                            sh.requireData,
                            style: kHeadlineStyle.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ]
            ,
          ),
        );
      },

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
                    style: kPageTitleStyle.copyWith(
                        fontSize: 26, color: theme.primaryColor),
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
                      HapticFeedback.mediumImpact();
                      getSnackBar(context, "relapse-recorded");
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
                      bloc.addSuccess(date);
                      HapticFeedback.mediumImpact();
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
                      HapticFeedback.mediumImpact();
                      getSnackBar(context, "pornonly-recorded");
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
                      bloc.addMastOnly(date);
                      HapticFeedback.mediumImpact();
                      getSnackBar(context, "mastonly-recorded");
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