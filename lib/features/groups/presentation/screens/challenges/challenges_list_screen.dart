import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/groups/providers/challenges_notifier.dart';
import 'package:reboot_app_3/features/groups/presentation/widgets/challenge_card_widget.dart';
import 'package:reboot_app_3/features/groups/application/group_chat_providers.dart';

class ChallengesListScreen extends ConsumerStatefulWidget {
  final String groupId;

  const ChallengesListScreen({
    super.key,
    required this.groupId,
  });

  @override
  ConsumerState<ChallengesListScreen> createState() =>
      _ChallengesListScreenState();
}

class _ChallengesListScreenState extends ConsumerState<ChallengesListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final challengesAsync =
        ref.watch(challengesNotifierProvider(widget.groupId));
    final isAdminAsync = ref.watch(isCurrentUserGroupAdminProvider(widget.groupId));
    final isAdmin = isAdminAsync.valueOrNull ?? false;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.translate('challenges'),
          style: TextStyles.screenHeadding.copyWith(
            color: theme.grey[900],
          ),
        ),
        backgroundColor: theme.backgroundColor,
        surfaceTintColor: theme.backgroundColor,
        centerTitle: false,
      ),
      body: challengesAsync.when(
        data: (challengesState) {
          if (challengesState.error != null) {
            return Center(
              child: Text(
                challengesState.error!,
                style: TextStyles.body.copyWith(color: theme.error[600]),
              ),
            );
          }

          return Column(
            children: [
              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: theme.backgroundColor,
                  border: Border(
                    bottom: BorderSide(
                      color: theme.grey[200]!,
                      width: 1,
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: theme.primary[700],
                  unselectedLabelColor: theme.grey[600],
                  indicatorColor: theme.primary[700],
                  indicatorWeight: 2,
                  labelStyle: TextStyles.smallBold,
                  unselectedLabelStyle: TextStyles.small,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(l10n.translate('active')),
                          const SizedBox(width: 6),
                          if (challengesState.activeChallenges.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.primary[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${challengesState.activeChallenges.length}',
                                style: TextStyles.caption.copyWith(
                                  color: theme.primary[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(l10n.translate('upcoming')),
                          const SizedBox(width: 6),
                          if (challengesState.upcomingChallenges.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.warn[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${challengesState.upcomingChallenges.length}',
                                style: TextStyles.caption.copyWith(
                                  color: theme.warn[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(l10n.translate('completed')),
                          const SizedBox(width: 6),
                          if (challengesState.completedChallenges.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.success[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${challengesState.completedChallenges.length}',
                                style: TextStyles.caption.copyWith(
                                  color: theme.success[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Active Challenges
                    _buildChallengesList(
                      context,
                      theme,
                      l10n,
                      challengesState.activeChallenges,
                      'no-active-challenges',
                    ),

                    // Upcoming Challenges
                    _buildChallengesList(
                      context,
                      theme,
                      l10n,
                      challengesState.upcomingChallenges,
                      'no-upcoming-challenges',
                    ),

                    // Completed Challenges
                    _buildChallengesList(
                      context,
                      theme,
                      l10n,
                      challengesState.completedChallenges,
                      'no-completed-challenges',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.alertCircle,
                size: 48,
                color: theme.error[600],
              ),
              verticalSpace(Spacing.points16),
              Text(
                l10n.translate('error-loading-challenges'),
                style: TextStyles.body.copyWith(color: theme.error[600]),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToCreateChallenge(context),
              backgroundColor: theme.primary[600],
              label: Row(
                children: [
                  Icon(
                    LucideIcons.plus,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.translate('create-challenge'),
                    style: TextStyles.small.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildChallengesList(
    BuildContext context,
    theme,
    AppLocalizations l10n,
    List challenges,
    String emptyMessageKey,
  ) {
    if (challenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.trophy,
              size: 64,
              color: theme.grey[400],
            ),
            verticalSpace(Spacing.points16),
            Text(
              l10n.translate(emptyMessageKey),
              style: TextStyles.body.copyWith(
                color: theme.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(challengesNotifierProvider(widget.groupId));
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: challenges.length,
        separatorBuilder: (context, index) => verticalSpace(Spacing.points12),
        itemBuilder: (context, index) {
          final challenge = challenges[index];
          return ChallengeCardWidget(
            challenge: challenge,
            onTap: () => _navigateToChallengeDetail(context, challenge.id),
          );
        },
      ),
    );
  }

  void _navigateToCreateChallenge(BuildContext context) {
    context.pushNamed(
      RouteNames.createChallenge.name,
      pathParameters: {'groupId': widget.groupId},
    );
  }

  void _navigateToChallengeDetail(BuildContext context, String challengeId) {
    context.pushNamed(
      RouteNames.challengeDetail.name,
      pathParameters: {
        'groupId': widget.groupId,
        'challengeId': challengeId,
      },
    );
  }
}

