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
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _replyPreviewController.dispose();
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
    final messages = _getDemoMessages();

    // Simple fallback to ensure messages show up
    if (messages.isEmpty) {
      return Center(
        child: Text(
          'لا توجد رسائل',
          style: TextStyles.body.copyWith(color: theme.grey[600]),
        ),
      );
    }

    // Simple ListView with date separators
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(
        horizontal: (screenWidth * 0.04).clamp(12.0, 20.0),
        vertical: (screenHeight * 0.01).clamp(6.0, 12.0),
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return Column(
          children: [
            // Show date separator for first message or when date changes
            if (index == 0 ||
                !_isSameDay(message.dateTime, messages[index - 1].dateTime))
              _buildDateSeparator(context, theme, l10n, message.dateTime),

            _buildMessageItem(context, theme, message, chatTextSize),
          ],
        );
      },
    );
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
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.03, // 3% of screen width
                  vertical: screenHeight * 0.01, // 1% of screen height
                ),
                decoration: BoxDecoration(
                  color: message.isCurrentUser
                      ? theme.primary[50]
                      : theme.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: message.isCurrentUser
                          ? theme.primary[200]!
                          : theme.grey[200]!,
                      width: 0.5),
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
                      textAlign: Directionality.of(context) == TextDirection.rtl
                          ? TextAlign.right
                          : TextAlign.left,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ],
                ),
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

    // Auto-focus the input field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  void _cancelReply() {
    // Animate out the reply preview
    _replyPreviewController.reverse().then((_) {
      setState(() {
        _replyState = const ChatReplyState();
      });
    });
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
    return Container(
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
    if (text.trim().isEmpty || _isSubmitting) return;

    // Show loader immediately so the user gets instant feedback
    setState(() {
      _isSubmitting = true;
    });

    // Give the UI a chance to rebuild before heavy async work starts
    await Future.delayed(Duration.zero);

    try {
      // TODO: Implement actual message sending to group chat
      // Include reply information if replying
      if (_replyState.isReplying) {
        // TODO: Send message with reply information
        print(
            'Sending reply to message ${_replyState.replyToMessageId}: $text');
      } else {
        // TODO: Send regular message
        print('Sending message: $text');
      }

      await Future.delayed(
          const Duration(seconds: 1)); // Simulate network request

      // Clear the input and reply state
      _messageController.clear();
      if (_replyState.isReplying) {
        setState(() {
          _replyState = const ChatReplyState();
        });
        _replyPreviewController.value = 1.0; // Reset animation for next reply
      }

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (error) {
      // Show error message if needed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  List<ChatMessage> _getDemoMessages() {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final twoDaysAgo = now.subtract(const Duration(days: 2));

    return [
      // Messages from two days ago
      ChatMessage(
        id: '1',
        content: 'مرحبًا بالجميع! كيف حالكم اليوم؟',
        senderName: 'أحمد محمد',
        time: '09:15 صباحًا',
        dateTime: twoDaysAgo.copyWith(hour: 9, minute: 15),
        isCurrentUser: false,
        avatarColor: Colors.green,
      ),
      ChatMessage(
        id: '2',
        content: 'الحمد لله، نحن بخير. كيف كانت جلسة التمارين اليوم؟',
        senderName: 'سيف حمد',
        time: '09:30 صباحًا',
        dateTime: twoDaysAgo.copyWith(hour: 9, minute: 30),
        isCurrentUser: false,
        avatarColor: Colors.orange,
      ),

      // Messages from yesterday
      ChatMessage(
        id: '3',
        content:
            'المجد للتعافي وكل ما يتعلق بالتعافي من كل أمور التعافي المتعافية. العقد شريعة المتعاقدين. بدون التعافي لا يوجد تشافي',
        senderName: 'سيف حمد',
        time: '14:23 مساءً',
        dateTime: yesterday.copyWith(hour: 14, minute: 23),
        isCurrentUser: false,
        avatarColor: Colors.orange,
      ),
      ChatMessage(
        id: '4',
        content: 'شكرًا لك على هذه الكلمات المحفزة',
        senderName: 'يوسف يعقوب',
        time: '14:30 مساءً',
        dateTime: yesterday.copyWith(hour: 14, minute: 30),
        isCurrentUser: true,
        avatarColor: Colors.blue,
        replyToMessage: ChatMessage(
          id: '3',
          content:
              'المجد للتعافي وكل ما يتعلق بالتعافي من كل أمور التعافي المتعافية.',
          senderName: 'سيف حمد',
          time: '14:23 مساءً',
          dateTime: yesterday.copyWith(hour: 14, minute: 23),
          isCurrentUser: false,
          avatarColor: Colors.orange,
        ),
        replyToMessageId: '3',
      ),
      ChatMessage(
        id: '5',
        content: 'أتفق معك تمامًا. التعافي رحلة تحتاج إلى صبر ومثابرة.',
        senderName: 'فاطمة حسن',
        time: '15:00 مساءً',
        dateTime: yesterday.copyWith(hour: 15, minute: 0),
        isCurrentUser: false,
        avatarColor: Colors.purple,
      ),

      // Messages from today
      ChatMessage(
        id: '6',
        content: 'صباح الخير جميعًا! كيف بدأتم يومكم؟',
        senderName: 'محمد علي',
        time: '08:00 صباحًا',
        dateTime: now.copyWith(hour: 8, minute: 0),
        isCurrentUser: false,
        avatarColor: Colors.teal,
      ),
      ChatMessage(
        id: '7',
        content: 'صباح النور! بدأت اليوم بتمارين التأمل',
        senderName: 'يوسف يعقوب',
        time: '08:15 صباحًا',
        dateTime: now.copyWith(hour: 8, minute: 15),
        isCurrentUser: true,
        avatarColor: Colors.blue,
      ),
      ChatMessage(
        id: '8',
        content: 'ممتاز! التأمل يساعد كثيرًا في بداية اليوم',
        senderName: 'أحمد محمد',
        time: '08:20 صباحًا',
        dateTime: now.copyWith(hour: 8, minute: 20),
        isCurrentUser: false,
        avatarColor: Colors.green,
        replyToMessage: ChatMessage(
          id: '7',
          content: 'صباح النور! بدأت اليوم بتمارين التأمل',
          senderName: 'يوسف يعقوب',
          time: '08:15 صباحًا',
          dateTime: now.copyWith(hour: 8, minute: 15),
          isCurrentUser: true,
          avatarColor: Colors.blue,
        ),
        replyToMessageId: '7',
      ),
      ChatMessage(
        id: '9',
        content: 'هل يمكن أن نتشارك تجاربنا مع التمارين اليومية؟',
        senderName: 'سيف حمد',
        time: '10:45 صباحًا',
        dateTime: now.copyWith(hour: 10, minute: 45),
        isCurrentUser: false,
        avatarColor: Colors.orange,
      ),
      ChatMessage(
        id: '10',
        content: 'فكرة رائعة! أنا أمارس الرياضة كل صباح',
        senderName: 'يوسف يعقوب',
        time: '11:00 صباحًا',
        dateTime: now.copyWith(hour: 11, minute: 0),
        isCurrentUser: true,
        avatarColor: Colors.blue,
      ),
    ];
  }
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
