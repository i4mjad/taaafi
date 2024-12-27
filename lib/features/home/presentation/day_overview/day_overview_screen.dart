import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

import 'package:reboot_app_3/features/home/data/emotion_notifier.dart';
import 'package:reboot_app_3/features/home/data/follow_up_notifier.dart';
import 'package:reboot_app_3/features/home/data/models/emotion_model.dart';
import 'package:reboot_app_3/features/home/data/models/follow_up_colors.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/follow_up_sheet.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';

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
    final followUpsStream =
        ref.watch(followUpNotifierProvider.notifier).watchFollowUpsByDate(date);
    final emotionsStream =
        ref.watch(emotionNotifierProvider.notifier).watchEmotionsByDate(date);

    return Scaffold(
      appBar: plainAppBar(context, ref,
          getDisplayDate(date, locale!.languageCode), false, true),
      backgroundColor: theme.backgroundColor,
      body: SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(context).size.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              StreamBuilder<List<FollowUpModel>>(
                stream: followUpsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  } else if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(child: Text('Error: ${snapshot.error}')),
                    );
                  } else {
                    final followUps = snapshot.data ?? [];

                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: DayFollowUps(date: date, followUps: followUps),
                    );
                  }
                },
              ),
              verticalSpace(Spacing.points32),
              Padding(
                padding: const EdgeInsets.all(16),
                child: DayNotes(date: date),
              ),
              verticalSpace(Spacing.points32),
              StreamBuilder<List<EmotionModel>>(
                stream: emotionsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  } else if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(child: Text('Error: ${snapshot.error}')),
                    );
                  } else {
                    final emotions = snapshot.data ?? [];
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: DayEmotions(date: date, emotions: emotions),
                    );
                  }
                },
              ),
            ],
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
    required this.emotions,
  });

  final DateTime date;
  final List<EmotionModel> emotions;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('emotions'),
          style: TextStyles.h6,
        ),
        verticalSpace(Spacing.points12),
        if (emotions.isEmpty)
          Column(
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
                  backgroundColor: theme.backgroundColor,
                  borderSide: BorderSide(color: theme.grey[900]!, width: 0.25),
                  boxShadow: Shadows.mainShadows,
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context).translate('add-emotions'),
                      style: TextStyles.h6.copyWith(
                        color: theme.secondary[600],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, int index) {
              final emotion = emotions[index];
              return GestureDetector(
                onTap: () {
                  showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (BuildContext context) {
                        return EditEmotion(emotion: emotion);
                      });
                },
                child: EmotionDailyRecordWidget(
                  dailyRecord: DailyRecord(
                    emotion.id,
                    emotion.emotionEmoji,
                    emotion.emotionName,
                    emotion.date,
                  ),
                ),
              );
            },
            separatorBuilder: (BuildContext context, int index) =>
                verticalSpace(Spacing.points8),
            itemCount: emotions.length,
          ),
      ],
    );
  }
}

class DayFollowUps extends StatelessWidget {
  const DayFollowUps({
    super.key,
    required this.date,
    required this.followUps,
  });

  final DateTime date;
  final List<FollowUpModel> followUps;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('day-overview'),
          style: TextStyles.h6,
        ),
        verticalSpace(Spacing.points12),
        if (followUps.isEmpty)
          Column(
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
                  backgroundColor: theme.backgroundColor,
                  borderSide: BorderSide(color: theme.grey[900]!, width: 0.25),
                  boxShadow: Shadows.mainShadows,
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context).translate('add-follow-ups'),
                      style: TextStyles.h6.copyWith(color: theme.primary[600]),
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, int index) {
              final followUp = followUps[index];
              return GestureDetector(
                onTap: () {
                  showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (BuildContext context) {
                        return EditFollowUp(followUp: followUp);
                      });
                },
                child: DailyRecordWidget(
                  dailyRecord: DailyRecord(
                    followUp.id,
                    (index + 1).toString(),
                    followUp.type.name,
                    followUp.time,
                  ),
                ),
              );
            },
            separatorBuilder: (BuildContext context, int index) =>
                verticalSpace(Spacing.points8),
            itemCount: followUps.length,
          ),
      ],
    );
  }
}

class EditFollowUp extends ConsumerWidget {
  const EditFollowUp({super.key, required this.followUp});

  final FollowUpModel followUp;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.20,
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).translate('edit-follow-up'),
              style: TextStyles.h6,
            ),
            // verticalSpace(Spacing.points16),
            Spacer(),
            GestureDetector(
              onTap: () {
                ref
                    .read(followUpNotifierProvider.notifier)
                    .deleteFollowUp(followUp.id);

                HapticFeedback.mediumImpact();
                context.pop();
              },
              child: WidgetsContainer(
                backgroundColor: theme.backgroundColor,
                borderSide: BorderSide(color: theme.grey[900]!, width: 0.25),
                boxShadow: Shadows.mainShadows,
                child: Center(
                  child: Text(
                    AppLocalizations.of(context).translate('delete-follow-up'),
                    style: TextStyles.h6.copyWith(
                      color: theme.error[600],
                    ),
                  ),
                ),
              ),
            ),
            verticalSpace(Spacing.points8),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.pop();
              },
              child: WidgetsContainer(
                backgroundColor: theme.backgroundColor,
                borderSide: BorderSide(color: theme.grey[900]!, width: 0.25),
                boxShadow: Shadows.mainShadows,
                child: Center(
                  child: Text(
                    AppLocalizations.of(context).translate('close'),
                    style: TextStyles.h6.copyWith(
                      color: theme.grey[600],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditEmotion extends ConsumerWidget {
  const EditEmotion({super.key, required this.emotion});

  final EmotionModel emotion;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.20,
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).translate('edit-emotion'),
              style: TextStyles.h6,
            ),
            // verticalSpace(Spacing.points16),
            Spacer(),
            GestureDetector(
              onTap: () {
                ref
                    .read(emotionNotifierProvider.notifier)
                    .deleteEmotion(emotion.id);

                HapticFeedback.mediumImpact();
                context.pop();
              },
              child: WidgetsContainer(
                backgroundColor: theme.backgroundColor,
                borderSide: BorderSide(color: theme.grey[900]!, width: 0.25),
                boxShadow: Shadows.mainShadows,
                child: Center(
                  child: Text(
                    AppLocalizations.of(context).translate('delete-follow-up'),
                    style: TextStyles.h6.copyWith(
                      color: theme.error[600],
                    ),
                  ),
                ),
              ),
            ),
            verticalSpace(Spacing.points8),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.pop();
              },
              child: WidgetsContainer(
                backgroundColor: theme.backgroundColor,
                borderSide: BorderSide(color: theme.grey[900]!, width: 0.25),
                boxShadow: Shadows.mainShadows,
                child: Center(
                  child: Text(
                    AppLocalizations.of(context).translate('close'),
                    style: TextStyles.h6.copyWith(
                      color: theme.grey[600],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
      padding: EdgeInsets.all(12),
      backgroundColor: theme.backgroundColor,
      boxShadow: Shadows.mainShadows,
      borderSide: BorderSide(width: 0.25, color: theme.grey[100]!),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: followUpNamesColors[dailyRecord.title]!,
              shape: BoxShape.circle,
            ),
          ),
          horizontalSpace(Spacing.points12),
          Text(
            AppLocalizations.of(context).translate(dailyRecord.title),
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

class NoteDailyRecordWidget extends ConsumerWidget {
  const NoteDailyRecordWidget({super.key, required this.dailyRecord});

  final DailyRecord dailyRecord;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final locale = ref.watch(localeNotifierProvider);
    return WidgetsContainer(
      padding: EdgeInsets.all(12),
      backgroundColor: theme.backgroundColor,
      boxShadow: Shadows.mainShadows,
      borderSide: BorderSide(width: 0.25, color: theme.grey[100]!),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: followUpNamesColors[dailyRecord.title]!,
              shape: BoxShape.circle,
            ),
          ),
          horizontalSpace(Spacing.points12),
          Text(
            AppLocalizations.of(context).translate(dailyRecord.title),
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

class EmotionDailyRecordWidget extends ConsumerWidget {
  const EmotionDailyRecordWidget({super.key, required this.dailyRecord});

  final DailyRecord dailyRecord;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final locale = ref.watch(localeNotifierProvider);
    return WidgetsContainer(
      padding: EdgeInsets.all(12),
      backgroundColor: theme.backgroundColor,
      boxShadow: Shadows.mainShadows,
      borderSide: BorderSide(width: 0.25, color: theme.grey[100]!),
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
            AppLocalizations.of(context).translate(dailyRecord.title),
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
      DailyRecord("", "1", 'يوميات', date),
      DailyRecord("", "2", 'تأملات', date),
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
                    backgroundColor: theme.backgroundColor,
                    borderSide:
                        BorderSide(color: theme.grey[900]!, width: 0.25),
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(9, 30, 66, 0.25),
                        blurRadius: 8,
                        spreadRadius: -2,
                        offset: Offset(
                          0,
                          4,
                        ),
                      ),
                      BoxShadow(
                        color: Color.fromRGBO(9, 30, 66, 0.08),
                        blurRadius: 0,
                        spreadRadius: 1,
                        offset: Offset(
                          0,
                          0,
                        ),
                      ),
                    ],
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context).translate('add-note'),
                        style: TextStyles.h6.copyWith(color: theme.tint[700]),
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
                return NoteDailyRecordWidget(
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
