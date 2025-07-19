import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
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
      loading: () => Center(child: Spinner()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  _AppointmentDataSource _getCalendarDataSource(List<FollowUpModel> followUps) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate =
        DateTime(userFirstDate.year, userFirstDate.month, userFirstDate.day);

    // Group follow-ups by date (ignoring time)
    final followUpDates = followUps
        .map((followUp) => DateTime(
            followUp.time.year, followUp.time.month, followUp.time.day))
        .toSet();

    List<Appointment> appointments = [];

    // Add "none" appointments for dates without follow-ups
    for (var date = startDate;
        date.isBefore(today);
        date = date.add(Duration(days: 1))) {
      if (!followUpDates.contains(date)) {
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

    // Add actual follow-ups
    appointments.addAll(followUps.map((followUp) {
      return Appointment(
        startTime: followUp.time,
        endTime: followUp.time,
        subject: followUp.type.name,
        color: followUpColors[followUp.type]!,
        startTimeZone: '',
        endTimeZone: '',
      );
    }));

    return _AppointmentDataSource(appointments);
  }
}

class _AppointmentDataSource extends CalendarDataSource {
  _AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }
}
