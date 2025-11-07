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
              // Show only the newest pinned message
              GestureDetector(
                onTap: () => _showPinnedMessagesSheet(
                  context,
                  ref,
                  groupId,
                  pinnedMessages,
                  isAdmin,
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
                  child: Row(
                    children: [
                      // Pin icon with count badge
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            LucideIcons.pin,
                            size: 18,
                            color: theme.tint[600],
                          ),
                          // Count badge if more than 1 message
                          if (pinnedMessages.length > 1)
                            Positioned(
                              right: -8,
                              top: -4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                  vertical: 2.0,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.tint[600],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Center(
                                  child: Text(
                                    '${pinnedMessages.length}',
                                    style: TextStyles.tinyBold.copyWith(
                                      color: Colors.white,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(width: 12.0),

                      // Newest message preview
                      Expanded(
                        child: Text(
                          pinnedMessages.first.body,
                          style: TextStyles.footnote.copyWith(
                            color: theme.grey[800],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Arrow indicator
                      Icon(
                        LucideIcons.chevronRight,
                        size: 16,
                        color: theme.grey[500],
                      ),
                    ],
                  ),
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

  /// Show pinned messages in a bottom sheet
  static void _showPinnedMessagesSheet(
    BuildContext context,
    WidgetRef ref,
    String groupId,
    List<GroupMessageEntity> pinnedMessages,
    bool isAdmin,
  ) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 20),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.pin,
                    size: 20,
                    color: theme.tint[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.translate('pinned-messages'),
                    style: TextStyles.h6.copyWith(
                      color: theme.grey[900],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      LucideIcons.x,
                      color: theme.grey[700],
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            Divider(height: 1, color: theme.grey[200]),

            // Pinned messages list (chat-like thread)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: pinnedMessages.length,
                itemBuilder: (context, index) {
                  final message = pinnedMessages[index];
                  final repository = ref.read(groupChatRepositoryProvider);
                  final senderName = repository.getSenderDisplayName(message.senderCpId);
                  final senderColor = repository.getSenderAvatarColor(message.senderCpId);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: senderColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                              style: TextStyles.body.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Message content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Sender name and unpin button
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      senderName,
                                      style: TextStyles.smallBold.copyWith(
                                        color: theme.grey[900],
                                      ),
                                    ),
                                  ),
                                  if (isAdmin)
                                    GestureDetector(
                                      onTap: () async {
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
                                      child: Icon(
                                        LucideIcons.pinOff,
                                        size: 18,
                                        color: theme.grey[600],
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 4),

                              // Message text
                              Container(
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: theme.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: theme.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  message.body,
                                  style: TextStyles.body.copyWith(
                                    color: theme.grey[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

