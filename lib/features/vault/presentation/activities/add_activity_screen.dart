import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:go_router/go_router.dart';

import 'package:reboot_app_3/features/vault/data/activities/activity.dart';

class AddActivityScreen extends ConsumerWidget {
  const AddActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    var activities = [
      Activity(
        "1",
        "تسلق الجبال",
        Difficulties.hard,
        "نشاط يتطلب قوة بدنية وقدرة على التحمل، حيث يتم تسلق الجبال العالية.",
        DateTime(2024, 4, 15),
        [UsersLevels.starter, UsersLevels.intermediate, UsersLevels.advanced],
      ),
      Activity(
        "2",
        "اليوغا",
        Difficulties.medium,
        "تمارين جسدية وذهنية تركز على التنفس، القوة، والمرونة.",
        DateTime(2024, 4, 20),
        [UsersLevels.starter, UsersLevels.intermediate],
      ),
      Activity(
        "3",
        "السباحة",
        Difficulties.easy,
        "نشاط رياضي يساعد في تحسين اللياقة البدنية وتقوية العضلات.",
        DateTime(2024, 4, 22),
        [
          UsersLevels.starter,
          UsersLevels.intermediate,
          UsersLevels.advanced,
          UsersLevels.expert
        ],
      ),
      Activity(
        "4",
        "ركوب الدراجة",
        Difficulties.medium,
        "نشاط ممتع يساعد في تقوية عضلات الساقين وتحسين اللياقة البدنية.",
        DateTime(2024, 4, 25),
        [UsersLevels.starter, UsersLevels.intermediate, UsersLevels.advanced],
      ),
    ];

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, "add-activity", false, true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: width,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemBuilder: (BuildContext context, int index) {
                      return ActivitiyWidget(
                        index + 1,
                        activities[index],
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) =>
                        verticalSpace(Spacing.points8),
                    itemCount: activities.length,
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ActivitiyWidget extends ConsumerWidget {
  const ActivitiyWidget(
    this.order,
    this.activity, {
    super.key,
  });

  final int order;
  final Activity activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final locale = ref.watch(localeNotifierProvider);
    return GestureDetector(
      onTap: () {
        context.goNamed(RouteNames.activityOverview.name,
            pathParameters: {"id": activity.id});
      },
      child: WidgetsContainer(
        backgroundColor: theme.backgroundColor,
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
        borderSide: BorderSide(color: theme.grey[600]!, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(50, 50, 93, 0.25),
            blurRadius: 5,
            spreadRadius: -1,
            offset: Offset(
              0,
              2,
            ),
          ),
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.3),
            blurRadius: 3,
            spreadRadius: -1,
            offset: Offset(
              0,
              1,
            ),
          ),
        ],
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              order.toString(),
              style: TextStyles.h6.copyWith(color: theme.grey[900]),
            ),
            horizontalSpace(Spacing.points16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.name,
                  style: TextStyles.footnoteSelected.copyWith(
                    color: theme.grey[900],
                  ),
                ),
                verticalSpace(Spacing.points4),
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context).translate('activity-level'),
                      style: TextStyles.small.copyWith(color: theme.grey[700]),
                    ),
                    Text(
                      AppLocalizations.of(context)
                          .translate(activity.difficulty.name),
                      style: TextStyles.smallBold.copyWith(
                        color: _getDifficultyColor(activity.difficulty, theme),
                      ),
                    ),
                  ],
                ),
                verticalSpace(Spacing.points4),
                Row(
                  children: [
                    Wrap(
                      spacing: 4,
                      children: activity.levels.map(
                        (level) {
                          return WidgetsContainer(
                            borderRadius: BorderRadius.circular(8),
                            padding: EdgeInsets.fromLTRB(8, 2, 8, 2),
                            child: Text(
                              AppLocalizations.of(context)
                                  .translate(level.name),
                              style: TextStyles.tiny.copyWith(
                                color: getTextColorForUserLevel(level, theme),
                              ),
                            ),
                            backgroundColor:
                                getBackgroundColorForUserLevel(level, theme),
                            borderSide: BorderSide(
                              color: getBorderColorForUserLevel(level, theme),
                            ),
                          );
                        },
                      ).toList(),
                    ),
                  ],
                ),
              ],
            ),
            Spacer(),
            Icon(
              locale!.languageCode == 'en'
                  ? LucideIcons.chevronRight
                  : LucideIcons.chevronLeft,
              color: theme.grey[500],
            ),
          ],
        ),
      ),
    );
  }

  Color getBackgroundColorForUserLevel(
      UsersLevels level, CustomThemeData theme) {
    switch (level) {
      // case UsersLevels.starter:
      //   return theme.success[50]!;
      // case UsersLevels.intermediate:
      //   return theme.warn[200]!;
      // case UsersLevels.advanced:
      //   return theme.tint[50]!;
      // case UsersLevels.expert:
      //   return theme.error[50]!;
      default:
        return theme.primary[50]!;
    }
  }

  Color getBorderColorForUserLevel(UsersLevels level, CustomThemeData theme) {
    switch (level) {
      // case UsersLevels.starter:
      //   return theme.success[100]!;
      // case UsersLevels.intermediate:
      //   return theme.warn[100]!;
      // case UsersLevels.advanced:
      //   return theme.tint[100]!;
      // case UsersLevels.expert:
      //   return theme.error[100]!;
      default:
        return theme.grey[300]!;
    }
  }

  Color getTextColorForUserLevel(UsersLevels level, CustomThemeData theme) {
    switch (level) {
      case UsersLevels.starter:
        return theme.success[900]!; // Light green for starter
      case UsersLevels.intermediate:
        return theme.tint[900]!; // Light orange for advanced
      case UsersLevels.advanced:
        return theme.warn[900]!; // Light blue for intermediate
      case UsersLevels.expert:
        return theme.error[900]!; // Light red for expert
      default:
        return theme.grey[900]!; // Default color
    }
  }

  _getDifficultyColor(Difficulties difficulty, CustomThemeData theme) {
    switch (difficulty) {
      case Difficulties.easy:
        return theme.success[700];
      case Difficulties.medium:
        return theme.warn[500];
      case Difficulties.hard:
        return theme.error[800];
      default:
        return theme.grey[700];
    }
  }
}
