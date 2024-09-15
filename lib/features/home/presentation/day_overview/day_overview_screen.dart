import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/home/data/models/daily_record.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/follow_up_sheet.dart';

class DayOverviewScreen extends ConsumerWidget {
  final DateTime date;

  const DayOverviewScreen({
    Key? key,
    required this.date,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeNotifierProvider);
    final theme = AppTheme.of(context);
    return Scaffold(
      appBar: plainAppBar(context, ref,
          getDisplayDate(date, locale!.languageCode), false, true),
      backgroundColor: theme.backgroundColor,
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width - 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                DayFollowUps(date: date),
                verticalSpace(Spacing.points32),
                DayNotes(date: date),
                verticalSpace(Spacing.points32),
                DayEmotions(date: date),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DayEmotions extends StatelessWidget {
  DayEmotions({
    super.key,
    required this.date,
  });

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    var records = [
      DailyRecord(
          "🧘‍♂️", AppLocalizations.of(context).translate('serenity'), date),
      DailyRecord("😄", AppLocalizations.of(context).translate('happy'), date),
      DailyRecord(
          "😇", AppLocalizations.of(context).translate('satisfaction'), date),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('emotions'),
          style: TextStyles.h6,
        ),
        verticalSpace(Spacing.points12),
        Builder(
          builder: (BuildContext context) {
            final noData = false;
            // ignore: dead_code
            if (noData) {
              return Column(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width - 32,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context).translate('no-emotions'),
                          style: TextStyles.footnote,
                        )
                      ],
                    ),
                  ),
                  verticalSpace(Spacing.points16),
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          builder: (BuildContext context) {
                            return FollowUpSheet(date);
                          });
                    },
                    child: WidgetsContainer(
                      backgroundColor: theme.secondary[100],
                      borderSide: BorderSide(color: theme.secondary[100]!),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)
                              .translate('add-emotions'),
                          style: TextStyles.h6.copyWith(
                            color: theme.secondary[900],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
              // ignore: dead_code
            } else {
              return ListView.separated(
                shrinkWrap:
                    true, // This makes the ListView take up only the needed space
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (BuildContext context, int index) {
                  return DailyRecordWidget(
                    dailyRecord: records[index],
                  );
                },
                separatorBuilder: (BuildContext context, int index) =>
                    verticalSpace(Spacing.points8),
                itemCount: records.length,
              );
            }
          },
        ),
      ],
    );
  }
}

class DailyRecordWidget extends ConsumerWidget {
  const DailyRecordWidget({super.key, required this.dailyRecord});

  final DailyRecord dailyRecord;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final locale = ref.watch(localeNotifierProvider);
    return WidgetsContainer(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10),
      backgroundColor: theme.primary[50],
      borderSide: BorderSide(color: theme.primary[100]!),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            dailyRecord.heading,
            style: TextStyles.h6.copyWith(color: theme.grey[900], fontSize: 18),
          ),
          horizontalSpace(Spacing.points12),
          Text(
            dailyRecord.title,
            style: TextStyles.bodyLarge.copyWith(color: theme.grey[800]),
          ),
          Spacer(),
          Text(
            getDisplayTime(dailyRecord.time, locale!.languageCode),
            style: TextStyles.footnoteSelected.copyWith(color: theme.grey[900]),
          ),
        ],
      ),
    );
  }
}

class DayNotes extends StatelessWidget {
  const DayNotes({
    super.key,
    required this.date,
  });

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    var records = [
      DailyRecord("1", 'يوميات', date),
      DailyRecord("2", 'تأملات', date),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('diaries'),
          style: TextStyles.h6,
        ),
        verticalSpace(Spacing.points12),
        Builder(builder: (BuildContext context) {
          final noData = true;
          // ignore: dead_code
          if (noData) {
            return Column(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width - 32,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context).translate('no-notes'),
                        style: TextStyles.footnote,
                      )
                    ],
                  ),
                ),
                verticalSpace(Spacing.points12),
                GestureDetector(
                  onTap: () => context.goNamed(RouteNames.diaries.name),
                  child: WidgetsContainer(
                    backgroundColor: theme.tint[100],
                    borderSide: BorderSide(color: theme.tint[100]!),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context).translate('add-note'),
                        style: TextStyles.h6.copyWith(color: theme.tint[900]),
                      ),
                    ),
                  ),
                ),
              ],
            );
            // ignore: dead_code
          } else {
            return ListView.separated(
              shrinkWrap:
                  true, // This makes the ListView take up only the needed space
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (BuildContext context, int index) {
                return DailyRecordWidget(
                  dailyRecord: records[index],
                );
              },
              separatorBuilder: (BuildContext context, int index) =>
                  verticalSpace(Spacing.points8),
              itemCount: records.length,
            );
          }
        }),

      ],
    );
  }
}

class DayFollowUps extends StatelessWidget {
  const DayFollowUps({
    super.key,
    required this.date,
  });

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    var records = [
      DailyRecord("1", AppLocalizations.of(context).translate('relapse'), date),
      DailyRecord("2", AppLocalizations.of(context).translate('slip-up'), date),
      DailyRecord(
          "3", AppLocalizations.of(context).translate('porn-only'), date),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('day-overview'),
          style: TextStyles.h6,
        ),
        verticalSpace(Spacing.points12),
        Builder(builder: (BuildContext context) {
          final noData = true;
          // ignore: dead_code
          if (noData) {
            return Column(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width - 32,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context).translate('no-follow-ups'),
                        style: TextStyles.footnote,
                      )
                    ],
                  ),
                ),
                verticalSpace(Spacing.points12),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (BuildContext context) {
                          return FollowUpSheet(date);
                        });
                  },
                  child: WidgetsContainer(
                    backgroundColor: theme.primary[100],
                    borderSide: BorderSide(color: theme.primary[100]!),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)
                            .translate('add-follow-ups'),
                        style:
                            TextStyles.h6.copyWith(color: theme.primary[900]),
                      ),
                    ),
                  ),
                ),
              ],
            );
            // ignore: dead_code
          } else {
            return ListView.separated(
              shrinkWrap:
                  true, // This makes the ListView take up only the needed space
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (BuildContext context, int index) {
                return DailyRecordWidget(
                  dailyRecord: records[index],
                );
              },
              separatorBuilder: (BuildContext context, int index) =>
                  verticalSpace(Spacing.points8),
              itemCount: records.length,
            );
          }
        }),
      ],
    );
  }
}
