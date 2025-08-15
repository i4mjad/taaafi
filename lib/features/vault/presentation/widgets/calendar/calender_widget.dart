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
import 'package:reboot_app_3/features/vault/data/calendar/calendar_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/features/vault/data/models/follow_up_colors.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';

class CalenderWidget extends ConsumerStatefulWidget {
  const CalenderWidget({
    super.key,
  });

  @override
  _CalenderWidgetState createState() => _CalenderWidgetState();
}

class _CalenderWidgetState extends ConsumerState<CalenderWidget> {
  DateTime userFirstDate = DateTime.now();
  DateTime? _currentMonth; // Track current month to prevent redundant fetches
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_isInitialized) {
        _isInitialized = true;
        // Delay provider modifications to avoid build cycle issues
        Future(() async {
          final now = DateTime.now();
          userFirstDate = await ref
              .read(calendarNotifierProvider.notifier)
              .getUserFirstDate();
          _currentMonth = DateTime(now.year, now.month); // Set initial month
          await ref
              .read(calendarNotifierProvider.notifier)
              .fetchFollowUpsForMonth(now);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final followUpState = ref.watch(calendarNotifierProvider);

    return followUpState.when(
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
                      final newMonth = DateTime(
                          firstVisibleDate.year, firstVisibleDate.month);

                      // Only fetch if month actually changed and we're initialized
                      if (_isInitialized &&
                          (_currentMonth == null ||
                              _currentMonth!.year != newMonth.year ||
                              _currentMonth!.month != newMonth.month)) {
                        _currentMonth = newMonth;
                        // Use microtask instead of Future to be more efficient
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            ref
                                .read(calendarNotifierProvider.notifier)
                                .fetchFollowUpsForMonth(firstVisibleDate);
                          }
                        });
                      }
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
                      final currentLanguage =
                          AppLocalizations.of(context).locale.languageCode;
                      final formattedFirstDate =
                          getDisplayDate(userFirstDate, currentLanguage);
                      final baseMessage = AppLocalizations.of(context)
                          .translate("past-date-message");
                      final messageWithDate =
                          "$baseMessage\n${AppLocalizations.of(context).translate("start-date")}: $formattedFirstDate";
                      getSystemSnackBar(context, messageWithDate);
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

    // Group follow-ups by date (ignoring time) to check which dates have follow-ups
    final followUpDates = <DateTime>{};
    for (final followUp in followUps) {
      followUpDates.add(
          DateTime(followUp.time.year, followUp.time.month, followUp.time.day));
    }

    final appointments = <Appointment>[];

    // Add green dots for empty days before today (clean days)
    for (var date = startDate;
        date.isBefore(today);
        date = date.add(Duration(days: 1))) {
      if (!followUpDates.contains(date)) {
        final appointmentDate = DateTime(date.year, date.month, date.day, 12);
        appointments.add(Appointment(
          startTime: appointmentDate,
          endTime: appointmentDate.add(Duration(hours: 1)),
          subject: 'Clean Day',
          color: followUpColors[FollowUpType.none]!,
          startTimeZone: '',
          endTimeZone: '',
        ));
      }
    }

    // Add actual follow-ups
    appointments.addAll(followUps.map((followUp) {
      // Normalize the date to avoid timezone issues
      final appointmentDate = DateTime(
        followUp.time.year,
        followUp.time.month,
        followUp.time.day,
        12, // Set to noon to avoid timezone edge cases
      );

      return Appointment(
        startTime: appointmentDate,
        endTime: appointmentDate.add(Duration(hours: 1)),
        subject: _getSubjectForType(followUp.type),
        color: followUpColors[followUp.type]!,
        startTimeZone: '',
        endTimeZone: '',
      );
    }));

    return _AppointmentDataSource(appointments);
  }

  /// Get a user-friendly subject for the appointment based on follow-up type
  String _getSubjectForType(FollowUpType type) {
    switch (type) {
      case FollowUpType.none:
        return 'Clean Day';
      case FollowUpType.slipUp:
        return 'Slip Up';
      case FollowUpType.relapse:
        return 'Relapse';
      case FollowUpType.pornOnly:
        return 'Porn Only';
      case FollowUpType.mastOnly:
        return 'Masturbation Only';
    }
  }
}

class _AppointmentDataSource extends CalendarDataSource {
  _AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }
}
