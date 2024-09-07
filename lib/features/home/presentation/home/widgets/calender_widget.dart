import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalenderWidget extends StatelessWidget {
  const CalenderWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
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
            borderSide: BorderSide(color: theme.primary[100]!),
            backgroundColor: theme.primary[50],
            child: SfCalendar(
              view: CalendarView.month,
              viewHeaderStyle: ViewHeaderStyle(
                dayTextStyle: TextStyles.tinyBold,
              ),
              headerStyle: CalendarHeaderStyle(
                backgroundColor: theme.primary[100],
                textAlign: TextAlign.center,
                textStyle: TextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              todayHighlightColor: theme.primary[800],
              monthViewSettings: MonthViewSettings(
                showTrailingAndLeadingDates: false,
                agendaStyle: AgendaStyle(
                  dayTextStyle: TextStyles.body,
                ),
                monthCellStyle: MonthCellStyle(
                  todayBackgroundColor: theme.primary[100],
                  backgroundColor: theme.primary[50],
                  textStyle: TextStyles.caption,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
