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

/// Model for chat message
class ChatMessage {
  final String id;
  final String content;
  final String senderName;
  final String time;
  final DateTime dateTime;
  final bool isCurrentUser;
  final Color avatarColor;
  final ChatMessage? replyToMessage; // The message being replied to
  final String? replyToMessageId; // ID of the message being replied to

  const ChatMessage({
    required this.id,
    required this.content,
    required this.senderName,
    required this.time,
    required this.dateTime,
    required this.isCurrentUser,
    required this.avatarColor,
    this.replyToMessage,
    this.replyToMessageId,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    String? senderName,
    String? time,
    DateTime? dateTime,
    bool? isCurrentUser,
    Color? avatarColor,
    ChatMessage? replyToMessage,
    String? replyToMessageId,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      senderName: senderName ?? this.senderName,
      time: time ?? this.time,
      dateTime: dateTime ?? this.dateTime,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      avatarColor: avatarColor ?? this.avatarColor,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
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
      appBar: appBar(context, ref, "group-chat", false, true),
      body: Column(
        children: [
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
            final messages = _convertEntitiesToChatMessages(messageEntities);

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

  Widget _buildMessageListView(BuildContext context, CustomThemeData theme,
      ChatTextSize chatTextSize, List<ChatMessage> messages) {
    // Reverse ListView to show latest messages at bottom (like WhatsApp)
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Reverse messages so latest appears at bottom
    final reversedMessages = messages.reversed.toList();

    // Auto-scroll to bottom when messages first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && messages.isNotEmpty) {
        _scrollController
            .jumpTo(0); // Jump to bottom (index 0 in reversed list)
      }
    });

    return ListView.builder(
      controller: _scrollController,
      reverse: true, // This makes the list start from bottom
      padding: EdgeInsets.symmetric(
        horizontal: (screenWidth * 0.04).clamp(12.0, 20.0),
        vertical: (screenHeight * 0.01).clamp(6.0, 12.0),
      ),
      itemCount: reversedMessages.length,
      itemBuilder: (context, index) {
        final message = reversedMessages[index];
        final nextMessage = index < reversedMessages.length - 1
            ? reversedMessages[index + 1]
            : null;

        return Column(
          children: [
            // Show date separator - fixed logic for reverse ListView
            // We want the separator ABOVE the first message of each day (chronologically)
            if (index ==
                    reversedMessages.length -
                        1 || // Last item (chronologically first)
                (nextMessage != null &&
                    !_isSameDay(message.dateTime, nextMessage.dateTime)))
              _buildDateSeparator(
                  context,
                  theme,
                  AppLocalizations.of(context),
                  nextMessage != null &&
                          !_isSameDay(message.dateTime, nextMessage.dateTime)
                      ? nextMessage.dateTime
                      : message.dateTime),

            _buildMessageItem(context, theme, message, chatTextSize),
          ],
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
                _buildDateSeparator(
                    context,
                    theme,
                    AppLocalizations.of(context),
                    nextMessage != null &&
                            !_isSameDay(message.dateTime, nextMessage.dateTime)
                        ? nextMessage.dateTime
                        : message.dateTime),

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
      List<GroupMessageEntity> entities) {
    final currentProfileAsync = ref.read(currentCommunityProfileProvider);
    final currentCpId = currentProfileAsync.valueOrNull?.id;

    // Get repository for cached profile data
    final repository = ref.read(groupChatRepositoryProvider);

    // Remove duplicates by ID first
    final uniqueEntities = <String, GroupMessageEntity>{};
    for (final entity in entities.where((entity) => entity.isVisible)) {
      uniqueEntities[entity.id] = entity;
    }

    return uniqueEntities.values.map((entity) {
      final isCurrentUser = entity.senderCpId == currentCpId;

      // Get sender info from repository cache (already fetched with messages)
      final senderDisplayName =
          repository.getSenderDisplayName(entity.senderCpId);
      final senderAvatarColor =
          repository.getSenderAvatarColor(entity.senderCpId);

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

          replyToMessage = ChatMessage(
            id: replyTarget.id,
            content: replyTarget.body,
            senderName: replyTargetDisplayName,
            time: _formatTime(replyTarget.createdAt),
            dateTime: replyTarget.createdAt,
            isCurrentUser: replyTarget.senderCpId == currentCpId,
            avatarColor: replyTargetAvatarColor,
          );
        }
      }

      return ChatMessage(
        id: entity.id,
        content: entity.body,
        senderName: senderDisplayName,
        time: _formatTime(entity.createdAt),
        dateTime: entity.createdAt,
        isCurrentUser: isCurrentUser,
        avatarColor: senderAvatarColor,
        replyToMessage: replyToMessage,
        replyToMessageId: entity.replyToMessageId,
      );
    }).toList();
  }

  /// Format DateTime to time string
  String _formatTime(DateTime dateTime) {
    // TODO: Use proper localization and user's locale
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'مساءً' : 'صباحًا';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

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
    final messageDate = DateTime(date.year, date.month, date.day);
    final screenHeight = MediaQuery.of(context).size.height;

    String dateText;
    if (messageDate == today) {
      dateText = l10n.translate('today');
    } else if (messageDate == yesterday) {
      dateText = l10n.translate('yesterday');
    } else {
      final isRTL = Directionality.of(context) == TextDirection.rtl;
      if (isRTL) {
        dateText = '${date.day}/${date.month}/${date.year}';
      } else {
        dateText = '${date.month}/${date.day}/${date.year}';
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

  Widget _buildMessageItem(BuildContext context, CustomThemeData theme,
      ChatMessage message, ChatTextSize chatTextSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate responsive dimensions
    final avatarSize = screenWidth * 0.08; // 8% of screen width, min 24, max 36
    final clampedAvatarSize = avatarSize.clamp(24.0, 36.0);

    // Message bubble widths: current user gets 40% of screen, others get 65%
    final currentUserMaxWidth = screenWidth * 0.65;
    final otherUserMaxWidth = screenWidth * 0.65;

    // Responsive spacing
    final horizontalSpacing = screenWidth * 0.02; // 2% of screen width
    final clampedSpacing = horizontalSpacing.clamp(6.0, 12.0);

    return _AnimatedSwipeMessage(
      key: Key(message.id),
      message: message,
      theme: theme,
      onLongPress: () => _showReportModal(context, theme, message),
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
              Container(
                width: clampedAvatarSize,
                height: clampedAvatarSize,
                decoration: BoxDecoration(
                  color: message.avatarColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
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
                      color: isHighlighted
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
                                color: theme.primary[300]!
                                    .withOpacity(highlightIntensity * 0.3),
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

                            Spacer(),

                            // Time second
                            Text(
                              message.time,
                              style: TextStyles.caption.copyWith(
                                color: theme.grey[300],
                                fontSize: 8,
                                fontWeight: FontWeight.w500,
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

                        // Message content with proper text wrapping and dynamic text size
                        Text(
                          message.content,
                          style: chatTextSize.textStyle.copyWith(
                            color: theme.grey[800],
                            height: 1.5,
                          ),
                          textAlign:
                              Directionality.of(context) == TextDirection.rtl
                                  ? TextAlign.right
                                  : TextAlign.left,
                          softWrap: true,
                          overflow: TextOverflow.visible,
                        ),
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

  /// Finds the index of a message in the current paginated list by its ID
  int? _findMessageIndex(String messageId) {
    if (widget.groupId == null) return null;

    final paginatedAsync =
        ref.read(groupChatMessagesPaginatedProvider(widget.groupId!));
    return paginatedAsync.maybeWhen(
      data: (paginatedResult) {
        final messages =
            _convertEntitiesToChatMessages(paginatedResult.messages);
        // Sort messages by creation time (latest first for reverse ListView)
        final sortedMessages = List<ChatMessage>.from(messages);
        sortedMessages.sort((a, b) => b.dateTime.compareTo(a.dateTime));

        final index =
            sortedMessages.indexWhere((message) => message.id == messageId);
        return index == -1 ? null : index; // Return null if not found
      },
      orElse: () => null,
    );
  }

  /// Smart message navigation with pagination support
  Future<void> _navigateToMessage(String messageId) async {
    if (widget.groupId == null) return;

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('جاري البحث عن الرسالة...'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    // First check if message is already loaded
    final currentIndex = _findMessageIndex(messageId);
    if (currentIndex != null) {
      // Message is already loaded, just scroll to it
      _scrollToMessage(messageId);
      return;
    }

    // Message not found in current loaded messages, load more until found
    await _loadMessagesUntilFound(messageId);
  }

  /// Load more message pages until target message is found
  Future<void> _loadMessagesUntilFound(String messageId) async {
    if (widget.groupId == null) return;

    try {
      // Get the paginated messages provider
      final paginatedProvider =
          groupChatMessagesPaginatedProvider(widget.groupId!);
      final paginatedNotifier = ref.read(paginatedProvider.notifier);

      const maxAttempts = 10; // Prevent infinite loops
      int attempts = 0;

      while (attempts < maxAttempts) {
        attempts++;

        // Check current paginated state
        final paginatedState = ref.read(paginatedProvider);

        await paginatedState.when(
          loading: () async {
            // Wait for loading to complete
            await Future.delayed(const Duration(milliseconds: 500));
          },
          error: (error, stack) async {
            print('Error loading paginated messages: $error');
            return; // Exit on error
          },
          data: (paginatedResult) async {
            // Check if target message is in this batch
            final messages =
                _convertEntitiesToChatMessages(paginatedResult.messages);
            final found = messages.any((msg) => msg.id == messageId);

            if (found) {
              // Found the message! Now scroll to it
              // Wait a moment for UI to update
              await Future.delayed(const Duration(milliseconds: 200));
              _scrollToMessage(messageId);
              return;
            }

            // Message not found, check if we can load more
            if (paginatedResult.hasMore) {
              print(
                  'Message not found in current batch, loading more... (attempt $attempts)');
              await paginatedNotifier.loadMore();
            } else {
              // No more messages to load, message doesn't exist
              print('Message $messageId not found in chat history');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('الرسالة المطلوبة غير موجودة أو محذوفة'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
              return;
            }
          },
        );

        // Small delay between attempts to avoid overwhelming the system
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // If we reach here, we hit max attempts
      print('Max attempts reached while searching for message $messageId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر العثور على الرسالة'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      print('Error in _loadMessagesUntilFound: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطأ في البحث عن الرسالة'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Scrolls to a specific message by its ID with smooth animation
  void _scrollToMessage(String messageId) {
    final messageIndex = _findMessageIndex(messageId);
    if (messageIndex == null ||
        messageIndex == -1 ||
        !_scrollController.hasClients) return;

    // Set the message to be highlighted
    setState(() {
      _highlightedMessageId = messageId;
    });

    // Calculate approximate item height and position
    // Each message item has variable height, but we can estimate
    final estimatedItemHeight =
        120.0; // Approximate height per message including spacing
    final targetPosition = messageIndex * estimatedItemHeight;

    // Animate to the target position
    // For reversed list, position is calculated from top (0)
    _scrollController
        .animateTo(
      targetPosition.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    )
        .then((_) {
      // Start highlight animation after scroll completes
      _highlightController?.forward().then((_) {
        // Clear highlight after animation completes
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _highlightedMessageId = null;
            });
            _highlightController?.reset();
          }
        });
      });
    });
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
                          child: Text(
                            originalMessage.senderName.isNotEmpty
                                ? originalMessage.senderName[0].toUpperCase()
                                : '؟',
                            style: TextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
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
                      originalMessage.content,
                      style: TextStyles.body.copyWith(
                        color: theme.grey[800],
                        height: 1.4,
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

  void _showReportModal(
      BuildContext context, CustomThemeData theme, ChatMessage message) {
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.translate('report-message'),
                        style: TextStyles.h5.copyWith(
                          color: theme.grey[900],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        LucideIcons.x,
                        color: theme.grey[600],
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),

              // Message preview
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                        message.content,
                        style: TextStyles.body.copyWith(
                          color: theme.grey[700],
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Report reasons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('report-reason'),
                      style: TextStyles.body.copyWith(
                        color: theme.grey[900],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildReportOption(
                        context,
                        theme,
                        l10n,
                        'report-inappropriate-content',
                        LucideIcons.alertTriangle),
                    _buildReportOption(context, theme, l10n,
                        'report-harassment', LucideIcons.userMinus),
                    _buildReportOption(context, theme, l10n, 'report-spam',
                        LucideIcons.shield),
                    _buildReportOption(context, theme, l10n,
                        'report-hate-speech', LucideIcons.frown),
                    _buildReportOption(context, theme, l10n,
                        'report-other-reason', LucideIcons.moreHorizontal),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportOption(BuildContext context, CustomThemeData theme,
      AppLocalizations l10n, String reasonKey, IconData icon) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        _showReportConfirmation(context, theme, l10n, reasonKey);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.grey[200]!, width: 1),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: theme.grey[600],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.translate(reasonKey),
                style: TextStyles.body.copyWith(
                  color: theme.grey[900],
                ),
              ),
            ),
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? LucideIcons.chevronLeft
                  : LucideIcons.chevronRight,
              color: theme.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showReportConfirmation(BuildContext context, CustomThemeData theme,
      AppLocalizations l10n, String reasonKey) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                Text(
                  l10n.translate('confirm-report'),
                  style: TextStyles.h5.copyWith(
                    color: theme.grey[900],
                  ),
                ),

                const SizedBox(height: 16),

                // Message
                Text(
                  l10n.translate('confirm-report-message'),
                  style: TextStyles.body.copyWith(
                    color: theme.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: theme.grey[300]!, width: 1),
                          ),
                        ),
                        child: Text(
                          l10n.translate('cancel'),
                          style: TextStyles.body.copyWith(
                            color: theme.grey[600],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _submitReport(context, l10n, reasonKey);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary[500],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          l10n.translate('confirm-submit-report'),
                          style: TextStyles.body.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitReport(
      BuildContext context, AppLocalizations l10n, String reason) {
    // TODO: Implement actual reporting functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.translate('report-submitted')),
        backgroundColor: Colors.green,
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
              originalMessage.content,
              style: TextStyles.small.copyWith(
                color: theme.grey[600],
                // fontSize: 11,
                height: 1.3,
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
          getSystemSnackBar(context, 'فشل في إرسال الرسالة');
        }
      }
      print('Error sending message: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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
