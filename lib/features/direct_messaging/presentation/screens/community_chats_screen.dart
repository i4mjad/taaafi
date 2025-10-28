import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/direct_messaging/application/direct_messaging_providers.dart';
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
                  padding: const EdgeInsets.all(16),
                  itemCount: conversations.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
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

        return GestureDetector(
          onTap: () {
            context.pushNamed(
              RouteNames.directChat.name,
              pathParameters: {'conversationId': conversation.id},
            );
          },
          child: WidgetsContainer(
            padding: const EdgeInsets.all(12),
            backgroundColor: theme.grey[50],
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.primary[100],
                  backgroundImage: otherProfile.avatarUrl != null
                      ? NetworkImage(otherProfile.avatarUrl!)
                      : null,
                  child: otherProfile.avatarUrl == null
                      ? Text(
                          displayName[0].toUpperCase(),
                          style: TextStyles.h5.copyWith(
                            color: theme.primary[500],
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),

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
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (isMuted)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                LucideIcons.bellOff,
                                size: 14,
                                color: theme.grey[500],
                              ),
                            ),
                          Expanded(
                            child: Text(
                              conversation.lastMessage ??
                                  localizations.translate('new-message'),
                              style: TextStyles.body.copyWith(
                                color: unreadCount > 0
                                    ? theme.grey[800]
                                    : theme.grey[600],
                                fontWeight: unreadCount > 0
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                    margin: const EdgeInsets.only(left: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primary[500],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: TextStyles.small.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConversationTileSkeleton(CustomThemeData theme) {
    return WidgetsContainer(
      padding: const EdgeInsets.all(12),
      backgroundColor: theme.grey[50],
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.grey[200],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 120,
                  decoration: BoxDecoration(
                    color: theme.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 200,
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
    return WidgetsContainer(
      padding: const EdgeInsets.all(12),
      backgroundColor: theme.grey[50],
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.grey[200],
            child: Icon(LucideIcons.userX, size: 20, color: theme.grey[400]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Error loading conversation',
              style: TextStyles.body.copyWith(color: theme.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}
