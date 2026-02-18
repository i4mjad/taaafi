import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/features/groups/domain/entities/group_update_entity.dart';
import 'package:reboot_app_3/features/groups/application/updates_providers.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/report_content_modal.dart';

/// Widget for displaying a single update in the feed
class UpdateCardWidget extends ConsumerWidget {
  final GroupUpdateEntity update;
  final String groupId;
  final VoidCallback? onTap;
  final bool isCompact;

  const UpdateCardWidget({
    super.key,
    required this.update,
    required this.groupId,
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.grey[200]!,
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context, ref, theme, l10n),
            const SizedBox(height: 12),

            // Content
            _buildContent(context, theme, l10n),

            if (!isCompact) ...[
              const SizedBox(height: 12),
              // Engagement bar
              _buildEngagementBar(context, ref, theme, l10n),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    dynamic theme,
    AppLocalizations l10n,
  ) {
    final authorAsync =
        ref.watch(communityProfileByIdProvider(update.authorCpId));
    final currentProfileAsync = ref.watch(currentCommunityProfileProvider);

    // Check if current user is the author
    final isCurrentUser = currentProfileAsync.maybeWhen(
      data: (profile) => profile?.id == update.authorCpId,
      orElse: () => false,
    );

    return Row(
      children: [
        // Avatar/Icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.primary[100],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              update.type.icon,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Name and time
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                update.isAnonymous
                    ? l10n.translate('anonymous-member')
                    : isCurrentUser
                        ? l10n.translate('you')
                        : authorAsync.when(
                            data: (author) =>
                                author != null ? author.displayName : 'Unknown',
                            loading: () => 'Loading...',
                            error: (_, __) => 'Member',
                          ),
                style: TextStyles.footnoteSelected.copyWith(
                  color: theme.grey[900],
                ),
              ),
              Text(
                _formatUpdateTime(update.createdAt, l10n),
                style: TextStyles.caption.copyWith(
                  color: theme.grey[600],
                ),
              ),
            ],
          ),
        ),
        // Type badge
        _buildTypeBadge(theme, l10n),
        const SizedBox(width: 8),
        // More options button
        if (!isCompact)
          GestureDetector(
            onTap: () => _showOptionsMenu(context, ref),
            child: Icon(
              LucideIcons.moreVertical,
              size: 16,
              color: theme.grey[600],
            ),
          ),
      ],
    );
  }

  Widget _buildTypeBadge(dynamic theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        l10n.translate('update-type-${update.type.toFirestore()}'),
        style: TextStyles.bodyTiny.copyWith(
          color: theme.grey[700],
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    dynamic theme,
    AppLocalizations l10n,
  ) {
    // Check if content should be redacted
    final bool shouldRedact = update.shouldBeRedacted();

    if (shouldRedact) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.warn[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.warn[200]!, width: 1),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.eye, size: 16, color: theme.warn[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.translate('update-under-review'),
                style: TextStyles.small.copyWith(
                  color: theme.warn[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (update.title.isNotEmpty && !isCompact) ...[
          Text(
            update.title,
            style: TextStyles.footnoteSelected.copyWith(
              color: theme.grey[900],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Text(
          isCompact && update.content.length > 100
              ? '${update.content.substring(0, 100)}...'
              : update.content,
          style: TextStyles.small.copyWith(
            color: theme.grey[800],
            height: 1.4,
          ),
        ),
        if (update.hasLinkedChallenge() && !isCompact) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.success[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: theme.success[200]!, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.trophy, size: 12, color: theme.success[700]),
                const SizedBox(width: 4),
                Text(
                  l10n.translate('linked-to-challenge'),
                  style: TextStyles.bodyTiny.copyWith(
                    color: theme.success[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEngagementBar(
    BuildContext context,
    WidgetRef ref,
    dynamic theme,
    AppLocalizations l10n,
  ) {
    final currentProfile = ref.watch(currentCommunityProfileProvider).value;
    final hasReacted = currentProfile != null &&
        update.reactions.values
            .any((cpIds) => cpIds.contains(currentProfile.id));

    return Row(
      children: [
        // Reactions
        _buildReactionButton(
          context,
          ref,
          theme,
          icon: LucideIcons.heart,
          count: update.supportCount,
          isActive: hasReacted,
          onTap: () => _toggleReaction(ref, '❤️'),
        ),
        const SizedBox(width: 16),
        // Comments
        _buildEngagementButton(
          theme,
          icon: LucideIcons.messageCircle,
          count: update.commentCount,
        ),
        const SizedBox(width: 16),
        // Share
        if (!isCompact)
          Icon(LucideIcons.share2, size: 16, color: theme.grey[600]),
      ],
    );
  }

  Widget _buildReactionButton(
    BuildContext context,
    WidgetRef ref,
    dynamic theme, {
    required IconData icon,
    required int count,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isActive ? theme.error[500] : theme.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: TextStyles.caption.copyWith(
              color: isActive ? theme.error[500] : theme.grey[700],
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementButton(
    dynamic theme, {
    required IconData icon,
    required int count,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.grey[600]),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: TextStyles.caption.copyWith(color: theme.grey[700]),
        ),
      ],
    );
  }

  String _formatUpdateTime(DateTime time, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return l10n.translate('just-now-time');
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}${l10n.translate('minutes-short-time')}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}${l10n.translate('hours-short-time')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}${l10n.translate('days-short-time')}';
    } else {
      return '${time.day}/${time.month}';
    }
  }

  void _toggleReaction(WidgetRef ref, String emoji) {
    ref.read(updateReactionsControllerProvider.notifier).toggleReaction(
          updateId: update.id,
          emoji: emoji,
        );
  }

  void _showOptionsMenu(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    // Check if current user is the author
    final currentProfileAsync = ref.watch(currentCommunityProfileProvider);
    final isAuthor = currentProfileAsync.maybeWhen(
      data: (profile) => profile?.id == update.authorCpId,
      orElse: () => false,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.backgroundColor,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAuthor)
              ListTile(
                leading: Icon(LucideIcons.trash2, color: theme.error[600]),
                title: Text(
                  l10n.translate('delete-update'),
                  style: TextStyles.body.copyWith(color: theme.error[600]),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, ref, l10n, theme);
                },
              )
            else
              ListTile(
                leading: Icon(LucideIcons.flag, color: theme.grey[700]),
                title: Text(
                  l10n.translate('report-update'),
                  style: TextStyles.body.copyWith(color: theme.grey[900]),
                ),
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => ReportContentModal(
                      groupUpdate: update,
                      contentType: ReportContentType.group_update,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    dynamic theme,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.backgroundColor,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              l10n.translate('delete-update'),
              style: TextStyles.h6.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Content
            Text(
              l10n.translate('delete-update-confirmation'),
              style: TextStyles.body.copyWith(
                color: theme.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Actions
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          l10n.translate('cancel'),
                          style: TextStyles.body.copyWith(
                            color: theme.grey[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      await _deleteUpdate(context, ref);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.error[600],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          l10n.translate('delete'),
                          style: TextStyles.body.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Future<void> _deleteUpdate(BuildContext context, WidgetRef ref) async {
    try {
      final controller = ref.read(updateManagementControllerProvider.notifier);
      await controller.deleteUpdate(
        updateId: update.id,
        isAdmin: false, // User is deleting their own update
      );

      // Refresh all update providers
      ref.invalidate(latestUpdatesProvider(groupId));
      ref.invalidate(recentUpdatesProvider(groupId));
      ref.invalidate(groupUpdatesProvider(groupId));

      if (context.mounted) {
        getSuccessSnackBar(context, 'update-deleted-successfully');
      }
    } catch (e) {
      if (context.mounted) {
        getErrorSnackBar(context, 'error-deleting-update');
      }
    }
  }
}
