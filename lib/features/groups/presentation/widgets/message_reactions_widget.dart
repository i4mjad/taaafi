import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/features/groups/domain/entities/group_message_entity.dart';
import 'package:reboot_app_3/features/groups/application/group_chat_providers.dart';
import 'package:reboot_app_3/features/community/application/community_profile_providers.dart';

/// A widget that displays reactions on a message
class MessageReactionsWidget extends ConsumerWidget {
  final GroupMessageEntity message;
  final String groupId;

  const MessageReactionsWidget({
    super.key,
    required this.message,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Don't show anything if there are no reactions
    if (message.reactions.isEmpty) {
      return const SizedBox.shrink();
    }

    final emojis = message.getReactionEmojis();
    if (emojis.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: emojis.map((emoji) {
          return _ReactionChip(
            emoji: emoji,
            count: message.getReactionCount(emoji),
            users: message.reactions[emoji] ?? [],
            isCurrentUserReacted: _checkIfCurrentUserReacted(ref, emoji),
            onTap: () => _handleReactionTap(context, ref, emoji),
          );
        }).toList(),
      ),
    );
  }

  bool _checkIfCurrentUserReacted(WidgetRef ref, String emoji) {
    final currentProfile = ref.watch(currentCommunityProfileProvider).value;
    if (currentProfile == null) return false;
    return message.hasUserReacted(currentProfile.id, emoji);
  }

  Future<void> _handleReactionTap(
    BuildContext context,
    WidgetRef ref,
    String emoji,
  ) async {
    try {
      final service = ref.read(messageReactionsServiceProvider.notifier);
      await service.toggleReaction(
        groupId: groupId,
        messageId: message.id,
        emoji: emoji,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('error-toggling-reaction'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Individual reaction chip
class _ReactionChip extends StatelessWidget {
  final String emoji;
  final int count;
  final List<String> users;
  final bool isCurrentUserReacted;
  final VoidCallback onTap;

  const _ReactionChip({
    required this.emoji,
    required this.count,
    required this.users,
    required this.isCurrentUserReacted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: isCurrentUserReacted
              ? theme.colorScheme.primary.withOpacity(0.1)
              : theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentUserReacted
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.2),
            width: isCurrentUserReacted ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: isCurrentUserReacted 
                    ? FontWeight.bold 
                    : FontWeight.normal,
                color: isCurrentUserReacted
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

