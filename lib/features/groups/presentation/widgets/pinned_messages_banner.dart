import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import '../../application/group_chat_providers.dart';
import '../../domain/entities/group_message_entity.dart';

/// Banner widget that displays pinned messages at the top of the chat
/// Allows horizontal scrolling through pinned messages
/// Admin long-press to unpin
class PinnedMessagesBanner extends ConsumerWidget {
  final String groupId;
  final bool isAdmin;
  final Function(String messageId)? onTapMessage;

  const PinnedMessagesBanner({
    super.key,
    required this.groupId,
    required this.isAdmin,
    this.onTapMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final pinnedMessagesAsync = ref.watch(pinnedMessagesProvider(groupId));

    return pinnedMessagesAsync.when(
      data: (pinnedMessages) {
        // Hide banner if no pinned messages
        if (pinnedMessages.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            color: theme.tint[50],
            border: Border(
              bottom: BorderSide(
                color: theme.grey[200]!,
                width: 1,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16.0,
                  8.0,
                  16.0,
                  4.0,
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.pin,
                      size: 16,
                      color: theme.tint[600],
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      AppLocalizations.of(context).translate('pinned-messages'),
                      style: TextStyles.smallBold.copyWith(
                        color: theme.tint[700],
                      ),
                    ),
                  ],
                ),
              ),

              // Horizontal scrollable list of pinned messages
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 4.0,
                  ),
                  itemCount: pinnedMessages.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12.0),
                  itemBuilder: (context, index) {
                    final message = pinnedMessages[index];
                    return _PinnedMessageCard(
                      message: message,
                      groupId: groupId,
                      isAdmin: isAdmin,
                      onTap: () => onTapMessage?.call(message.id),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) {
        // Silently fail - pinned messages are not critical
        return const SizedBox.shrink();
      },
    );
  }
}

/// Individual pinned message card
class _PinnedMessageCard extends ConsumerWidget {
  final GroupMessageEntity message;
  final String groupId;
  final bool isAdmin;
  final VoidCallback? onTap;

  const _PinnedMessageCard({
    required this.message,
    required this.groupId,
    required this.isAdmin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final repository = ref.read(groupChatRepositoryProvider);
    final senderName = repository.getSenderDisplayName(message.senderCpId);

    return GestureDetector(
      onTap: onTap,
      onLongPress: isAdmin
          ? () => _showUnpinDialog(context, ref)
          : null,
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(12.0),
        decoration: ShapeDecoration(
          color: theme.backgroundColor[0],
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
              cornerRadius: 12,
              cornerSmoothing: 1,
            ),
            side: BorderSide(
              color: theme.tint[200]!,
              width: 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sender name
            Row(
              children: [
                Icon(
                  LucideIcons.pin,
                  size: 12,
                  color: theme.tint[500],
                ),
                const SizedBox(width: 4.0),
                Expanded(
                  child: Text(
                    senderName,
                    style: TextStyles.small.copyWith(
                      color: theme.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4.0),

            // Message preview
            Expanded(
              child: Text(
                message.body,
                style: TextStyles.footnote.copyWith(
                  color: theme.grey[800],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnpinDialog(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 20,
            cornerSmoothing: 1,
          ),
        ),
        title: Text(
          l10n.translate('unpin-message'),
          style: TextStyles.h6,
        ),
        content: Text(
          l10n.translate('confirm-unpin-message'),
          style: TextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.translate('cancel'),
              style: TextStyles.footnote.copyWith(
                color: theme.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref
                    .read(pinnedMessagesServiceProvider.notifier)
                    .unpinMessage(
                      groupId: groupId,
                      messageId: message.id,
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.translate('message-unpinned')),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.translate('error-unpinning-message')),
                      backgroundColor: theme.error[500],
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: Text(
              l10n.translate('unpin'),
              style: TextStyles.footnote.copyWith(
                color: theme.error[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

