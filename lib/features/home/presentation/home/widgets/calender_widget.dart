import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
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
            backgroundColor: theme.backgroundColor,
            borderSide: BorderSide(
              color: theme.grey[600]!,
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(60, 64, 67, 0.3),
                blurRadius: 2,
                spreadRadius: 0,
                offset: Offset(
                  0,
                  1,
                ),
              ),
              BoxShadow(
                color: Color.fromRGBO(60, 64, 67, 0.15),
                blurRadius: 6,
                spreadRadius: 2,
                offset: Offset(
                  0,
                  2,
                ),
              ),
            ],
            child: SfCalendar(
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
              todayHighlightColor: theme.primary[900],
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
              onTap: (date) {
                var selectedDate = date.date;
                context.go('/home/dayOverview/${selectedDate}');
              },
            ),
          ),
        ],
      ),
    );
  }
}
