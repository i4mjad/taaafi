import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/quick_actions_widget.dart';
import 'package:reboot_app_3/features/plus/presentation/widgets/subscription_card.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/streaks/streaks_view_widget.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/notification_promoter_widget.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/features/vault/presentation/vault_settings/activities_notifications_settings_screen.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/challenges_coming_soon_card.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/groups_coming_soon_card.dart';

class MainHomeView extends ConsumerWidget {
  const MainHomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);
    final notificationsEnabledAsync = ref.watch(notificationsEnabledProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subscription Card

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: const SubscriptionCard(),
          ),

          verticalSpace(Spacing.points24),
          // Notification Promoter - show if notifications are disabled
          notificationsEnabledAsync.when(
            data: (enabled) => enabled
                ? const SizedBox.shrink()
                : const NotificationPromoterWidget(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Quick Actions
          const QuickActionsWidget(),
          verticalSpace(Spacing.points24),

          // Streaks View
          const StreaksViewWidget(),
          verticalSpace(Spacing.points24),

          // Community Activity Section
          const _CommunityActivitySection(),
          verticalSpace(Spacing.points24),

          // Coming Soon Cards Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Challenges Coming Soon Card
                Expanded(
                  child: ChallengesComingSoonCard(),
                ),
                const SizedBox(width: 12),
                // Groups Coming Soon Card
                Expanded(
                  child: GroupsComingSoonCard(),
                ),
              ],
            ),
          ),
          verticalSpace(Spacing.points24),

          // Active Goals/Challenges Section
          // const _ActiveChallengesSection(),
          // verticalSpace(Spacing.points24),
        ],
      ),
    );
  }
}

class _CommunityActivitySection extends ConsumerStatefulWidget {
  const _CommunityActivitySection();

  @override
  _CommunityActivitySectionState createState() =>
      _CommunityActivitySectionState();
}

class _CommunityActivitySectionState
    extends ConsumerState<_CommunityActivitySection> {
  late PageController pageController;
  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    pageController = PageController(
      viewportFraction: 0.75,
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(LucideIcons.users, size: 20, color: theme.primary[600]),
              horizontalSpace(Spacing.points8),
              Text(
                localization.translate("community"),
                style: TextStyles.h6.copyWith(color: theme.grey[900]),
              ),
              const Spacer(),
              // Page indicators
              Row(
                children: List.generate(4, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: currentPage == index
                          ? theme.primary[600]
                          : theme.grey[300],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        verticalSpace(Spacing.points12),

        // Horizontal scrollable cards with snap
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 140,
            child: PageView(
              controller: pageController,
              padEnds: false,
              onPageChanged: (int page) {
                setState(() {
                  currentPage = page;
                });
              },
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _CommunityActionCard(
                    title: localization.translate("discover-fresh-content"),
                    subtitle: localization.translate("explore-trending-now"),
                    icon: LucideIcons.compass,
                    iconColor: theme.primary[600]!,
                    backgroundColor: theme.primary[50]!,
                    borderColor: theme.primary[200]!,
                    onTap: () {
                      // Navigate to community main screen with posts tab selected
                      context.push('/community?tab=posts');
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _CommunityActionCard(
                    title: localization.translate("share-your-story"),
                    subtitle: localization.translate("inspire-others-journey"),
                    icon: LucideIcons.edit3,
                    iconColor: theme.success[600]!,
                    backgroundColor: theme.success[50]!,
                    borderColor: theme.success[200]!,
                    onTap: () {
                      // Navigate to create post with general category selected
                      context.push(
                          '/community/forum/new?categoryId=DFbm1WSnUyrOmtKZYWVb');
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _CommunityActionCard(
                    title: localization.translate("need-support"),
                    subtitle: localization.translate("get-help-community"),
                    icon: LucideIcons.helpCircle,
                    iconColor: theme.warn[600]!,
                    backgroundColor: theme.warn[50]!,
                    borderColor: theme.warn[200]!,
                    onTap: () {
                      // Navigate to create post with support category selected
                      context.push(
                          '/community/forum/new?categoryId=mQFCsyIwAk5KcVPSH3NS');
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _CommunityActionCard(
                    title: localization.translate("browse-categories"),
                    subtitle: localization.translate("find-content-topic"),
                    icon: LucideIcons.grid,
                    iconColor: theme.secondary[600]!,
                    backgroundColor: theme.secondary[50]!,
                    borderColor: theme.secondary[200]!,
                    onTap: () {
                      // Navigate to community main screen with categories tab selected
                      context.push('/community?tab=categories');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CommunityActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _CommunityActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: WidgetsContainer(
        padding: const EdgeInsets.all(16),
        backgroundColor: backgroundColor,
        borderSide: BorderSide(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor,
              ),
            ),
            verticalSpace(Spacing.points12),
            Text(
              title,
              style: TextStyles.footnote.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            verticalSpace(Spacing.points4),
            Text(
              subtitle,
              style: TextStyles.small.copyWith(
                color: theme.grey[600],
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveChallengesSection extends ConsumerStatefulWidget {
  const _ActiveChallengesSection();

  @override
  _ActiveChallengesSectionState createState() =>
      _ActiveChallengesSectionState();
}

class _ActiveChallengesSectionState
    extends ConsumerState<_ActiveChallengesSection> {
  late PageController challengePageController;
  int challengeCurrentPage = 0;

  @override
  void initState() {
    super.initState();
    challengePageController = PageController(
      viewportFraction: 0.6,
    );
  }

  @override
  void dispose() {
    challengePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(LucideIcons.trophy, size: 20, color: theme.warn[600]),
              horizontalSpace(Spacing.points8),
              Text(
                localization.translate("active-challenges"),
                style: TextStyles.h6.copyWith(color: theme.grey[900]),
              ),
              const Spacer(),
              // Page indicators
              Row(
                children: List.generate(3, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: challengeCurrentPage == index
                          ? theme.warn[600]
                          : theme.grey[300],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        verticalSpace(Spacing.points12),

        // Horizontal scrollable cards with snap
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 100,
            child: PageView(
              controller: challengePageController,
              padEnds: false,
              onPageChanged: (int page) {
                setState(() {
                  challengeCurrentPage = page;
                });
              },
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _ChallengeCard(
                    title: localization.translate("thirty-day-challenge"),
                    progress: 0.6,
                    daysLeft: 12,
                    daysLeftText: localization
                        .translate("days-left")
                        .replaceAll("{days}", "12"),
                    color: theme.success[500]!,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _ChallengeCard(
                    title: localization.translate("weekly-goal"),
                    progress: 0.8,
                    daysLeft: 2,
                    daysLeftText: localization
                        .translate("days-left")
                        .replaceAll("{days}", "2"),
                    color: theme.primary[500]!,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _ChallengeCard(
                    title: localization.translate("monthly-challenge"),
                    progress: 0.4,
                    daysLeft: 18,
                    daysLeftText: localization
                        .translate("days-left")
                        .replaceAll("{days}", "18"),
                    color: theme.secondary[500]!,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final String title;
  final double progress;
  final int daysLeft;
  final String daysLeftText;
  final Color color;

  const _ChallengeCard({
    required this.title,
    required this.progress,
    required this.daysLeft,
    required this.daysLeftText,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return WidgetsContainer(
      padding: const EdgeInsets.all(12),
      backgroundColor: color.withValues(alpha: 0.1),
      borderSide: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyles.small.copyWith(
                    color: theme.grey[900],
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  daysLeftText,
                  style: TextStyles.small.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          verticalSpace(Spacing.points8),
          // Progress bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
