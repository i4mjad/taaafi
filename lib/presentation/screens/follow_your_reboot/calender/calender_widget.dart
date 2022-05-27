import 'package:flutter/material.dart';
import 'package:reboot_app_3/Model/Relapse.dart';
import 'package:reboot_app_3/Shared/constants/constants.dart';
import 'package:reboot_app_3/Shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/bloc_provider.dart';
import 'package:reboot_app_3/presentation/blocs/follow_your_reboot_bloc.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import 'calender_data_model.dart';

class FollowUpCalender extends StatelessWidget {
  FollowUpCalender({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = CustomBlocProvider.of<FollowYourRebootBloc>(context);

    return FutureBuilder(
        future: bloc.getCalenderData(),
        initialData: [new Day("sd", DateTime.now(), Colors.white)],
        builder: (BuildContext context, AsyncSnapshot<List<Day>> snapshot) {
          return Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.35,
            decoration: BoxDecoration(
                color: mainGrayColor, borderRadius: BorderRadius.circular(15)),
            child: SfCalendar(
              onTap: (CalendarTapDetails details) {
                DateTime date = details.date;
                //TODO - Implement dateChecker method after pulling it out from the presentation layer
                // dateChecker(date);
              },
              view: CalendarView.month,
              headerStyle: CalendarHeaderStyle(
                  textAlign: TextAlign.center,
                  backgroundColor: mainYellowColor,
                  textStyle: kSubTitlesStyle),
              dataSource: CalenderDataSource(snapshot.data),
              monthViewSettings: MonthViewSettings(
                agendaStyle: AgendaStyle(),
                appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
              ),
            ),
          );
        });
  }
}
