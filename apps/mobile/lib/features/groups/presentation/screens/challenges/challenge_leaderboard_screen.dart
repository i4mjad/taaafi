import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/groups/application/challenges_providers.dart';

class ChallengeLeaderboardScreen extends ConsumerWidget {
  final String groupId;
  final String challengeId;

  const ChallengeLeaderboardScreen({
    super.key,
    required this.groupId,
    required this.challengeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final leaderboardAsync =
        ref.watch(challengeLeaderboardProvider(challengeId));

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.translate('leaderboard'),
          style: TextStyles.screenHeadding.copyWith(
            color: theme.grey[900],
          ),
        ),
        backgroundColor: theme.backgroundColor,
        surfaceTintColor: theme.backgroundColor,
        centerTitle: false,
      ),
      body: leaderboardAsync.when(
        data: (participants) {
          if (participants.isEmpty) {
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
                    l10n.translate('no-participants-yet'),
                    style: TextStyles.body.copyWith(
                      color: theme.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Top 3 Podium
                if (participants.length >= 3)
                  _buildPodium(theme, l10n, participants.take(3).toList()),

                verticalSpace(Spacing.points24),

                // Full Rankings List
                _buildRankingsList(theme, l10n, participants),
              ],
            ),
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
                l10n.translate('error-loading-leaderboard'),
                style: TextStyles.body.copyWith(color: theme.error[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodium(theme, AppLocalizations l10n, List participants) {
    if (participants.length < 3) return const SizedBox.shrink();

    // Reorder to show 2nd, 1st, 3rd
    final first = participants[0];
    final second = participants.length > 1 ? participants[1] : null;
    final third = participants.length > 2 ? participants[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 2nd Place
        if (second != null)
          Expanded(
            child: _buildPodiumPlace(theme, l10n, second, 2, 120, theme.grey[400]!),
          ),

        const SizedBox(width: 8),

        // 1st Place
        Expanded(
          child: _buildPodiumPlace(theme, l10n, first, 1, 150, theme.warn[600]!),
        ),

        const SizedBox(width: 8),

        // 3rd Place
        if (third != null)
          Expanded(
            child: _buildPodiumPlace(theme, l10n, third, 3, 100, theme.tint[600]!),
          ),
      ],
    );
  }

  Widget _buildPodiumPlace(
      theme, AppLocalizations l10n, participant, int rank, double height, Color color) {
    return Column(
      children: [
        // Crown for 1st place
        if (rank == 1)
          Icon(
            LucideIcons.crown,
            size: 32,
            color: color,
          ),

        verticalSpace(Spacing.points8),

        // Avatar
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
          ),
          child: Center(
            child: Icon(
              LucideIcons.user,
              size: 32,
              color: color,
            ),
          ),
        ),

        verticalSpace(Spacing.points8),

        // Rank Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '#$rank',
            style: TextStyles.h6.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        verticalSpace(Spacing.points8),

        // Points
        Text(
          '${participant.earnedPoints}',
          style: TextStyles.h5.copyWith(
            color: theme.grey[900],
            fontWeight: FontWeight.bold,
          ),
        ),

        verticalSpace(Spacing.points8),

        // Podium
        Container(
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border(
              top: BorderSide(color: color, width: 3),
              left: BorderSide(color: color, width: 3),
              right: BorderSide(color: color, width: 3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankingsList(theme, AppLocalizations l10n, List participants) {
    return WidgetsContainer(
      backgroundColor: theme.backgroundColor,
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.grey[200]!, width: 1),
      cornerSmoothing: 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('all-participants'),
            style: TextStyles.h6.copyWith(
              color: theme.grey[900],
              fontWeight: FontWeight.bold,
            ),
          ),
          verticalSpace(Spacing.points16),
          ...participants.asMap().entries.map((entry) {
            final index = entry.key;
            final participant = entry.value;
            return _buildRankingItem(theme, l10n, index + 1, participant);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRankingItem(theme, AppLocalizations l10n, int rank, participant) {
    Color? badgeColor;
    Color? textColor;

    if (rank == 1) {
      badgeColor = theme.warn[100];
      textColor = theme.warn[700];
    } else if (rank == 2) {
      badgeColor = theme.grey[200];
      textColor = theme.grey[700];
    } else if (rank == 3) {
      badgeColor = theme.tint[100];
      textColor = theme.tint[700];
    } else {
      badgeColor = theme.grey[100];
      textColor = theme.grey[700];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.grey[200]!),
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyles.smallBold.copyWith(
                  color: textColor,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Participant Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.translate('participant'),
                  style: TextStyles.body.copyWith(
                    color: theme.grey[900],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                    const SizedBox(height: 4),
                // Points display
                Text(
                  '${participant.earnedPoints} ${l10n.translate('points')}',
                  style: TextStyles.smallBold.copyWith(
                    color: theme.success[700],
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

