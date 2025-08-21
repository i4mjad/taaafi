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

/// Model for chat message
class ChatMessage {
  final String id;
  final String content;
  final String senderName;
  final String time;
  final DateTime dateTime;
  final bool isCurrentUser;
  final Color avatarColor;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.senderName,
    required this.time,
    required this.dateTime,
    required this.isCurrentUser,
    required this.avatarColor,
  });
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

class GroupChatScreen extends ConsumerStatefulWidget {
  final String? groupId;

  const GroupChatScreen({super.key, this.groupId});

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, "group-chat", false, true),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _buildMessagesList(context, theme, l10n),
          ),

          // Input area
          _buildInputArea(context, theme, l10n),
        ],
      ),
    );
  }

  Widget _buildMessagesList(
      BuildContext context, CustomThemeData theme, AppLocalizations l10n) {
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
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return Column(
          children: [
            // Show date separator for first message or when date changes
            if (index == 0 ||
                !_isSameDay(message.dateTime, messages[index - 1].dateTime))
              _buildDateSeparator(context, theme, l10n, message.dateTime),

            _buildMessageItem(context, theme, message),
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
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  Widget _buildMessageItem(
      BuildContext context, CustomThemeData theme, ChatMessage message) {
    return GestureDetector(
      onLongPress: () => _showReportModal(context, theme, message),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          textDirection: Directionality.of(context), // Support both RTL and LTR
          children: [
            // For current user messages, add flexible space on the left
            if (message.isCurrentUser) const Expanded(child: SizedBox()),

            // Avatar - only show for other users' messages
            if (!message.isCurrentUser) ...[
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: message.avatarColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
              ),
              const SizedBox(width: 8),
            ],

            // For current user messages, add equivalent spacing where avatar would be
            if (message.isCurrentUser) const SizedBox(width: 8),

            // Message bubble - different sizing for current user vs others
            Container(
              constraints: BoxConstraints(
                maxWidth: message.isCurrentUser
                    ? 152
                    : 239, // Match Figma design widths
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

                    // Message content with proper text wrapping
                    Text(
                      message.content,
                      style: TextStyles.caption.copyWith(
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
            if (!message.isCurrentUser) const SizedBox(width: 50),
          ],
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
        _submitReport(context, l10n, reasonKey);
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
              LucideIcons.chevronRight,
              color: theme.grey[400],
              size: 16,
            ),
          ],
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.grey[50],
        border: Border(
          top: BorderSide(color: theme.grey[200]!, width: 1),
        ),
      ),
      child: SafeArea(
        child: WidgetsContainer(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          backgroundColor: theme.postInputBackgound,
          borderSide: BorderSide(color: theme.grey[300]!, width: 0.5),
          borderRadius: BorderRadius.circular(12.5),
          child: Row(
            children: [
              // User avatar
              _buildUserAvatar(context, theme),

              const SizedBox(width: 10),

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
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isSubmitting
                      ? null
                      : () => _handleSubmit(_messageController.text),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          _isSubmitting ? theme.grey[400] : theme.primary[600],
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
      ),
    );
  }

  Widget _buildUserAvatar(BuildContext context, CustomThemeData theme) {
    final user = FirebaseAuth.instance.currentUser;
    final userImageUrl = user?.photoURL;

    return CircleAvatar(
      radius: 14,
      backgroundColor: theme.primary[100],
      backgroundImage: userImageUrl != null ? NetworkImage(userImageUrl) : null,
      child: userImageUrl == null
          ? Icon(
              Icons.person,
              size: 18,
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
      await Future.delayed(
          const Duration(seconds: 1)); // Simulate network request

      // Clear the input
      _messageController.clear();

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
