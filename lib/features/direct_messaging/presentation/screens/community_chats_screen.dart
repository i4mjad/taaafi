import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/direct_messaging/application/direct_messaging_providers.dart';
import 'package:reboot_app_3/features/direct_messaging/application/direct_messaging_ban_providers.dart';
import 'package:reboot_app_3/features/direct_messaging/domain/entities/direct_conversation_entity.dart';

class CommunityChatsScreen extends ConsumerStatefulWidget {
  final bool showAppBar;

  const CommunityChatsScreen({Key? key, this.showAppBar = true})
      : super(key: key);

  @override
  ConsumerState<CommunityChatsScreen> createState() =>
      _CommunityChatsScreenState();
}

class _CommunityChatsScreenState extends ConsumerState<CommunityChatsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final conversationsAsync = ref.watch(userConversationsProvider);
    final currentProfileAsync = ref.watch(currentCommunityProfileProvider);
    
    // Watch DM access status (cached)
    final dmAccessAsync = ref.watch(directMessagingAccessNotifierProvider);

    return Scaffold(
      appBar: widget.showAppBar
          ? appBar(context, ref, 'community-chats', false, false)
          : null,
      backgroundColor:
          widget.showAppBar ? theme.backgroundColor : Colors.transparent,
      body: currentProfileAsync.when(
        loading: () => const Center(child: Spinner()),
        error: (error, _) => Center(
          child: Text(
            'Error loading profile: $error',
            style: TextStyles.body.copyWith(color: theme.grey[600]),
          ),
        ),
        data: (currentProfile) {
          if (currentProfile == null) {
            return Center(
              child: Text(
                'Please create a community profile first',
                style: TextStyles.body.copyWith(color: theme.grey[600]),
              ),
            );
          }

          // Check DM access status
          return dmAccessAsync.when(
            loading: () => const Center(child: Spinner()),
            error: (error, _) => Center(
              child: Text(
                'Error checking access: $error',
                style: TextStyles.body.copyWith(color: theme.grey[600]),
              ),
            ),
            data: (dmAccess) {
              // Show ban message if user is completely blocked
              if (dmAccess.isCompletelyBlocked) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.ban,
                          size: 64,
                          color: theme.error[500],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          localizations.translate(dmAccess.errorMessageKey),
                          textAlign: TextAlign.center,
                          style: TextStyles.h6.copyWith(color: theme.grey[800]),
                        ),
                        if (dmAccess.activeBan != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            localizations.translate('reason') + ': ${dmAccess.activeBan!.reason}',
                            textAlign: TextAlign.center,
                            style: TextStyles.body.copyWith(color: theme.grey[600]),
                          ),
                        ],
                      ],
                    ),
              ),
            );
          }

          return conversationsAsync.when(
            loading: () => const Center(child: Spinner()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading conversations: $error',
                  style: TextStyles.body.copyWith(color: theme.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (conversations) {
              if (conversations.isEmpty) {
                return _buildEmptyState(context, theme, localizations);
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(userConversationsProvider);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: conversations.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: theme.grey[200],
                  ),
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    return _buildConversationTile(
                      context,
                      theme,
                      localizations,
                      conversation,
                      currentProfile.id,
                    );
                  },
                ),
              );
            },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations localizations,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.messageSquare,
              size: 64,
              color: theme.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              localizations.translate('no-conversations'),
              style: TextStyles.h5.copyWith(
                color: theme.grey[700],
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              localizations.translate('no-conversations-description'),
              style: TextStyles.body.copyWith(color: theme.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations localizations,
    DirectConversationEntity conversation,
    String currentCpId,
  ) {
    final otherCpId = conversation.getOtherParticipantCpId(currentCpId);
    final otherProfileAsync =
        ref.watch(communityProfileByIdProvider(otherCpId));
    final unreadCount = conversation.getUnreadCount(currentCpId);
    final isMuted = conversation.isMutedBy(currentCpId);

    return otherProfileAsync.when(
      loading: () => _buildConversationTileSkeleton(theme),
      error: (error, _) => _buildConversationTileError(theme),
      data: (otherProfile) {
        if (otherProfile == null) {
          return _buildConversationTileError(theme);
        }

        final displayName = otherProfile.isDeleted
            ? localizations.translate('community-deleted-user')
            : otherProfile.isAnonymous
                ? localizations.translate('community-anonymous')
                : otherProfile.displayName;

        final timeAgo =
            DateFormat('MMM d, HH:mm').format(conversation.lastActivityAt);

        return Dismissible(
          key: Key(conversation.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            // Show confirmation dialog
            return await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text(
                  localizations.translate('delete-conversation'),
                  style: TextStyles.h6.copyWith(color: theme.grey[900]),
                ),
                content: Text(
                  localizations.translate('delete-conversation-confirmation'),
                  style: TextStyles.body.copyWith(color: theme.grey[700]),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(
                      localizations.translate('cancel'),
                      style: TextStyles.body.copyWith(color: theme.grey[600]),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(
                      localizations.translate('delete'),
                      style: TextStyles.body.copyWith(color: theme.error[600]),
                    ),
                  ),
                ],
              ),
            ) ?? false;
          },
          onDismissed: (direction) async {
            try {
              final actionsController = ref.read(conversationActionsControllerProvider.notifier);
              await actionsController.deleteConversation(conversation.id);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(localizations.translate('conversation-deleted')),
                    backgroundColor: theme.success[600],
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(localizations.translate('error-deleting-conversation')),
                    backgroundColor: theme.error[600],
                  ),
                );
              }
            }
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: theme.error[600],
            child: Icon(
              LucideIcons.trash2,
              color: Colors.white,
              size: 24,
            ),
          ),
          child: InkWell(
            onTap: () async {
              // Check if user can send messages before opening conversation
              try {
                final canSend = await ref.read(canSendDirectMessageProvider.future);
                
                if (!canSend) {
                  if (!context.mounted) return;
                  final dmAccess = await ref.read(directMessagingAccessNotifierProvider.future);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(localizations.translate(dmAccess.errorMessageKey)),
                      backgroundColor: theme.error[600],
                    ),
                  );
                  return;
                }
              } catch (e) {
                print('Error checking send message permission: $e');
                // Continue anyway to show conversation in read-only mode
              }
              
              if (context.mounted) {
            context.pushNamed(
              RouteNames.directChat.name,
              pathParameters: {'conversationId': conversation.id},
            );
              }
          },
            child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 26,
                  backgroundColor: theme.primary[100],
                  backgroundImage: otherProfile.avatarUrl != null
                      ? NetworkImage(otherProfile.avatarUrl!)
                      : null,
                  child: otherProfile.avatarUrl == null
                      ? Text(
                          displayName[0].toUpperCase(),
                          style: TextStyles.h5.copyWith(
                            color: theme.primary[600],
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: TextStyles.body.copyWith(
                                color: theme.grey[900],
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeAgo,
                            style: TextStyles.small.copyWith(
                              color: theme.grey[500],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (isMuted)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(
                                LucideIcons.bellOff,
                                size: 15,
                                color: theme.grey[500],
                              ),
                            ),
                          Expanded(
                            child: Consumer(
                              builder: (context, ref, child) {
                                // Get the actual last visible message
                                final lastVisibleMessageAsync = ref.watch(
                                  conversationLastVisibleMessageProvider(
                                    conversation.id,
                                  ),
                                );

                                return lastVisibleMessageAsync.when(
                                  data: (lastVisibleMessage) => Text(
                                    lastVisibleMessage ??
                                        localizations.translate('new-message'),
                                    style: TextStyles.body.copyWith(
                                      color: unreadCount > 0
                                          ? theme.grey[700]
                                          : theme.grey[600],
                                      fontWeight: unreadCount > 0
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  loading: () => Text(
                                    conversation.lastMessage ??
                                        localizations.translate('new-message'),
                                    style: TextStyles.body.copyWith(
                                      color: unreadCount > 0
                                          ? theme.grey[700]
                                          : theme.grey[600],
                                      fontWeight: unreadCount > 0
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  error: (_, __) => Text(
                              conversation.lastMessage ??
                                  localizations.translate('new-message'),
                              style: TextStyles.body.copyWith(
                                color: unreadCount > 0
                                          ? theme.grey[700]
                                    : theme.grey[600],
                                fontWeight: unreadCount > 0
                                          ? FontWeight.w500
                                    : FontWeight.normal,
                                      fontSize: 14,
                              ),
                                    maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Unread badge
                if (unreadCount > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: theme.primary[500],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: TextStyles.small.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConversationTileSkeleton(CustomThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: theme.grey[200],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: 140,
                  decoration: BoxDecoration(
                    color: theme.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 14,
                  width: 220,
                  decoration: BoxDecoration(
                    color: theme.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTileError(CustomThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: theme.grey[200],
            child: Icon(LucideIcons.userX, size: 22, color: theme.grey[400]),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Error loading conversation',
              style: TextStyles.body.copyWith(
                color: theme.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
