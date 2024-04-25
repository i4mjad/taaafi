import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/data/models/CalenderDay.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/calender/calender_data_model.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/follow_your_reboot_helpers.dart';
import 'package:reboot_app_3/providers/followup/followup_providers.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class RebootCalender extends ConsumerWidget {
  const RebootCalender({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followUpData = ref.watch(followupViewModelProvider.notifier);
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
                  future: followUpData.getCalenderData(),
                  initialData: [
                    new CalenderDay("relapse", DateTime.now(), Colors.black)
                  ],
                  builder: (BuildContext context,
                      AsyncSnapshot<List<CalenderDay>> snapshot) {
                    return SfCalendar(
                      backgroundColor: theme.cardColor,
                      onTap: (CalendarTapDetails details) async {
                        var date = details.date as DateTime;
                        var firstDate = await followUpData.getFirstDate();

                        dateChecker(firstDate, date, context, followUpData);
                      },
                      view: CalendarView.month,
                      headerStyle: CalendarHeaderStyle(
                          textAlign: TextAlign.center,
                          backgroundColor: theme.cardColor,
                          textStyle: kSubTitlesStyle.copyWith(
                              color: theme.primaryColor)),
                      dataSource: CalenderDataSource(snapshot.data!),
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
