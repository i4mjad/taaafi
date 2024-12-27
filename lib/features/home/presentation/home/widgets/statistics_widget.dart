import 'package:flutter/material.dart';
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0, left: 16),
                child: Text(
                  localization.translate("statistics"),
                  style: TextStyles.h6.copyWith(color: theme.grey[900]),
                ),
              ),
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
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 16),
            child: Text(
              localization.translate("starting-date") +
                  ": " +
                  (streaksState.value?.userFirstDate != null
                      ? getDisplayDateTime(streaksState.value!.userFirstDate,
                          locale!.languageCode)
                      : "")
              // getDisplayDateTime(
              //     data.userFirstDate, locale!.languageCode),,
              ,
              style: TextStyles.small.copyWith(color: theme.grey[400]),
            ),
          ),
          verticalSpace(Spacing.points4),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.17125,
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
    final streakState = ref.watch(streakStreamProvider);

    return streakState.when(
      data: (data) {
        return WidgetsContainer(
          padding: EdgeInsets.all(16),
          backgroundColor: theme.backgroundColor,
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: theme.grey[600]!, width: 0.5),
          boxShadow: Shadows.mainShadows,
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.backgroundColor,
                  boxShadow: Shadows.mainShadows,
                  shape: BoxShape.circle,
                  border: Border.all(
                    width: 0.5,
                    color: theme.grey[600]!,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${data.relapseStreak.toString()} ",
                      style: TextStyles.h5,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      localization.translate("day"),
                      style: TextStyles.h5,
                      textAlign: TextAlign.center,
                    ),
                    verticalSpace(Spacing.points8),
                    Flexible(
                      child: Text(
                        localization.translate("current-streak"),
                        textAlign: TextAlign.center,
                        style: TextStyles.small,
                      ),
                    ),
                  ],
                ),
              ),
              horizontalSpace(Spacing.points16),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: followUpColors[FollowUpType.pornOnly],
                              shape: BoxShape.circle,
                            ),
                          ),
                          horizontalSpace(Spacing.points4),
                          Text(
                            "${data.pornOnlyStreak.toString()} " +
                                localization.translate("day"),
                            style: TextStyles.h6,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      horizontalSpace(Spacing.points8),
                      Text(
                        localization.translate("free-porn-days"),
                        style: TextStyles.small,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: followUpColors[FollowUpType.mastOnly],
                              shape: BoxShape.circle,
                            ),
                          ),
                          horizontalSpace(Spacing.points4),
                          Text(
                            "${data.mastOnlyStreak.toString()} " +
                                localization.translate("day"),
                            style: TextStyles.h6,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      horizontalSpace(Spacing.points8),
                      Text(
                        localization.translate("free-mast-days"),
                        style: TextStyles.small,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: followUpColors[FollowUpType.slipUp],
                              shape: BoxShape.circle,
                            ),
                          ),
                          horizontalSpace(Spacing.points4),
                          Text(
                            "${data.slipUpStreak.toString()} " +
                                localization.translate("day"),
                            style: TextStyles.h6,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      horizontalSpace(Spacing.points8),
                      Text(
                        localization.translate("slip-up"),
                        style: TextStyles.small,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
              Spacer(),
              GestureDetector(
                onTap: () {
                  _showOnboardingModal(context);
                },
                child: Icon(LucideIcons.badgeInfo, color: theme.grey[400]),
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

  void _showOnboardingModal(BuildContext context) {
    final theme = AppTheme.of(context);
    showModalBottomSheet(
      backgroundColor: theme.backgroundColor,
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              verticalSpace(Spacing.points16),
              FollowupDescriptionSection(
                color: followUpColors[FollowUpType.relapse]!,
                title: AppLocalizations.of(context).translate("relapse"),
                description:
                    AppLocalizations.of(context).translate("what-is-relapse"),
              ),
              verticalSpace(Spacing.points16),
              FollowupDescriptionSection(
                color: followUpColors[FollowUpType.pornOnly]!,
                title: AppLocalizations.of(context).translate("porn-only"),
                description:
                    AppLocalizations.of(context).translate("what-is-no-porn"),
              ),
              verticalSpace(Spacing.points16),
              FollowupDescriptionSection(
                color: followUpColors[FollowUpType.mastOnly]!,
                title: AppLocalizations.of(context).translate("mast-only"),
                description:
                    AppLocalizations.of(context).translate("what-is-no-mast"),
              ),
              verticalSpace(Spacing.points16),
              FollowupDescriptionSection(
                color: followUpColors[FollowUpType.slipUp]!,
                title: AppLocalizations.of(context).translate("slip-up"),
                description:
                    AppLocalizations.of(context).translate("what-is-slip-up"),
              ),
              verticalSpace(Spacing.points16),
              Spacer(),
              Text(
                "المصدر" + ": " + "nofap.com",
                style: TextStyles.caption.copyWith(
                  color: theme.grey[600],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context).translate("close"),
                        style: TextStyles.body.copyWith(
                          color: theme.primary[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        );
      },
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 1,
                child: WidgetsContainer(
                  padding: EdgeInsets.all(16),
                  backgroundColor: theme.backgroundColor,
                  borderSide: BorderSide(color: theme.grey[600]!, width: 0.5),
                  boxShadow: Shadows.mainShadows,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          LucideIcons.heart,
                          size: 20,
                        ),
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
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    WidgetsContainer(
                      padding: EdgeInsets.all(14),
                      backgroundColor: theme.backgroundColor,
                      borderSide:
                          BorderSide(color: theme.grey[600]!, width: 0.5),
                      boxShadow: Shadows.mainShadows,
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(width: 1),
                            ),
                            child: Icon(
                              LucideIcons.lineChart,
                              size: 20,
                            ),
                          ),
                          horizontalSpace(Spacing.points8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                  "${data.longestRelapseStreak} " +
                                      localization.translate("day"),
                                  style: TextStyles.h6),
                              verticalSpace(Spacing.points8),
                              Text(
                                localization.translate("highest-streak"),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyles.small,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    WidgetsContainer(
                      padding: EdgeInsets.all(14),
                      backgroundColor: theme.backgroundColor,
                      borderSide:
                          BorderSide(color: theme.grey[600]!, width: 0.5),
                      boxShadow: Shadows.mainShadows,
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(width: 1),
                            ),
                            child: Icon(
                              LucideIcons.calendar,
                              size: 20,
                            ),
                          ),
                          horizontalSpace(Spacing.points8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                  "${data.totalDaysFromFirstDate} " +
                                      localization.translate("day"),
                                  style: TextStyles.h6),
                              verticalSpace(Spacing.points8),
                              Text(
                                localization.translate("total-days"),
                                overflow: TextOverflow.ellipsis,
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

class FollowupDescriptionSection extends StatelessWidget {
  const FollowupDescriptionSection({
    super.key,
    required this.color,
    required this.title,
    required this.description,
  });

  final Color color;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Container(
      padding: EdgeInsets.only(right: 32, left: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          horizontalSpace(Spacing.points16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyles.h6.copyWith(
                    color: theme.primary[600],
                  ),
                ),
                verticalSpace(Spacing.points8),
                Text(
                  description,
                  style: TextStyles.small.copyWith(
                    color: theme.grey[700],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
