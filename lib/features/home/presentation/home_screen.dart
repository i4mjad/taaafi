import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:time_picker_spinner_pop_up/time_picker_spinner_pop_up.dart';

class HomeScreen extends ConsumerWidget {
  HomeScreen({super.key});

  List<Widget> children = [
    WidgetsContainer(
      child: Text("data"),
    ),
    WidgetsContainer(
      child: Text("data"),
    ),
  ];
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, 'home', false, true),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              StatisticsWidget(),
              verticalSpace(Spacing.points16),
              CalenderWidget()
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
          backgroundColor: theme.primary[600],
          onPressed: () {
            showModalBottomSheet<void>(
                context: context,
                builder: (BuildContext context) {
                  return FollowUpSheet();
                });
          },
          label: Text(
            AppLocalizations.of(context).translate("daily-follow-up"),
            style: TextStyles.caption.copyWith(color: theme.grey[50]),
          ),
          icon: Icon(LucideIcons.pencil, color: theme.grey[50])),
    );
  }
}

class FollowUpSheet extends ConsumerStatefulWidget {
  const FollowUpSheet({super.key});

  @override
  _FollowUpSheetState createState() => _FollowUpSheetState();
}

class _FollowUpSheetState extends ConsumerState<FollowUpSheet> {
  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeNotifierProvider);
    final theme = AppTheme.of(context);
    final width = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.all(16),
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TimePickerSpinnerPopUp(
                mode: CupertinoDatePickerMode.dateAndTime,
                barrierColor: theme.primary[50]!,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                locale: locale,
                cancelTextStyle:
                    TextStyles.caption.copyWith(color: theme.primary[600]),
                confirmTextStyle:
                    TextStyles.caption.copyWith(color: theme.primary[600]),
                timeFormat: "d - MMMM - yyyy hh:mm a",
                timeWidgetBuilder: (dateTime) {
                  return WidgetsContainer(
                    padding: EdgeInsets.all(8),
                    backgroundColor: theme.primary[50],
                    borderSide:
                        BorderSide(color: theme.primary[100]!, width: 0.75),
                    borderRadius: BorderRadius.circular(8),
                    child: Text(
                      getDisplayDateTime(dateTime, locale!.languageCode),
                      style: TextStyles.body,
                    ),
                  );
                },
                cancelText: AppLocalizations.of(context).translate("cancel"),
                confirmText: AppLocalizations.of(context).translate("confirm"),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Icon(
                  LucideIcons.xCircle,
                ),
              )
            ],
          ),
          Spacer(),
          Row(
            children: [
              Expanded(
                child: WidgetsContainer(
                  backgroundColor: theme.primary[600],
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context).translate('save'),
                      style: TextStyles.h6.copyWith(color: theme.grey[50]),
                    ),
                  ),
                ),
              ),
              horizontalSpace(Spacing.points8),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: WidgetsContainer(
                    backgroundColor: theme.secondary[50],
                    padding: EdgeInsets.all(16),
                    borderSide: BorderSide(color: theme.secondary[200]!),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context).translate('cancel'),
                        style: TextStyles.h6.copyWith(
                          color: theme.secondary[900],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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

class StatisticsWidget extends StatelessWidget {
  const StatisticsWidget({
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
            AppLocalizations.of(context).translate("statistics"),
            style: TextStyles.h6.copyWith(color: theme.grey[900]),
          ),
          verticalSpace(Spacing.points8),
          IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 1,
                  child: WidgetsContainer(
                    padding: EdgeInsets.all(20),
                    backgroundColor: theme.primary[50],
                    borderSide: BorderSide(color: theme.primary[100]!),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                                color: theme.primary[200]!, width: 1),
                          ),
                          child: Icon(
                            LucideIcons.heart,
                            color: theme.primary[600],
                            size: 20,
                          ),
                        ),
                        verticalSpace(Spacing.points8),
                        Text(
                            "28" +
                                " " +
                                AppLocalizations.of(context).translate("day"),
                            style: TextStyles.h6),
                        verticalSpace(Spacing.points8),
                        Text(
                          AppLocalizations.of(context)
                              .translate("current-streak"),
                          style: TextStyles.small,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                horizontalSpace(Spacing.points8),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      WidgetsContainer(
                        padding: EdgeInsets.all(12),
                        backgroundColor: theme.primary[50],
                        borderSide: BorderSide(color: theme.primary[100]!),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                    color: theme.tint[200]!, width: 1),
                              ),
                              child: Icon(
                                LucideIcons.lineChart,
                                color: theme.tint[600],
                                size: 20,
                              ),
                            ),
                            horizontalSpace(Spacing.points8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                    "28" +
                                        " " +
                                        AppLocalizations.of(context)
                                            .translate("day"),
                                    style: TextStyles.h6),
                                verticalSpace(Spacing.points8),
                                Text(
                                  AppLocalizations.of(context)
                                      .translate("highest-streak"),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyles.small,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      verticalSpace(Spacing.points8),
                      WidgetsContainer(
                        padding: EdgeInsets.all(12),
                        backgroundColor: theme.primary[50],
                        borderSide: BorderSide(color: theme.primary[100]!),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                    color: theme.success[200]!, width: 1),
                              ),
                              child: Icon(
                                LucideIcons.calendar,
                                color: theme.success[600],
                                size: 20,
                              ),
                            ),
                            horizontalSpace(Spacing.points8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                    "28" +
                                        " " +
                                        AppLocalizations.of(context)
                                            .translate("day"),
                                    style: TextStyles.h6),
                                verticalSpace(Spacing.points8),
                                Text(
                                  AppLocalizations.of(context)
                                      .translate("free-days-from-start"),
                                  style: TextStyles.small,
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
