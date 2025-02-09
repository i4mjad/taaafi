import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/features/home/data/statistics_notifier.dart';
import 'package:reboot_app_3/features/home/data/streak_notifier.dart';
import 'package:reboot_app_3/features/home/presentation/home/statistics_visibility_notifier.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';
import 'package:reboot_app_3/features/home/data/models/follow_up_colors.dart';

class StatisticsWidget extends ConsumerStatefulWidget {
  const StatisticsWidget({
    super.key,
  });

  @override
  _StatisticsWidgetState createState() => _StatisticsWidgetState();
}

class _StatisticsWidgetState extends ConsumerState<StatisticsWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);

    final locale = ref.watch(localeNotifierProvider);
    final streaksState = ref.watch(streakNotifierProvider);

    return Container(
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          verticalSpace(Spacing.points16),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localization.translate("statistics"),
                  style: TextStyles.h6.copyWith(color: theme.grey[900]),
                ),
              ],
            ),
          ),
          verticalSpace(Spacing.points4),
          verticalSpace(Spacing.points4),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0, left: 16),
                child: Text(
                  localization.translate("starting-date") +
                      ": " +
                      (streaksState.value?.userFirstDate != null
                          ? getDisplayDateTime(
                              streaksState.value!.userFirstDate,
                              locale!.languageCode)
                          : "")
                  // getDisplayDateTime(
                  //     data.userFirstDate, locale!.languageCode),,
                  ,
                  style: TextStyles.small.copyWith(color: theme.grey[400]),
                ),
              ),
              Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 16.0, left: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(2, (index) {
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 4.0),
                      width: 8.0,
                      height: 8.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? theme.primary[700]
                            : theme.grey[400],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          verticalSpace(Spacing.points4),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.15,
            child: PageView.builder(
              clipBehavior: Clip.none,
              controller: _pageController,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemCount: 2,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(left: 16, right: 16),
                  child: index == 0 ? _FirstPageWidget() : _SecondPageWidget(),
                );
              },
            ),
          ),
          verticalSpace(Spacing.points16),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 16),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.heavyImpact();
                showModalBottomSheet(
                  context: context,
                  builder: (context) => InformationSheet(),
                );
              },
              child: WidgetsContainer(
                padding: EdgeInsets.all(8),
                borderRadius: BorderRadius.circular(8),
                backgroundColor: theme.backgroundColor,
                borderSide: BorderSide(color: theme.grey[600]!, width: 0.25),
                child: Center(
                  child: Text(
                    localization.translate("what-is-all-of-those"),
                    style: TextStyles.small.copyWith(color: theme.primary[500]),
                    textAlign: TextAlign.center,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FirstPageWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);
    final streakState = ref.watch(streakNotifierProvider);
    final visibilitySettings = ref.watch(statisticsVisibilityProvider);

    return streakState.when(
      data: (data) {
        return Row(
          children: [
            if (visibilitySettings['relapse']!)
              Expanded(
                child: WidgetsContainer(
                  padding: EdgeInsets.all(12),
                  backgroundColor: theme.backgroundColor,
                  borderSide: BorderSide(
                      color: followUpColors[FollowUpType.relapse]!,
                      width: 0.75),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${data.relapseStreak}",
                        style: TextStyles.h6,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        localization.translate("day"),
                        style: TextStyles.h6,
                        textAlign: TextAlign.center,
                      ),
                      verticalSpace(Spacing.points4),
                      Text(
                        localization.translate("current-streak"),
                        textAlign: TextAlign.center,
                        style: TextStyles.small,
                      ),
                    ],
                  ),
                ),
              ),
            if (visibilitySettings['relapse']! &&
                (visibilitySettings['pornOnly']! ||
                    visibilitySettings['mastOnly']! ||
                    visibilitySettings['slipUp']!))
              horizontalSpace(Spacing.points8),
            if (visibilitySettings['pornOnly']!)
              Expanded(
                child: WidgetsContainer(
                  padding: EdgeInsets.all(12),
                  backgroundColor: theme.backgroundColor,
                  borderSide: BorderSide(
                      color: followUpColors[FollowUpType.pornOnly]!,
                      width: 0.75),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${data.pornOnlyStreak}",
                        style: TextStyles.h6,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        localization.translate("day"),
                        style: TextStyles.h6,
                        textAlign: TextAlign.center,
                      ),
                      verticalSpace(Spacing.points4),
                      Text(
                        localization.translate("free-porn-days"),
                        style: TextStyles.small,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            if (visibilitySettings['pornOnly']! &&
                (visibilitySettings['mastOnly']! ||
                    visibilitySettings['slipUp']!))
              horizontalSpace(Spacing.points8),
            if (visibilitySettings['mastOnly']!)
              Expanded(
                child: WidgetsContainer(
                  padding: EdgeInsets.all(12),
                  backgroundColor: theme.backgroundColor,
                  borderSide: BorderSide(
                      color: followUpColors[FollowUpType.mastOnly]!,
                      width: 0.75),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${data.mastOnlyStreak}",
                        style: TextStyles.h6,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        localization.translate("day"),
                        style: TextStyles.h6,
                        textAlign: TextAlign.center,
                      ),
                      verticalSpace(Spacing.points4),
                      Text(
                        localization.translate("free-mast-days"),
                        style: TextStyles.small,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            if (visibilitySettings['mastOnly']! &&
                visibilitySettings['slipUp']!)
              horizontalSpace(Spacing.points8),
            if (visibilitySettings['slipUp']!)
              Expanded(
                child: WidgetsContainer(
                  padding: EdgeInsets.all(12),
                  backgroundColor: theme.backgroundColor,
                  borderSide: BorderSide(
                      color: followUpColors[FollowUpType.slipUp]!, width: 0.75),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${data.slipUpStreak}",
                        style: TextStyles.h6,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        localization.translate("day"),
                        style: TextStyles.h6,
                        textAlign: TextAlign.center,
                      ),
                      verticalSpace(Spacing.points4),
                      Text(
                        localization.translate("slip-up"),
                        style: TextStyles.small,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => Center(
          child: CircularProgressIndicator(
        color: theme.grey[100],
      )),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}

class _SecondPageWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);
    final statisticsState = ref.watch(statisticsNotifierProvider);

    return statisticsState.when(
      data: (data) {
        return IntrinsicHeight(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            // crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: WidgetsContainer(
                  padding: EdgeInsets.all(16),
                  backgroundColor: theme.backgroundColor,
                  borderSide: BorderSide(color: theme.grey[600]!, width: 0.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.heart,
                        color: theme.primary[600],
                        size: 25,
                      ),
                      verticalSpace(Spacing.points8),
                      Text(
                          "${data.daysWithoutRelapse} " +
                              localization.translate("day"),
                          style: TextStyles.h6),
                      verticalSpace(Spacing.points8),
                      Text(
                        localization.translate("free-days-from-start"),
                        style: TextStyles.small,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              horizontalSpace(Spacing.points8),
              Expanded(
                child: WidgetsContainer(
                  padding: EdgeInsets.all(16),
                  backgroundColor: theme.backgroundColor,
                  borderSide: BorderSide(color: theme.grey[600]!, width: 0.5),
                  // boxShadow: Shadows.mainShadows,
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.lineChart,
                        size: 25,
                        color: theme.primary[600],
                      ),
                      verticalSpace(Spacing.points8),
                      Text(
                          "${data.longestRelapseStreak} " +
                              localization.translate("day"),
                          style: TextStyles.h6),
                      verticalSpace(Spacing.points8),
                      Text(
                        localization.translate("highest-streak"),
                        style: TextStyles.small,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              horizontalSpace(Spacing.points8),
              Expanded(
                child: WidgetsContainer(
                  padding: EdgeInsets.all(16),
                  backgroundColor: theme.backgroundColor,
                  borderSide: BorderSide(color: theme.grey[600]!, width: 0.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.calendarRange,
                        size: 25,
                        color: theme.primary[600],
                      ),
                      verticalSpace(Spacing.points8),
                      Text(
                          "${data.relapsesInLast30Days} " +
                              localization.translate("relapse"),
                          style: TextStyles.h6),
                      verticalSpace(Spacing.points8),
                      Text(
                        localization.translate("relapses-30-days"),
                        style: TextStyles.small,
                        textAlign: TextAlign.center,
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Center(
          child: CircularProgressIndicator(
        color: theme.grey[100],
      )),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}

class InformationSection extends StatelessWidget {
  final String title;
  final String description;
  final Color? dotColor;

  const InformationSection({
    super.key,
    required this.title,
    required this.description,
    this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: dotColor ?? theme.primary[600],
            shape: BoxShape.circle,
          ),
        ),
        horizontalSpace(Spacing.points8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).translate(title),
                style: TextStyles.footnoteSelected,
              ),
              verticalSpace(Spacing.points4),
              Text(
                AppLocalizations.of(context).translate(description),
                style: TextStyles.small,
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class InformationSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);

    return Container(
      color: theme.backgroundColor,
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                localization.translate("home"),
                style: TextStyles.h6,
              ),
              Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Icon(
                  LucideIcons.xCircle,
                  size: 24,
                  color: theme.grey[600],
                ),
              )
            ],
          ),
          verticalSpace(Spacing.points16),
          InformationSection(
            title: "relapse",
            description: "what-is-relapse",
            dotColor: followUpColors[FollowUpType.relapse],
          ),
          verticalSpace(Spacing.points16),
          InformationSection(
            title: "slipUp",
            description: "what-is-slip-up",
            dotColor: followUpColors[FollowUpType.slipUp],
          ),
          verticalSpace(Spacing.points16),
          InformationSection(
            title: "porn-only",
            description: "what-is-no-porn",
            dotColor: followUpColors[FollowUpType.pornOnly],
          ),
          verticalSpace(Spacing.points16),
          InformationSection(
            title: "mast-only",
            description: "what-is-no-mast",
            dotColor: followUpColors[FollowUpType.mastOnly],
          ),
          Spacer(),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.backgroundColor,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: theme.grey[500]!,
                  width: 0.75,
                ),
                borderRadius: BorderRadius.circular(10.5),
              ),
            ),
            child: Text(
              localization.translate('close'),
              style: TextStyles.small.copyWith(
                color: theme.primary[600]!,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
