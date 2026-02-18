import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/shared_widgets/container.dart';
import '../../../../core/theming/app-themes.dart';
import '../../../../core/theming/text_styles.dart';
import '../../domain/entities/referral_verification_entity.dart';

enum ChecklistItemType {
  accountAge7Days,
  forumPosts3,
  interactions5,
  groupJoined,
  groupMessages3,
  activityStarted,
}

class ChecklistItemWidget extends ConsumerWidget {
  final ChecklistItemType type;
  final ChecklistItemEntity item;
  final DateTime? signupDate;
  final bool isReadOnly;

  const ChecklistItemWidget({
    super.key,
    required this.type,
    required this.item,
    this.signupDate,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    final isCompleted = item.completed;
    final isInProgress = !isCompleted && (item.current ?? 0) > 0;

    Color backgroundColor;
    Color borderColor;
    Color iconColor;
    IconData icon;

    if (isCompleted) {
      backgroundColor = theme.success[50]!;
      borderColor = theme.success[200]!;
      iconColor = theme.success[600]!;
      icon = LucideIcons.checkCircle2;
    } else if (isInProgress) {
      backgroundColor = theme.warn[50]!;
      borderColor = theme.warn[200]!;
      iconColor = theme.warn[600]!;
      icon = LucideIcons.clock;
    } else {
      backgroundColor = theme.grey[50]!;
      borderColor = theme.grey[200]!;
      iconColor = theme.grey[400]!;
      icon = LucideIcons.circle;
    }

    return WidgetsContainer(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      backgroundColor: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: borderColor,
        width: 1,
      ),
      cornerSmoothing: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Status icon - Different styling for read-only
              if (isReadOnly)
                // Read-only: Just show status with emoji/icon
                Text(
                  isCompleted ? '✅' : isInProgress ? '⏳' : '⏸️',
                  style: const TextStyle(fontSize: 24),
                )
              else
                // Interactive: Show icon
                Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              const SizedBox(width: 12),

              // Title
              Expanded(
                child: Text(
                  _getTitle(l10n),
                  style: TextStyles.body.copyWith(
                    color: theme.grey[900],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Progress or completion info
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isCompleted) ...[
                  // Completion timestamp
                  if (item.completedAt != null)
                    Text(
                      _getCompletedText(item.completedAt!, l10n),
                      style: TextStyles.footnote.copyWith(
                        color: theme.grey[600],
                      ),
                    ),
                ] else ...[
                  // Progress indicator
                  Text(
                    _getProgressText(l10n),
                    style: TextStyles.footnote.copyWith(
                      color: theme.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  // Action button for incomplete items (ONLY if not read-only)
                  if (!isReadOnly && _hasActionButton()) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _handleAction(context),
                        icon: Icon(_getActionIcon(), size: 16),
                        label: Text(
                          _getActionText(l10n),
                          style: TextStyles.small,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.primary[600],
                          side: BorderSide(
                            color: theme.primary[300]!,
                            width: 1,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTitle(AppLocalizations l10n) {
    switch (type) {
      case ChecklistItemType.accountAge7Days:
        return l10n.translate('referral.checklist.account_age');
      case ChecklistItemType.forumPosts3:
        return l10n.translate('referral.checklist.forum_posts');
      case ChecklistItemType.interactions5:
        return l10n.translate('referral.checklist.interactions');
      case ChecklistItemType.groupJoined:
        return l10n.translate('referral.checklist.join_group');
      case ChecklistItemType.groupMessages3:
        return l10n.translate('referral.checklist.group_messages');
      case ChecklistItemType.activityStarted:
        return l10n.translate('referral.checklist.start_activity');
    }
  }

  String _getProgressText(AppLocalizations l10n) {
    switch (type) {
      case ChecklistItemType.accountAge7Days:
        if (signupDate != null) {
          final daysSinceSignup =
              DateTime.now().difference(signupDate!).inDays;
          final daysRemaining = 7 - daysSinceSignup;
          if (daysRemaining > 0) {
            return l10n
                .translate('referral.checklist.days_remaining')
                .replaceAll('{days}', daysRemaining.toString());
          }
        }
        return l10n.translate('referral.checklist.day_progress')
            .replaceAll('{current}', (item.current ?? 0).toString())
            .replaceAll('{target}', '7');
      case ChecklistItemType.forumPosts3:
        return '${item.current ?? 0}/3 ${l10n.translate('referral.checklist.posts')}';
      case ChecklistItemType.interactions5:
        return '${item.current ?? 0}/5 ${l10n.translate('referral.checklist.interactions_count')}';
      case ChecklistItemType.groupJoined:
        return l10n.translate('referral.checklist.not_joined');
      case ChecklistItemType.groupMessages3:
        return '${item.current ?? 0}/3 ${l10n.translate('referral.checklist.messages')}';
      case ChecklistItemType.activityStarted:
        return l10n.translate('referral.checklist.no_activity');
    }
  }

  String _getCompletedText(DateTime completedAt, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(completedAt);

    if (difference.inDays > 0) {
      return l10n
          .translate('referral.checklist.completed_days_ago')
          .replaceAll('{days}', difference.inDays.toString());
    } else if (difference.inHours > 0) {
      return l10n
          .translate('referral.checklist.completed_hours_ago')
          .replaceAll('{hours}', difference.inHours.toString());
    } else {
      return l10n.translate('referral.checklist.completed_recently');
    }
  }

  bool _hasActionButton() {
    // Account age has no action (automatic)
    // Group joined has no action if not yet joined (handled elsewhere)
    return type != ChecklistItemType.accountAge7Days &&
        (type != ChecklistItemType.groupJoined || (item.current ?? 0) == 0);
  }

  IconData _getActionIcon() {
    switch (type) {
      case ChecklistItemType.forumPosts3:
      case ChecklistItemType.interactions5:
        return LucideIcons.messageSquare;
      case ChecklistItemType.groupJoined:
        return LucideIcons.users;
      case ChecklistItemType.groupMessages3:
        return LucideIcons.messageCircle;
      case ChecklistItemType.activityStarted:
        return LucideIcons.activity;
      default:
        return LucideIcons.arrowRight;
    }
  }

  String _getActionText(AppLocalizations l10n) {
    switch (type) {
      case ChecklistItemType.forumPosts3:
      case ChecklistItemType.interactions5:
        return l10n.translate('referral.checklist.go_to_forum');
      case ChecklistItemType.groupJoined:
        return l10n.translate('referral.checklist.go_to_groups');
      case ChecklistItemType.groupMessages3:
        return l10n.translate('referral.checklist.go_to_group');
      case ChecklistItemType.activityStarted:
        return l10n.translate('referral.checklist.start_an_activity');
      default:
        return l10n.translate('common.view');
    }
  }

  void _handleAction(BuildContext context) {
    switch (type) {
      case ChecklistItemType.forumPosts3:
        // Navigate to new post screen
        context.pushNamed(RouteNames.newPost.name);
        break;
      case ChecklistItemType.interactions5:
        // Navigate to community/forum feed
        context.pushNamed(RouteNames.community.name);
        break;
      case ChecklistItemType.groupJoined:
        // Navigate to group exploration
        context.pushNamed(RouteNames.groupExploration.name);
        break;
      case ChecklistItemType.groupMessages3:
        // Navigate to user's group chat if groupId is available
        if (item.groupId != null) {
          context.pushNamed(
            RouteNames.groupChat.name,
            pathParameters: {'groupId': item.groupId!},
          );
        } else {
          // Fallback to group list
          context.pushNamed(RouteNames.groupList.name);
        }
        break;
      case ChecklistItemType.activityStarted:
        // Navigate to add activity screen
        context.pushNamed(RouteNames.addActivity.name);
        break;
      case ChecklistItemType.accountAge7Days:
        // No action for account age
        break;
    }
  }
}

