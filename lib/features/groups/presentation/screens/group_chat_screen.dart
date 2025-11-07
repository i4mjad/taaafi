import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:grouped_list/grouped_list.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';

import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/core/theming/chat_text_size_provider.dart';

// Group chat backend integration
import '../../application/group_chat_providers.dart';
import '../../domain/entities/group_message_entity.dart';

import '../../../community/presentation/providers/community_providers_new.dart';
import '../../../../core/shared_widgets/snackbar.dart';
import '../../../../core/shared_widgets/action_modal.dart';
import '../widgets/group_chat_profile_modal.dart';
import '../widgets/message_report_modal.dart';
import '../widgets/pinned_messages_banner.dart';
import '../widgets/reaction_picker.dart';
import '../../../shared/data/notifiers/user_reports_notifier.dart';
import 'group_chat_settings_screen.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/route_names.dart';

/// Model for chat message
class ChatMessage {
  final String id;
  final String content;
  final String senderName;
  final String senderCpId; // Community profile ID for avatar clicks
  final String time;
  final DateTime dateTime;
  final bool isCurrentUser;
  final Color avatarColor;
  final bool isAnonymous; // Whether this user is anonymous
  final String? avatarUrl; // Community profile avatar URL
  final ChatMessage? replyToMessage; // The message being replied to
  final String? replyToMessageId; // ID of the message being replied to
  final bool isHidden; // Whether this message was hidden by admin
  final ModerationStatusType? moderationStatus; // Moderation status
  final String? moderationReason; // Moderation reason if blocked
  final bool isPinned; // Whether this message is pinned
  final Map<String, List<String>> reactions; // Emoji reactions on this message

  const ChatMessage({
    required this.id,
    required this.content,
    required this.senderName,
    required this.senderCpId,
    required this.time,
    required this.dateTime,
    required this.isCurrentUser,
    required this.avatarColor,
    required this.isAnonymous,
    this.avatarUrl,
    this.replyToMessage,
    this.replyToMessageId,
    this.isHidden = false,
    this.moderationStatus,
    this.moderationReason,
    this.isPinned = false,
    this.reactions = const {},
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    String? senderName,
    String? senderCpId,
    String? time,
    DateTime? dateTime,
    bool? isCurrentUser,
    Color? avatarColor,
    bool? isAnonymous,
    String? avatarUrl,
    ChatMessage? replyToMessage,
    String? replyToMessageId,
    bool? isHidden,
    ModerationStatusType? moderationStatus,
    String? moderationReason,
    bool? isPinned,
    Map<String, List<String>>? reactions,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      senderName: senderName ?? this.senderName,
      senderCpId: senderCpId ?? this.senderCpId,
      time: time ?? this.time,
      dateTime: dateTime ?? this.dateTime,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      avatarColor: avatarColor ?? this.avatarColor,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      isHidden: isHidden ?? this.isHidden,
      moderationStatus: moderationStatus ?? this.moderationStatus,
      moderationReason: moderationReason ?? this.moderationReason,
      isPinned: isPinned ?? this.isPinned,
      reactions: reactions ?? this.reactions,
    );
  }
}

/// Model for grouped chat messages by date (for fallback use)
class GroupedMessages {
  final DateTime date;
  final List<ChatMessage> messages;

  const GroupedMessages({
    required this.date,
    required this.messages,
  });
}

/// Reply state for managing message replies
class ChatReplyState {
  final bool isReplying;
  final ChatMessage? replyToMessage;
  final String? replyToMessageId;

  const ChatReplyState({
    this.isReplying = false,
    this.replyToMessage,
    this.replyToMessageId,
  });

  ChatReplyState copyWith({
    bool? isReplying,
    ChatMessage? replyToMessage,
    String? replyToMessageId,
  }) {
    return ChatReplyState(
      isReplying: isReplying ?? this.isReplying,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
    );
  }

  ChatReplyState clear() {
    return const ChatReplyState();
  }
}

class GroupChatScreen extends ConsumerStatefulWidget {
  final String? groupId;

  const GroupChatScreen({super.key, this.groupId});

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSubmitting = false;
  ChatReplyState _replyState = const ChatReplyState();

  // Animation for reply preview dismissal
  late AnimationController _replyPreviewController;
  late Animation<double> _replyPreviewAnimation;

  // Highlight effect for scrolled-to messages
  String? _highlightedMessageId;
  AnimationController? _highlightController;
  Animation<double>? _highlightAnimation;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() {});
    });

    // Initialize reply preview animation
    _replyPreviewController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _replyPreviewAnimation = CurvedAnimation(
      parent: _replyPreviewController,
      curve: Curves.easeIn,
    );
    _replyPreviewController.value = 1.0; // Start fully visible

    // Initialize highlight animation
    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _highlightAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _highlightController!,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _replyPreviewController.dispose();
    _highlightController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final chatTextSize = ref.watch(chatTextSizeProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(
        context,
        ref,
        "group-chat",
        false,
        true,
        actions: [
          IconButton(
            icon: Icon(
              LucideIcons.settings,
              color: theme.grey[700],
              size: 20,
            ),
            onPressed: () => _navigateToChatSettings(context),
            tooltip: l10n.translate('chat-settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Pinned messages banner
          Consumer(
            builder: (context, ref, child) {
              final groupId = widget.groupId;
              if (groupId == null) return const SizedBox.shrink();

              final isAdminAsync =
                  ref.watch(isCurrentUserGroupAdminProvider(groupId));
              final isAdmin = isAdminAsync.valueOrNull ?? false;

              return PinnedMessagesBanner(
                groupId: groupId,
                isAdmin: isAdmin,
                onTapMessage: (messageId) {
                  // TODO: Scroll to message in chat
                  // This will be implemented when we add scroll-to-message functionality
                  print('Tapped pinned message: $messageId');
                },
              );
            },
          ),

          // Messages list
          Expanded(
            child: _buildMessagesList(context, theme, l10n, chatTextSize),
          ),

          // Input area
          _buildInputArea(context, theme, l10n),
        ],
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context, CustomThemeData theme,
      AppLocalizations l10n, ChatTextSize chatTextSize) {
    // Check if user can access chat
    final canAccessAsync =
        ref.watch(canAccessGroupChatProvider(widget.groupId ?? ''));

    return canAccessAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          'خطأ في تحميل المحادثة',
          style: TextStyles.body.copyWith(color: theme.grey[600]),
        ),
      ),
      data: (canAccess) {
        if (!canAccess) {
          return Center(
            child: Text(
              'يجب أن تكون عضواً في المجموعة لرؤية الرسائل',
              style: TextStyles.body.copyWith(color: theme.grey[600]),
            ),
          );
        }

        // Use real-time stream for display - this ensures no duplicates
        final messagesAsync =
            ref.watch(groupChatMessagesProvider(widget.groupId ?? ''));

        return messagesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text(
              'خطأ في تحميل الرسائل',
              style: TextStyles.body.copyWith(color: theme.grey[600]),
            ),
          ),
          data: (messageEntities) {
            final messages =
                _convertEntitiesToChatMessages(messageEntities, l10n);

            if (messages.isEmpty) {
              return Center(
                child: Text(
                  'لا توجد رسائل',
                  style: TextStyles.body.copyWith(color: theme.grey[600]),
                ),
              );
            }

            // Check if we can load more from paginated provider (for navigation only)
            final paginatedAsync = ref
                .read(groupChatMessagesPaginatedProvider(widget.groupId ?? ''));
            final hasMore = paginatedAsync.valueOrNull?.hasMore ?? false;

            return _buildMessageListViewWithPagination(
                context, theme, chatTextSize, messages, hasMore);
          },
        );
      },
    );
  }

  Widget _buildMessageListViewWithPagination(
      BuildContext context,
      CustomThemeData theme,
      ChatTextSize chatTextSize,
      List<ChatMessage> messages,
      bool hasMore) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Sort messages by creation time (latest first for reverse ListView)
    final sortedMessages = List<ChatMessage>.from(messages);
    sortedMessages.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    // Auto-scroll to bottom when messages first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && messages.isNotEmpty) {
        _scrollController.jumpTo(0); // Jump to bottom (latest messages)
      }
    });

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        // Load more messages when scrolling to the top (older messages)
        if (hasMore &&
            scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent * 0.9) {
          _loadMoreMessages();
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        reverse: true, // Latest messages at bottom
        padding: EdgeInsets.symmetric(
          horizontal: (screenWidth * 0.04).clamp(12.0, 20.0),
          vertical: (screenHeight * 0.01).clamp(6.0, 12.0),
        ),
        itemCount: sortedMessages.length +
            (hasMore ? 1 : 0), // +1 for loading indicator
        itemBuilder: (context, index) {
          // Show loading indicator at the top when loading more
          if (index == sortedMessages.length) {
            return hasMore
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox.shrink();
          }

          final message = sortedMessages[index];
          final nextMessage = index < sortedMessages.length - 1
              ? sortedMessages[index + 1]
              : null;

          return Column(
            children: [
              // Show date separator - fixed logic for reverse ListView
              // We want the separator ABOVE the first message of each day (chronologically)
              // In reverse ListView: last index = chronologically first message of the day
              if (index ==
                      sortedMessages.length -
                          1 || // Last item (chronologically first)
                  (nextMessage != null &&
                      !_isSameDay(message.dateTime, nextMessage.dateTime)))
                _buildDateSeparator(context, theme,
                    AppLocalizations.of(context), message.dateTime),

              _buildMessageItem(context, theme, message, chatTextSize),
            ],
          );
        },
      ),
    );
  }

  /// Load more messages (for infinite scroll)
  void _loadMoreMessages() {
    if (widget.groupId == null) return;

    final paginatedProvider =
        groupChatMessagesPaginatedProvider(widget.groupId!);
    final paginatedNotifier = ref.read(paginatedProvider.notifier);
    paginatedNotifier.loadMore();
  }

  /// Convert GroupMessageEntity list to ChatMessage list for UI compatibility
  List<ChatMessage> _convertEntitiesToChatMessages(
      List<GroupMessageEntity> entities, AppLocalizations l10n) {
    final currentProfileAsync = ref.read(currentCommunityProfileProvider);
    final currentCpId = currentProfileAsync.valueOrNull?.id;

    // Get repository for cached profile data
    final repository = ref.read(groupChatRepositoryProvider);

    // Remove duplicates by ID first (keep all messages including hidden ones)
    final uniqueEntities = <String, GroupMessageEntity>{};
    for (final entity in entities.where((entity) => !entity.isDeleted)) {
      // Hide blocked messages from OTHER users only
      if (entity.moderation.status == ModerationStatusType.blocked) {
        // Only show blocked messages to the sender
        if (currentCpId != null && entity.senderCpId == currentCpId) {
          uniqueEntities[entity.id] = entity;
        }
      } else {
        // Show all other messages (pending, approved, manual_review)
        uniqueEntities[entity.id] = entity;
      }
    }

    return uniqueEntities.values.map((entity) {
      final isCurrentUser =
          currentCpId != null && entity.senderCpId == currentCpId;

      // Get sender info from repository cache (already fetched with messages)
      final senderDisplayName =
          repository.getSenderDisplayName(entity.senderCpId);
      final senderAvatarColor =
          repository.getSenderAvatarColor(entity.senderCpId);
      final senderIsAnonymous =
          repository.getSenderAnonymity(entity.senderCpId);
      final senderAvatarUrl = repository.getSenderAvatarUrl(entity.senderCpId);

      // Find reply target if this is a reply
      ChatMessage? replyToMessage;
      if (entity.replyToMessageId != null) {
        final replyTarget = entities.firstWhere(
          (e) => e.id == entity.replyToMessageId,
          orElse: () => GroupMessageEntity(
            id: '',
            groupId: '',
            senderCpId: '',
            body: 'رسالة محذوفة',
            createdAt: DateTime.now(),
          ),
        );

        if (replyTarget.id.isNotEmpty) {
          final replyTargetDisplayName =
              repository.getSenderDisplayName(replyTarget.senderCpId);
          final replyTargetAvatarColor =
              repository.getSenderAvatarColor(replyTarget.senderCpId);
          final replyTargetIsAnonymous =
              repository.getSenderAnonymity(replyTarget.senderCpId);
          final replyTargetAvatarUrl =
              repository.getSenderAvatarUrl(replyTarget.senderCpId);

          replyToMessage = ChatMessage(
            id: replyTarget.id,
            content: replyTarget.body,
            senderName: replyTargetDisplayName,
            senderCpId: replyTarget.senderCpId,
            time: _formatTime(replyTarget.createdAt, l10n),
            dateTime: replyTarget.createdAt,
            isCurrentUser:
                currentCpId != null && replyTarget.senderCpId == currentCpId,
            avatarColor: replyTargetAvatarColor,
            isAnonymous: replyTargetIsAnonymous,
            avatarUrl: replyTargetAvatarUrl,
            isHidden: replyTarget.isHidden,
            moderationStatus: replyTarget.moderation.status,
            moderationReason: replyTarget.moderation.reason,
          );
        }
      }

      return ChatMessage(
        id: entity.id,
        content: entity.body,
        senderName: senderDisplayName,
        senderCpId: entity.senderCpId,
        time: _formatTime(entity.createdAt, l10n),
        dateTime: entity.createdAt,
        isCurrentUser: isCurrentUser,
        avatarColor: senderAvatarColor,
        isAnonymous: senderIsAnonymous,
        avatarUrl: senderAvatarUrl,
        replyToMessage: replyToMessage,
        replyToMessageId: entity.replyToMessageId,
        isHidden: entity.isHidden,
        moderationStatus: entity.moderation.status,
        moderationReason: entity.moderation.reason,
        isPinned: entity.isPinned,
        reactions: entity.reactions,
      );
    }).toList();
  }

  /// Format DateTime to time string
  String _formatTime(DateTime dateTime, AppLocalizations l10n) {
    final local = dateTime.toLocal();
    final hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final amText = l10n.translate('am');
    final pmText = l10n.translate('pm');
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final period = hour >= 12 ? pmText : amText;

    return '$displayHour:$minute $period';
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildDateSeparator(BuildContext context, CustomThemeData theme,
      AppLocalizations l10n, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final localDate = date.toLocal();
    final messageDate =
        DateTime(localDate.year, localDate.month, localDate.day);
    final screenHeight = MediaQuery.of(context).size.height;

    String dateText;
    if (messageDate == today) {
      dateText = l10n.translate('today');
    } else if (messageDate == yesterday) {
      dateText = l10n.translate('yesterday');
    } else {
      final isRTL = Directionality.of(context) == TextDirection.rtl;
      if (isRTL) {
        dateText = '${localDate.day}/${localDate.month}/${localDate.year}';
      } else {
        dateText = '${localDate.month}/${localDate.day}/${localDate.year}';
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(
          vertical: (screenHeight * 0.02).clamp(12.0, 20.0)),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal:
                (MediaQuery.of(context).size.width * 0.03).clamp(10.0, 16.0),
            vertical: (screenHeight * 0.008).clamp(4.0, 8.0),
          ),
          decoration: BoxDecoration(
            color: theme.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            dateText,
            style: TextStyles.caption.copyWith(
              color: theme.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  /// Build fallback avatar for when image fails to load or user is anonymous
  Widget _buildFallbackAvatar(ChatMessage message, double size) {
    return message.isAnonymous
        ? Icon(
            Icons.person,
            color: Colors.white,
            size: size * 0.6,
          )
        : Center(
            child: Text(
              message.senderName.isNotEmpty
                  ? message.senderName[0].toUpperCase()
                  : '؟',
              style: TextStyles.body.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.4,
              ),
            ),
          );
  }

  Widget _buildMessageItem(BuildContext context, CustomThemeData theme,
      ChatMessage message, ChatTextSize chatTextSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate responsive dimensions
    final avatarSize = screenWidth * 0.08; // 8% of screen width, min 24, max 36
    final clampedAvatarSize = avatarSize.clamp(24.0, 36.0);

    // Message bubble widths: current user gets 40% of screen, others get 65%
    final currentUserMaxWidth = screenWidth * 0.5;
    final otherUserMaxWidth = screenWidth * 0.65;

    // Responsive spacing
    final horizontalSpacing = screenWidth * 0.02; // 2% of screen width
    final clampedSpacing = horizontalSpacing.clamp(6.0, 12.0);

    return _AnimatedSwipeMessage(
      key: Key(message.id),
      message: message,
      theme: theme,
      onLongPress: () => _showMessageActionsModal(context, theme, message),
      onSwipeToReply: () => _startReplyToMessage(message),
      child: Container(
        margin:
            EdgeInsets.only(bottom: screenHeight * 0.02), // 2% of screen height
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          textDirection: Directionality.of(context), // Support both RTL and LTR
          children: [
            // For current user messages, add flexible space on the left
            if (message.isCurrentUser) const Expanded(child: SizedBox()),

            // Avatar - only show for other users' messages
            if (!message.isCurrentUser) ...[
              GestureDetector(
                onTap: () => _showUserProfileModal(context, message),
                child: Container(
                  width: clampedAvatarSize,
                  height: clampedAvatarSize,
                  decoration: BoxDecoration(
                    color: message.avatarColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: message.avatarUrl != null && !message.isAnonymous
                      ? ClipOval(
                          child: Image.network(
                            message.avatarUrl!,
                            width: clampedAvatarSize,
                            height: clampedAvatarSize,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildFallbackAvatar(
                                    message, clampedAvatarSize),
                          ),
                        )
                      : _buildFallbackAvatar(message, clampedAvatarSize),
                ),
              ),
              SizedBox(width: clampedSpacing),
            ],

            // For current user messages, add equivalent spacing where avatar would be
            if (message.isCurrentUser) SizedBox(width: clampedSpacing),

            // Message bubble - different sizing for current user vs others
            Container(
              constraints: BoxConstraints(
                maxWidth: message.isCurrentUser
                    ? currentUserMaxWidth
                    : otherUserMaxWidth, // Responsive widths based on screen size
              ),
              child: AnimatedBuilder(
                animation: _highlightAnimation ?? kAlwaysCompleteAnimation,
                builder: (context, child) {
                  final isHighlighted = _highlightedMessageId == message.id;
                  final highlightIntensity =
                      isHighlighted ? (_highlightAnimation?.value ?? 0.0) : 0.0;

                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.03, // 3% of screen width
                      vertical: screenHeight * 0.01, // 1% of screen height
                    ),
                    decoration: BoxDecoration(
                      color: message.moderationStatus ==
                                  ModerationStatusType.blocked &&
                              message.isCurrentUser
                          ? Colors.red
                              .shade50 // Red background for blocked messages
                          : isHighlighted
                              ? Color.lerp(
                                  message.isCurrentUser
                                      ? theme.primary[50]
                                      : theme.grey[50],
                                  theme.primary[100],
                                  highlightIntensity *
                                      0.6, // Fade between normal and highlight color
                                )
                              : (message.isCurrentUser
                                  ? theme.primary[50]
                                  : theme.grey[50]),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isHighlighted
                            ? Color.lerp(
                                message.isCurrentUser
                                    ? theme.primary[200]!
                                    : theme.grey[200]!,
                                theme.primary[400]!,
                                highlightIntensity,
                              )!
                            : (message.isCurrentUser
                                ? theme.primary[200]!
                                : theme.grey[200]!),
                        width: isHighlighted
                            ? (0.5 + highlightIntensity * 1.5)
                            : 0.5,
                      ),
                      boxShadow: isHighlighted && highlightIntensity > 0.3
                          ? [
                              BoxShadow(
                                color: theme.primary[300]!.withValues(
                                    alpha: highlightIntensity * 0.3),
                                blurRadius: 8.0 * highlightIntensity,
                                spreadRadius: 2.0 * highlightIntensity,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Name and time row - sender first, then time
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          textDirection: Directionality.of(context),
                          children: [
                            // Sender name first
                            Text(
                              message.senderName,
                              style: TextStyles.smallBold.copyWith(
                                color: theme.grey[900],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            // Pin indicator
                            if (message.isPinned) ...[
                              const SizedBox(width: 4),
                              Icon(
                                LucideIcons.pin,
                                size: 12,
                                color: theme.tint[600],
                              ),
                            ],

                            Spacer(),

                            // Time second
                            Text(
                              message.time,
                              style: TextStyles.small.copyWith(
                                color: theme.grey[600],
                              ),
                            ),
                          ],
                        ),

                        // Divider line
                        Container(
                          height: 0.5,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: theme.grey[200],
                        ),

                        // Reply preview (show if this message is a reply)
                        if (message.replyToMessage != null)
                          _buildMessageReplyPreview(
                              context, theme, message.replyToMessage!),

                        // Check for blocked message and show special UI to sender
                        if (message.moderationStatus ==
                                ModerationStatusType.blocked &&
                            message.isCurrentUser)
                          _buildBlockedMessageContent(context, theme, message)
                        else if (message.moderationStatus ==
                                ModerationStatusType.manual_review &&
                            message.isCurrentUser)
                          _buildMessageWithReviewIndicator(
                              context, theme, message, chatTextSize)
                        else
                          // Regular message content
                          Text(
                            message.isHidden
                                ? AppLocalizations.of(context)
                                    .translate('message-hidden-by-admin')
                                : message.content,
                            style: chatTextSize.textStyle.copyWith(
                              color: message.isHidden
                                  ? theme.grey[500]
                                  : theme.grey[800],
                              height: 1.5,
                              fontStyle: message.isHidden
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                            textAlign:
                                Directionality.of(context) == TextDirection.rtl
                                    ? TextAlign.right
                                    : TextAlign.left,
                            softWrap: true,
                            overflow: TextOverflow.visible,
                          ),

                        // Message reactions
                        if (message.reactions.isNotEmpty)
                          _buildReactionsDisplay(context, theme, message),
                      ],
                    ),
                  );
                },
              ),
            ),

            // For other user messages, add some spacing on the right
            if (!message.isCurrentUser)
              SizedBox(width: screenWidth * 0.12), // 12% of screen width
          ],
        ),
      ),
    );
  }

  /// Build reactions display widget
  Widget _buildReactionsDisplay(
      BuildContext context, CustomThemeData theme, ChatMessage message) {
    final emojis = message.reactions.keys
        .where((emoji) => (message.reactions[emoji]?.isNotEmpty ?? false))
        .toList();

    if (emojis.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentProfile = ref.watch(currentCommunityProfileProvider).value;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: emojis.map((emoji) {
          final count = message.reactions[emoji]?.length ?? 0;
          final users = message.reactions[emoji] ?? [];
          final isCurrentUserReacted =
              currentProfile != null && users.contains(currentProfile.id);

          return InkWell(
            onTap: () async {
              try {
                await ref
                    .read(messageReactionsServiceProvider.notifier)
                    .toggleReaction(
                      groupId: widget.groupId ?? '',
                      messageId: message.id,
                      emoji: emoji,
                    );
              } catch (e) {
                if (context.mounted) {
                  getErrorSnackBar(context, 'error-toggling-reaction');
                }
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isCurrentUserReacted
                    ? theme.primary[100]!.withValues(alpha: 0.3)
                    : theme.grey[100]!.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrentUserReacted
                      ? theme.primary[400]!
                      : theme.grey[300]!,
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
                    style: TextStyles.caption.copyWith(
                      fontWeight: isCurrentUserReacted
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isCurrentUserReacted
                          ? theme.primary[700]
                          : theme.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Build quick reactions in horizontal scrollable row
  Widget _buildQuickReactions(
    BuildContext context,
    WidgetRef ref,
    CustomThemeData theme,
    ChatMessage message,
  ) {
    // Default reaction emojis (same as in ReactionPicker)
    const emojis = ['👍', '❤️', '😂', '😮', '😢', '🙏', '🎉', '🔥', '👏', '💯'];

    final currentProfile = ref.watch(currentCommunityProfileProvider).value;

    // Find current user's reaction (if any)
    String? currentUserReaction;
    if (currentProfile != null) {
      for (final emoji in message.reactions.keys) {
        if (message.reactions[emoji]?.contains(currentProfile.id) ?? false) {
          currentUserReaction = emoji;
          break;
        }
      }
    }

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: emojis.length,
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final emoji = emojis[index];
          final hasReacted = currentUserReaction == emoji;

          return InkWell(
            onTap: () async {
              try {
                // First, remove existing reaction if any
                if (currentUserReaction != null &&
                    currentUserReaction != emoji) {
                  await ref
                      .read(messageReactionsServiceProvider.notifier)
                      .toggleReaction(
                        groupId: widget.groupId ?? '',
                        messageId: message.id,
                        emoji: currentUserReaction,
                      );
                }

                // Then add/remove the selected emoji
                await ref
                    .read(messageReactionsServiceProvider.notifier)
                    .toggleReaction(
                      groupId: widget.groupId ?? '',
                      messageId: message.id,
                      emoji: emoji,
                    );
                
                // Close modal after successful operation
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop(); // Close modal even on error
                  getErrorSnackBar(context, 'error-toggling-reaction');
                }
                print('Error toggling reaction: $e');
              }
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: hasReacted
                    ? theme.primary[100]!.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _startReplyToMessage(ChatMessage message) {
    setState(() {
      _replyState = ChatReplyState(
        isReplying: true,
        replyToMessage: message,
        replyToMessageId: message.id,
      );
    });

    // Animate in the reply preview
    _replyPreviewController.forward();

    // Keep input field focused if it already was
    // Don't auto-focus to avoid dismissing keyboard unnecessarily
  }

  void _cancelReply() {
    // Animate out the reply preview
    _replyPreviewController.reverse().then((_) {
      setState(() {
        _replyState = const ChatReplyState();
      });
    });
  }

  /// Show user profile modal for chat participants
  void _showUserProfileModal(BuildContext context, ChatMessage message) {
    final profileAsync =
        ref.read(communityProfileByIdProvider(message.senderCpId));

    // Get basic profile info for the modal
    final profile = profileAsync.valueOrNull;
    final isAnonymous = profile?.isAnonymous ?? false;
    final isPlusUser = profile?.isPlusUser ?? false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GroupChatProfileModal(
        communityProfileId: message.senderCpId,
        groupId: widget.groupId ?? 'unknown-group',
        displayName: message.senderName,
        isAnonymous: isAnonymous,
        isPlusUser: isPlusUser,
      ),
    );
  }

  /// Show original message in a simple modal bottom sheet
  void _showOriginalMessageModal(BuildContext context, CustomThemeData theme,
      ChatMessage originalMessage) {
    final screenWidth = MediaQuery.of(context).size.width;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.reply,
                    color: theme.primary[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'الرسالة الأصلية',
                    style: TextStyles.body.copyWith(
                      color: theme.grey[800],
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(
                      Icons.close,
                      color: theme.grey[600],
                      size: 20,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Original message content
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.grey[200]!, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sender info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: originalMessage.avatarColor,
                          backgroundImage: originalMessage.avatarUrl != null &&
                                  !originalMessage.isAnonymous
                              ? NetworkImage(originalMessage.avatarUrl!)
                              : null,
                          child: originalMessage.avatarUrl == null ||
                                  originalMessage.isAnonymous
                              ? (originalMessage.isAnonymous
                                  ? const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 14,
                                    )
                                  : Text(
                                      originalMessage.senderName.isNotEmpty
                                          ? originalMessage.senderName[0]
                                              .toUpperCase()
                                          : '؟',
                                      style: TextStyles.caption.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ))
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          originalMessage.senderName,
                          style: TextStyles.caption.copyWith(
                            color: theme.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          originalMessage.time,
                          style: TextStyles.caption.copyWith(
                            color: theme.grey[500],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Message content
                    Text(
                      originalMessage.isHidden
                          ? AppLocalizations.of(context)
                              .translate('message-hidden-by-admin')
                          : originalMessage.content,
                      style: TextStyles.body.copyWith(
                        color: originalMessage.isHidden
                            ? theme.grey[500]
                            : theme.grey[800],
                        height: 1.4,
                        fontStyle: originalMessage.isHidden
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageActionsModal(
      BuildContext context, CustomThemeData theme, ChatMessage message) {
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final groupId = widget.groupId;
          final isAdminAsyncWatch = groupId != null
              ? ref.watch(isCurrentUserGroupAdminProvider(groupId))
              : const AsyncValue.data(false);
          final isAdminFromWatch = isAdminAsyncWatch.valueOrNull ?? false;

          return Container(
            decoration: BoxDecoration(
              color: theme.backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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

                // Title
                Text(
                  l10n.translate('message-actions'),
                  style: TextStyles.h6.copyWith(
                    color: theme.grey[900],
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 16),

                // Message preview
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: theme.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.grey[200]!, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.senderName,
                          style: TextStyles.smallBold.copyWith(
                            color: theme.grey[900],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message.isHidden
                              ? l10n.translate('message-hidden-by-admin')
                              : message.content,
                          style: TextStyles.body.copyWith(
                            color: message.isHidden
                                ? theme.grey[500]
                                : theme.grey[700],
                            fontStyle: message.isHidden
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Quick reactions section
                _buildQuickReactions(context, ref, theme, message),

                const SizedBox(height: 20),

                // Actions with ActionModal styling
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Admin actions (if user is admin)
                      if (isAdminFromWatch) ...[
                        if (message.isHidden)
                          _buildActionItem(
                            context,
                            theme,
                            icon: LucideIcons.eye,
                            title: l10n.translate('unhide-message'),
                            subtitle:
                                l10n.translate('unhide-message-description'),
                            onTap: () => _unhideMessage(context, message),
                            isDestructive: false,
                          )
                        else
                          _buildActionItem(
                            context,
                            theme,
                            icon: LucideIcons.eyeOff,
                            title: 'إخفاء الرسالة',
                            subtitle:
                                'إخفاء هذه الرسالة من جميع أعضاء المجموعة',
                            onTap: () => _hideMessage(context, message),
                            isDestructive: false,
                          ),
                        const SizedBox(height: 8),
                        // Pin/Unpin action (only for non-blocked, non-hidden, non-deleted messages)
                        if (!message.isHidden &&
                            message.moderationStatus !=
                                ModerationStatusType.blocked) ...[
                          if (message.isPinned)
                            _buildActionItem(
                              context,
                              theme,
                              icon: LucideIcons.pinOff,
                              title: l10n.translate('unpin-message'),
                              subtitle:
                                  l10n.translate('tap-to-view-pinned-message'),
                              onTap: () => _unpinMessage(context, message),
                              isDestructive: false,
                            )
                          else
                            _buildActionItem(
                              context,
                              theme,
                              icon: LucideIcons.pin,
                              title: l10n.translate('pin-message'),
                              subtitle: l10n.translate('max-pinned-messages'),
                              onTap: () => _pinMessage(context, message),
                              isDestructive: false,
                            ),
                          const SizedBox(height: 8),
                        ],
                      ],

                      // Report action
                      _buildActionItem(
                        context,
                        theme,
                        icon: LucideIcons.flag,
                        title: l10n.translate('report-message'),
                        subtitle: 'الإبلاغ عن محتوى غير مناسب',
                        onTap: () =>
                            _showReportOptionsModal(context, theme, message),
                        isDestructive: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Build action item with ActionModal styling
  Widget _buildActionItem(
    BuildContext context,
    CustomThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDestructive,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDestructive ? theme.error[50] : theme.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive ? theme.error[100] : theme.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDestructive ? theme.error[600] : theme.grey[700],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? theme.error[700] : theme.grey[900],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyles.caption.copyWith(
                      color: isDestructive ? theme.error[600] : theme.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show report options modal (expandable)
  void _showReportOptionsModal(
      BuildContext context, CustomThemeData theme, ChatMessage message,
      {bool showingForOther = false}) {
    final l10n = AppLocalizations.of(context);

    final reportActions = <ActionItem>[
      ActionItem(
        icon: LucideIcons.alertTriangle,
        title: l10n.translate('report-inappropriate-content'),
        onTap: () => _submitReport('inappropriate-content', message),
        isDestructive: true,
      ),
      ActionItem(
        icon: LucideIcons.userMinus,
        title: l10n.translate('report-harassment'),
        onTap: () => _submitReport('harassment', message),
        isDestructive: true,
      ),
      ActionItem(
        icon: LucideIcons.shield,
        title: l10n.translate('report-spam'),
        onTap: () => _submitReport('spam', message),
        isDestructive: true,
      ),
      ActionItem(
        icon: LucideIcons.frown,
        title: l10n.translate('report-hate-speech'),
        onTap: () => _submitReport('hate-speech', message),
        isDestructive: true,
      ),
      // Only show "other" option if not already showing for other
      if (!showingForOther)
        ActionItem(
          icon: LucideIcons.moreHorizontal,
          title: l10n.translate('report-other-reason'),
          onTap: () => _submitReport('other', message),
          isDestructive: true,
        ),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ActionModal(
        title: l10n.translate('report-reason'),
        actions: reportActions,
      ),
    );
  }

  /// Hide message (admin only)
  Future<void> _hideMessage(BuildContext context, ChatMessage message) async {
    final l10n = AppLocalizations.of(context);

    try {
      // Get repository reference
      final repository = ref.read(groupChatRepositoryProvider);

      // Show loading indicator
      getSystemSnackBar(context, l10n.translate('hiding-message'));

      // Hide the message
      await repository.hideMessage(widget.groupId ?? '', message.id);

      // Show success message
      getSystemSnackBar(context, l10n.translate('message-hidden-successfully'));
    } catch (e) {
      // Show error message
      getSystemSnackBar(context, l10n.translate('failed-to-hide-message'));
      print('Error hiding message: $e');
    }
  }

  /// Unhide message (admin only)
  Future<void> _unhideMessage(BuildContext context, ChatMessage message) async {
    final l10n = AppLocalizations.of(context);

    try {
      // Get repository reference
      final repository = ref.read(groupChatRepositoryProvider);

      // Show loading indicator
      getSystemSnackBar(context, l10n.translate('unhiding-message'));

      // Unhide the message
      await repository.unhideMessage(widget.groupId ?? '', message.id);

      // Show success message
      getSystemSnackBar(
          context, l10n.translate('message-unhidden-successfully'));
    } catch (e) {
      // Show error message
      getSystemSnackBar(context, l10n.translate('failed-to-unhide-message'));
      print('Error unhiding message: $e');
    }
  }

  /// Show reaction picker for a message
  Future<void> _showReactionPicker(
      BuildContext context, ChatMessage message) async {
    final emoji = await ReactionPicker.show(context);
    if (emoji != null && context.mounted) {
      try {
        await ref.read(messageReactionsServiceProvider.notifier).toggleReaction(
              groupId: widget.groupId ?? '',
              messageId: message.id,
              emoji: emoji,
            );
      } catch (e) {
        if (context.mounted) {
          getErrorSnackBar(context, 'error-toggling-reaction');
        }
        print('Error toggling reaction: $e');
      }
    }
  }

  /// Pin message (admin only)
  Future<void> _pinMessage(BuildContext context, ChatMessage message) async {
    final l10n = AppLocalizations.of(context);

    try {
      await ref.read(pinnedMessagesServiceProvider.notifier).pinMessage(
            groupId: widget.groupId ?? '',
            messageId: message.id,
          );

      if (context.mounted) {
        getSuccessSnackBar(context, 'message-pinned');
      }
    } catch (e) {
      if (context.mounted) {
        if (e.toString().contains('Maximum 3 messages')) {
          getErrorSnackBar(context, 'max-pinned-messages');
        } else {
          getErrorSnackBar(context, 'error-pinning-message');
        }
      }
      print('Error pinning message: $e');
    }
  }

  /// Unpin message (admin only)
  Future<void> _unpinMessage(BuildContext context, ChatMessage message) async {
    final l10n = AppLocalizations.of(context);

    try {
      await ref.read(pinnedMessagesServiceProvider.notifier).unpinMessage(
            groupId: widget.groupId ?? '',
            messageId: message.id,
          );

      if (context.mounted) {
        getSuccessSnackBar(context, 'message-unpinned');
      }
    } catch (e) {
      if (context.mounted) {
        getErrorSnackBar(context, 'error-unpinning-message');
      }
      print('Error unpinning message: $e');
    }
  }

  void _submitReport(String reason, ChatMessage message) {
    if (reason == 'other') {
      // For "other" reason, show the options modal again and then the input modal on top
      Future.microtask(() {
        _showReportOptionsModal(context, AppTheme.of(context), message,
            showingForOther: true);
        // Then show the message report modal on top
        Future.delayed(const Duration(milliseconds: 100), () {
          _showMessageReportModal(reason, message, dismissMultipleModals: true);
        });
      });
    } else {
      // For predefined reasons, submit directly with preset message
      _submitDirectReport(reason, message);
    }
  }

  Future<void> _submitDirectReport(String reason, ChatMessage message) async {
    final l10n = AppLocalizations.of(context);

    // Create preset message based on reason
    final reasonText = l10n.translate('report-$reason');
    final messagePreview = message.content.length > 100
        ? '${message.content.substring(0, 100)}...'
        : message.content;

    final presetMessage = '''
$reasonText

${l10n.translate('reported-message')}:
"$messagePreview"
    '''
        .trim();

    try {
      final reportsNotifier = ref.read(userReportsNotifierProvider.notifier);

      final reportId = await reportsNotifier.submitMessageReport(
        messageId: message.id,
        groupId: widget.groupId ?? 'unknown-group',
        userMessage: presetMessage,
        messageSender: message.senderCpId,
        messageContent: message.content,
      );

      if (mounted) {
        context.pushNamed(
          RouteNames.reportConversation.name,
          pathParameters: {'reportId': reportId},
        );

        getSuccessSnackBar(context, 'message-report-submitted');
      }
    } catch (e) {
      if (mounted) {
        // Extract the localization key from the exception message
        String errorKey = 'report-submission-failed';
        if (e.toString().contains('Exception: ')) {
          final extractedKey = e.toString().replaceFirst('Exception: ', '');
          // Check if it's one of our known error keys
          if ([
            'max-active-reports-reached',
            'message-cannot-be-empty',
            'message-exceeds-character-limit'
          ].contains(extractedKey)) {
            errorKey = extractedKey;
          }
        }
        getErrorSnackBar(context, errorKey);
      }
    }
  }

  void _showMessageReportModal(String reason, ChatMessage message,
      {bool dismissMultipleModals = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MessageReportModal(
        reason: reason,
        message: message,
        groupId: widget.groupId ?? 'unknown-group',
        dismissMultipleModals: dismissMultipleModals,
      ),
    );
  }

  Widget _buildInputArea(
      BuildContext context, CustomThemeData theme, AppLocalizations l10n) {
    final screenWidth = MediaQuery.of(context).size.width;
    final responsivePadding = (screenWidth * 0.04).clamp(12.0, 20.0);

    return Container(
      padding: EdgeInsets.all(responsivePadding),
      decoration: BoxDecoration(
        color: theme.grey[50],
        border: Border(
          top: BorderSide(color: theme.grey[200]!, width: 1),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply preview (show when replying)
            if (_replyState.isReplying && _replyState.replyToMessage != null)
              _buildReplyPreview(context, theme, l10n),

            // Input area
            WidgetsContainer(
              padding: EdgeInsets.symmetric(
                horizontal: (screenWidth * 0.03).clamp(8.0, 16.0),
                vertical: (screenWidth * 0.02).clamp(6.0, 10.0),
              ),
              backgroundColor: theme.postInputBackgound,
              borderSide: BorderSide(color: theme.grey[300]!, width: 0.5),
              borderRadius: BorderRadius.circular(12.5),
              child: Row(
                children: [
                  // User avatar
                  _buildUserAvatar(context, theme),

                  SizedBox(width: (screenWidth * 0.025).clamp(8.0, 12.0)),

                  // Text input
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !_isSubmitting,
                      maxLines: null,
                      minLines: 1,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: l10n.translate('type-your-message'),
                        hintStyle: TextStyles.caption.copyWith(
                          color: theme.grey[700],
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      style: TextStyles.body.copyWith(
                        color: theme.grey[900],
                        fontSize: 14,
                      ),
                      onSubmitted: _handleSubmit,
                    ),
                  ),

                  // Send button
                  if (_messageController.text.isNotEmpty || _isSubmitting) ...[
                    SizedBox(width: (screenWidth * 0.02).clamp(6.0, 10.0)),
                    GestureDetector(
                      onTap: _isSubmitting
                          ? null
                          : () => _handleSubmit(_messageController.text),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: (screenWidth * 0.03).clamp(10.0, 16.0),
                          vertical: (screenWidth * 0.015).clamp(4.0, 8.0),
                        ),
                        decoration: BoxDecoration(
                          color: _isSubmitting
                              ? theme.grey[400]
                              : theme.primary[600],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _isSubmitting
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: Spinner(
                                      strokeWidth: 2,
                                      valueColor: theme.grey[100]!,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    l10n.translate('send'),
                                    style: TextStyles.caption.copyWith(
                                      color: theme.grey[100],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.send,
                                    size: 14,
                                    color: theme.grey[100],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.translate('send'),
                                    style: TextStyles.caption.copyWith(
                                      color: theme.grey[100],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview(
      BuildContext context, CustomThemeData theme, AppLocalizations l10n) {
    final replyMessage = _replyState.replyToMessage!;
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: _replyPreviewAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
              0,
              (1 - _replyPreviewAnimation.value) *
                  (screenWidth * 0.15)), // Responsive slide distance
          child: Opacity(
            opacity: _replyPreviewAnimation.value,
            child: Container(
              margin: EdgeInsets.only(
                  bottom: (screenWidth * 0.02).clamp(6.0, 10.0)),
              padding: EdgeInsets.all((screenWidth * 0.03).clamp(10.0, 16.0)),
              decoration: BoxDecoration(
                color: theme.primary[50],
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(color: theme.primary[500]!, width: 3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.reply,
                              size: 16,
                              color: theme.primary[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.translate('replying-to'),
                              style: TextStyles.caption.copyWith(
                                color: theme.primary[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              replyMessage.senderName,
                              style: TextStyles.caption.copyWith(
                                color: theme.primary[700],
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          replyMessage.content,
                          style: TextStyles.caption.copyWith(
                            color: theme.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _cancelReply,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.x,
                        size: 14,
                        color: theme.grey[600],
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

  Widget _buildMessageReplyPreview(BuildContext context, CustomThemeData theme,
      ChatMessage originalMessage) {
    return GestureDetector(
      onTap: () {
        // Show original message in a simple modal
        _showOriginalMessageModal(context, theme, originalMessage);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.grey[100],
          borderRadius: BorderRadius.circular(6),
          border: Border(
            left: BorderSide(color: theme.primary[400]!, width: 2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.reply,
                  size: 12,
                  color: theme.primary[600],
                ),
                const SizedBox(width: 4),
                Text(
                  originalMessage.senderName,
                  style: TextStyles.caption.copyWith(
                    color: theme.primary[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                // Add visual indicator that this is tappable
                Icon(
                  LucideIcons.externalLink,
                  size: 10,
                  color: theme.primary[500],
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              originalMessage.isHidden
                  ? AppLocalizations.of(context)
                      .translate('message-hidden-by-admin')
                  : originalMessage.content,
              style: TextStyles.small.copyWith(
                color: originalMessage.isHidden
                    ? theme.grey[400]
                    : theme.grey[600],
                // fontSize: 11,
                height: 1.3,
                fontStyle: originalMessage.isHidden
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(BuildContext context, CustomThemeData theme) {
    final user = FirebaseAuth.instance.currentUser;
    final userImageUrl = user?.photoURL;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive avatar radius: 3.5% of screen width, clamped between 12-18
    final avatarRadius = (screenWidth * 0.035).clamp(12.0, 18.0);
    final iconSize = avatarRadius * 1.3; // Icon size proportional to avatar

    return CircleAvatar(
      radius: avatarRadius,
      backgroundColor: theme.primary[100],
      backgroundImage: userImageUrl != null ? NetworkImage(userImageUrl) : null,
      child: userImageUrl == null
          ? Icon(
              Icons.person,
              size: iconSize,
              color: theme.primary[700],
            )
          : null,
    );
  }

  Future<void> _handleSubmit(String text) async {
    if (text.trim().isEmpty || _isSubmitting || widget.groupId == null) return;

    // Use QuickActionGuard to check sendMessage feature access
    // await checkFeatureAccessAndShowBanSnackbar(
    //   context,
    //   ref,
    //   AppFeaturesConfig.sendMessage,
    //   customMessage:
    //       AppLocalizations.of(context).translate('send-message-restricted'),
    // ).then((canAccess) async {
    //   if (!canAccess) return;

    // Show loader immediately so the user gets instant feedback
    setState(() {
      _isSubmitting = true;
    });

    // Give the UI a chance to rebuild before heavy async work starts
    await Future.delayed(Duration.zero);

    try {
      final groupChatService = ref.read(groupChatServiceProvider.notifier);

      // Prepare reply information if replying
      String? quotedPreview;
      if (_replyState.isReplying && _replyState.replyToMessage != null) {
        quotedPreview = ref.read(
            generateQuotedPreviewProvider(_replyState.replyToMessage!.content));
      }

      // Send message via service
      await groupChatService.sendMessage(
        groupId: widget.groupId!,
        body: text.trim(),
        replyToMessageId: _replyState.replyToMessageId,
        quotedPreview: quotedPreview,
      );

      // Clear the input and reply state
      _messageController.clear();
      if (_replyState.isReplying) {
        setState(() {
          _replyState = const ChatReplyState();
        });
        _replyPreviewController.value = 1.0; // Reset animation for next reply
      }

      // Scroll to bottom after a short delay to allow messages to load
      // For reversed list, scroll to position 0 (which is the bottom/latest)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0, // For reversed list, 0 is the bottom (latest messages)
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      });
    } catch (error) {
      // Show error using the proper snackbar system
      if (mounted) {
        if (error.toString().contains('already in progress')) {
          getSystemSnackBar(context, 'يتم إرسال رسالة أخرى، يرجى الانتظار');
        } else {
          getSystemSnackBar(context,
              AppLocalizations.of(context).translate('message-send-failed'));
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
    // });
  }

  /// Blocked message UI (only visible to sender)
  Widget _buildBlockedMessageContent(
      BuildContext context, CustomThemeData theme, ChatMessage message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.block, color: Colors.red, size: 18),
            const SizedBox(width: 8),
            Text(
              'رسالة محظورة', // 'Message Blocked' in Arabic
              style: TextStyles.footnote.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (message.moderationReason != null) ...[
          const SizedBox(height: 8),
          Text(
            message.moderationReason!,
            style: TextStyles.small.copyWith(
              color: Colors.red.shade700,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'هذه الرسالة تنتهك إرشادات المجتمع وهي مرئية لك فقط.', // 'This message violates community guidelines and is only visible to you.' in Arabic
          style: TextStyles.caption.copyWith(
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  /// Manual review indicator (subtle)
  Widget _buildMessageWithReviewIndicator(BuildContext context,
      CustomThemeData theme, ChatMessage message, ChatTextSize chatTextSize) {
    return Stack(
      children: [
        // Regular message content
        Text(
          message.isHidden
              ? AppLocalizations.of(context)
                  .translate('message-hidden-by-admin')
              : message.content,
          style: chatTextSize.textStyle.copyWith(
            color: message.isHidden ? theme.grey[500] : theme.grey[800],
            height: 1.5,
            fontStyle: message.isHidden ? FontStyle.italic : FontStyle.normal,
          ),
          textAlign: Directionality.of(context) == TextDirection.rtl
              ? TextAlign.right
              : TextAlign.left,
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
        // Review indicator overlay
        Positioned(
          top: 0,
          right: Directionality.of(context) == TextDirection.rtl ? 0 : null,
          left: Directionality.of(context) == TextDirection.ltr ? 0 : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'قيد المراجعة', // 'Under Review' in Arabic
              style: TextStyles.tiny.copyWith(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Navigate to chat settings screen
  void _navigateToChatSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GroupChatSettingsScreen(),
      ),
    );
  }

  // Demo messages method removed - now using real-time Firestore data
}

/// Animated swipe message widget for reply functionality
class _AnimatedSwipeMessage extends StatefulWidget {
  final ChatMessage message;
  final CustomThemeData theme;
  final Widget child;
  final VoidCallback onLongPress;
  final VoidCallback onSwipeToReply;

  const _AnimatedSwipeMessage({
    super.key,
    required this.message,
    required this.theme,
    required this.child,
    required this.onLongPress,
    required this.onSwipeToReply,
  });

  @override
  State<_AnimatedSwipeMessage> createState() => _AnimatedSwipeMessageState();
}

class _AnimatedSwipeMessageState extends State<_AnimatedSwipeMessage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _replyIconAnimation;

  double _dragOffset = 0.0;
  late double _maxSwipeDistance;
  late double _replyThreshold;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _replyIconAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handlePanStart(DragStartDetails details) {
    // Start of pan gesture - could be used for haptic feedback
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final delta = details.delta.dx;

    // Only allow swipe in the correct direction (left for LTR, right for RTL)
    final isCorrectDirection = isRTL ? delta > 0 : delta < 0;

    if (isCorrectDirection) {
      setState(() {
        _dragOffset = (_dragOffset + (isRTL ? delta : -delta))
            .clamp(0.0, _maxSwipeDistance);
      });

      // Update animation progress based on drag offset
      final progress = (_dragOffset / _maxSwipeDistance).clamp(0.0, 1.0);
      _animationController.value = progress;
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    final shouldTriggerReply = _dragOffset >= _replyThreshold;

    if (shouldTriggerReply) {
      // Trigger reply
      widget.onSwipeToReply();
      // Animate to show completion
      _animationController.forward().then((_) {
        _resetAnimation();
      });
    } else {
      // Animate back to original position
      _resetAnimation();
    }
  }

  void _resetAnimation() {
    _animationController.reverse().then((_) {
      setState(() {
        _dragOffset = 0.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate responsive swipe distances: 20% of screen width for max, 15% for threshold
    _maxSwipeDistance = (screenWidth * 0.2).clamp(60.0, 100.0);
    _replyThreshold = (screenWidth * 0.15).clamp(45.0, 75.0);

    return GestureDetector(
      onLongPress: widget.onLongPress,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: Stack(
        children: [
          // Reply icon that appears during swipe
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _replyIconAnimation,
              builder: (context, child) {
                final iconOpacity = _replyIconAnimation.value.clamp(0.0, 1.0);
                final iconScale = _replyIconAnimation.value.clamp(0.0, 1.0);

                if (iconOpacity == 0) return const SizedBox.shrink();

                return Align(
                  alignment:
                      isRTL ? Alignment.centerLeft : Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: isRTL ? 20 : 0,
                      right: isRTL ? 0 : 20,
                    ),
                    child: Transform.scale(
                      scale: iconScale,
                      child: Opacity(
                        opacity: iconOpacity,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: widget.theme.primary[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.reply,
                            size: 20,
                            color: widget.theme.primary[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Message content with slide animation
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              final slideValue = _dragOffset * (isRTL ? 1 : -1);

              return Transform.translate(
                offset: Offset(slideValue, 0),
                child: widget.child,
              );
            },
          ),
        ],
      ),
    );
  }
}
