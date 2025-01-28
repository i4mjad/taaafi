import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:reboot_app_3/features/home/data/calendar_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/features/home/data/models/follow_up_colors.dart';

class CalenderWidget extends ConsumerStatefulWidget {
  const CalenderWidget({
    super.key,
  });

  @override
  _CalenderWidgetState createState() => _CalenderWidgetState();
}

class _CalenderWidgetState extends ConsumerState<CalenderWidget> {
  DateTime userFirstDate = DateTime.now();
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final now = DateTime.now();
      userFirstDate =
          await ref.read(calendarNotifierProvider.notifier).getUserFirstDate();
      await ref
          .read(calendarNotifierProvider.notifier)
          .fetchFollowUpsForMonth(now);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    // final followUpState = ref.watch(calendarNotifierProvider);
    final stream = ref.watch(calendarStreamProvider);

    return stream.when(
      data: (followUps) {
        return Container(
          width: MediaQuery.of(context).size.width - 32,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).translate("reboot-calender"),
                style: TextStyles.h6.copyWith(
                  color: theme.grey[900],
                ),
              ),
              verticalSpace(Spacing.points8),
              WidgetsContainer(
                backgroundColor: theme.backgroundColor,
                borderSide: BorderSide(
                  color: theme.grey[600]!,
                  width: 0.5,
                ),
                // boxShadow: Shadows.mainShadows,
                child: SfCalendar(
                  dataSource: _getCalendarDataSource(followUps),
                  view: CalendarView.month,
                  viewHeaderStyle: ViewHeaderStyle(
                    dayTextStyle: TextStyles.tinyBold,
                  ),
                  headerStyle: CalendarHeaderStyle(
                    backgroundColor: theme.calenderHeaderBackgound,
                    textAlign: TextAlign.center,
                    textStyle: TextStyles.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.grey[900],
                    ),
                  ),
                  todayHighlightColor: theme.primary[700],
                  monthViewSettings: MonthViewSettings(
                    showTrailingAndLeadingDates: false,
                    agendaStyle: AgendaStyle(
                      dayTextStyle: TextStyles.body,
                    ),
                    monthCellStyle: MonthCellStyle(
                      backgroundColor: theme.calenderHeaderBackgound,
                      textStyle: TextStyles.footnoteSelected
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  onViewChanged: (viewChangedDetails) {
                    final visibleDates = viewChangedDetails.visibleDates;
                    if (visibleDates.isNotEmpty) {
                      final firstVisibleDate = visibleDates.first;
                      ref
                          .read(calendarNotifierProvider.notifier)
                          .fetchFollowUpsForMonth(firstVisibleDate);
                    }
                  },
                  onTap: (date) {
                    var selectedDate = date.date;
                    if (selectedDate != null &&
                        selectedDate.isAfter(DateTime.now())) {
                      getErrorSnackBar(context, "future-date-message");
                    } else if (selectedDate != null &&
                        userFirstDate != null &&
                        selectedDate.isBefore(DateTime(userFirstDate.year,
                            userFirstDate.month, userFirstDate.day, 0, 0))) {
                      getErrorSnackBar(context, "past-date-message");
                    } else {
                      context.goNamed(RouteNames.dayOverview.name,
                          pathParameters: {'date': selectedDate.toString()});
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  _AppointmentDataSource _getCalendarDataSource(List<FollowUpModel> followUps) {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final followUpDates = followUps.map((followUp) => followUp.time).toSet();

    List<Appointment> appointments = [];

    bool hasFollowUpToday = followUpDates.any((date) =>
        date.year == now.year &&
        date.month == now.month &&
        date.day == now.day);

    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(now.year, now.month, i);
      if (date.isBefore(
          DateTime(userFirstDate.year, userFirstDate.month, userFirstDate.day)))
        continue;
      if (date.isAfter(now)) break; // Avoid adding anything after today's date
      if (!followUpDates.contains(date) && date != now) {
        if (date != now || !hasFollowUpToday) {
          appointments.add(Appointment(
            startTime: date,
            endTime: date.add(Duration(minutes: 10)),
            subject: 'No Follow-up',
            color: followUpColors[FollowUpType.none]!,
            startTimeZone: '',
            endTimeZone: '',
          ));
        }
      }
    }

    appointments.addAll(followUps.map((followUp) {
      final color = followUpColors[followUp.type]!;
      var appointment = Appointment(
        startTime: followUp.time,
        endTime: followUp.time,
        subject: followUp.type.name,
        color: color,
        startTimeZone: '',
        endTimeZone: '',
      );
      return appointment;
    }).toList());

    return _AppointmentDataSource(appointments);
  }
}

class _AppointmentDataSource extends CalendarDataSource {
  _AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }
}
