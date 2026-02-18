import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/shared_widgets/platform_action_sheet.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textarea.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/chat_text_size_provider.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/direct_messaging/application/direct_messaging_providers.dart';
import 'package:reboot_app_3/features/direct_messaging/application/direct_messaging_ban_providers.dart';
import 'package:reboot_app_3/features/direct_messaging/domain/entities/direct_message_entity.dart';
import 'package:reboot_app_3/features/shared/data/notifiers/user_reports_notifier.dart';

class DirectChatScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const DirectChatScreen({
    Key? key,
    required this.conversationId,
  }) : super(key: key);

  @override
  ConsumerState<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends ConsumerState<DirectChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  DirectMessageEntity? _replyToMessage;
  bool _isAtBottom = true;
  bool _isSubmitting = false;
  bool _hasMarkedAsRead = false; // Track if we've already marked as read
  bool _hasAutoScrolled = false; // Track if we've already auto-scrolled

  // Animation for reply preview dismissal
  late AnimationController _replyPreviewController;
  late Animation<double> _replyPreviewAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Mark conversation as read once when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasMarkedAsRead && mounted) {
        ref
            .read(conversationActionsControllerProvider.notifier)
            .markAsRead(widget.conversationId);
        _hasMarkedAsRead = true;
      }
    });
    _messageController.addListener(() {
      setState(() {}); // Rebuild for send button visibility
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

  void _onScroll() {
    if (_scrollController.hasClients) {
      // For reversed list, position 0 is the bottom (latest messages)
      final isAtBottom = _scrollController.position.pixels <= 50;
      if (isAtBottom != _isAtBottom) {
        setState(() => _isAtBottom = isAtBottom);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // For reversed list, scroll to position 0 (bottom/latest messages)
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    // Check if user is banned from sending messages
    try {
      final canSend = await ref.read(canSendDirectMessageProvider.future);
      
      if (!canSend) {
        if (mounted) {
          final dmAccess = await ref.read(directMessagingAccessNotifierProvider.future);
          getErrorSnackBar(context, dmAccess.errorMessageKey);
        }
        return;
      }
    } catch (e) {
      print('Error checking send permission: $e');
      if (mounted) {
        getErrorSnackBar(context, 'error-checking-permissions');
      }
      return;
    }

    // Show loader immediately so the user gets instant feedback
    setState(() {
      _isSubmitting = true;
    });

    // Give the UI a chance to rebuild before heavy async work starts
    await Future.delayed(Duration.zero);

    try {
      final controller = ref.read(directChatControllerProvider.notifier);

      String? quotedPreview;
      if (_replyToMessage != null) {
        quotedPreview =
            ref.read(generateQuotedPreviewProvider(_replyToMessage!.body));
      }

      await controller.send(
        widget.conversationId,
        text,
        replyToMessageId: _replyToMessage?.id,
        quotedPreview: quotedPreview,
      );

      // Clear the input and reply state
      _messageController.clear();
      if (_replyToMessage != null) {
        setState(() {
          _replyToMessage = null;
        });
        _replyPreviewController.value = 1.0; // Reset animation for next reply
      }

      // Scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (error) {
      if (mounted) {
        getErrorSnackBar(context, 'error-sending-message');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showBlockConfirmation(
      BuildContext context, String blockedCpId, String blockerCpId) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          localizations.translate('block-user'),
          style: TextStyles.h6.copyWith(color: theme.grey[900]),
        ),
        content: Text(
          localizations.translate('block-user-confirmation'),
          style: TextStyles.body.copyWith(color: theme.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              localizations.translate('cancel'),
              style: TextStyles.body.copyWith(color: theme.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                final controller = ref.read(blockControllerProvider.notifier);
                await controller.blockUser(blockedCpId);
                if (context.mounted) {
                  getSuccessSnackBar(context, 'user-blocked-successfully');
                }
              } catch (e) {
                if (context.mounted) {
                  getErrorSnackBar(context, 'error-blocking-user');
                }
              }
            },
            child: Text(
              localizations.translate('block'),
              style: TextStyles.body.copyWith(color: theme.error[600]),
            ),
          ),
        ],
      ),
    );
  }

  void _showUnblockConfirmation(
      BuildContext context, String blockedCpId, String blockerCpId) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          localizations.translate('unblock-user'),
          style: TextStyles.h6.copyWith(color: theme.grey[900]),
        ),
        content: Text(
          localizations.translate('unblock-user-confirmation'),
          style: TextStyles.body.copyWith(color: theme.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              localizations.translate('cancel'),
              style: TextStyles.body.copyWith(color: theme.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                final controller = ref.read(blockControllerProvider.notifier);
                await controller.unblockUser(blockedCpId);
                if (context.mounted) {
                  getSuccessSnackBar(context, 'user-unblocked-successfully');
                }
              } catch (e) {
                if (context.mounted) {
                  getErrorSnackBar(context, 'error-unblocking-user');
                }
              }
            },
            child: Text(
              localizations.translate('unblock'),
              style: TextStyles.body.copyWith(color: theme.success[600]),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportUserDialog(
      BuildContext context, String reportedCpId, String reporterCpId) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final TextEditingController reportController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: theme.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localizations.translate('report-user'),
                      style: TextStyles.h6.copyWith(color: theme.grey[900]),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(sheetContext).pop(),
                      child: Icon(
                        LucideIcons.x,
                        size: 20,
                        color: theme.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  localizations.translate('report-user-subtitle'),
                  style: TextStyles.body.copyWith(color: theme.grey[700]),
                ),
                const SizedBox(height: 16),

                // Text Area
                CustomTextArea(
                  controller: reportController,
                  hint: localizations.translate('report-user-placeholder'),
                  prefixIcon: LucideIcons.messageCircle,
                  enabled: !isSubmitting,
                  height: 120,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return localizations.translate('field-required');
                    }
                    if (value.length > 1500) {
                      return localizations.translate('character-limit-exceeded');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                          final message = reportController.text.trim();
                          if (message.isEmpty) {
                            getErrorSnackBar(
                                context, 'field-required');
                            return;
                          }
                          if (message.length > 1500) {
                            getErrorSnackBar(
                                context, 'character-limit-exceeded');
                            return;
                          }

                          setState(() => isSubmitting = true);

                          try {
                            final reportsNotifier =
                                ref.read(userReportsNotifierProvider.notifier);
                            await reportsNotifier.submitUserReport(
                              communityProfileId: reportedCpId,
                              userMessage: message,
                            );
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                            if (context.mounted) {
                              getSuccessSnackBar(
                                  context, 'user-reported-successfully');
                            }
                          } catch (e) {
                            String errorKey = 'error-reporting-user';
                            if (e.toString().contains('Exception: ')) {
                              final extractedKey =
                                  e.toString().replaceFirst('Exception: ', '');
                              if ([
                                'max-active-reports-reached',
                                'message-cannot-be-empty',
                                'message-exceeds-character-limit'
                              ].contains(extractedKey)) {
                                errorKey = extractedKey;
                              }
                            }
                            if (context.mounted) {
                              getErrorSnackBar(context, errorKey);
                            }
                          } finally {
                            if (mounted) {
                              setState(() => isSubmitting = false);
                            }
                          }
                        },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.error[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: isSubmitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: Spinner(
                              strokeWidth: 2,
                              valueColor: theme.grey[50],
                            ),
                          )
                        : Icon(LucideIcons.flag, size: 20),
                    label: Text(
                      localizations.translate('submit-report'),
                      style: TextStyles.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReportMessageDialog(BuildContext context, DirectMessageEntity message) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final TextEditingController reportController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: theme.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localizations.translate('report-message'),
                      style: TextStyles.h6.copyWith(color: theme.grey[900]),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(sheetContext).pop(),
                      child: Icon(
                        LucideIcons.x,
                        size: 20,
                        color: theme.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Message Preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    message.body.length > 100
                        ? '${message.body.substring(0, 100)}...'
                        : message.body,
                    style: TextStyles.small.copyWith(color: theme.grey[700]),
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  localizations.translate('report-message-confirmation'),
                  style: TextStyles.body.copyWith(color: theme.grey[700]),
                ),
                const SizedBox(height: 16),

                // Text Area
                CustomTextArea(
                  controller: reportController,
                  hint: localizations.translate('report-user-placeholder'),
                  prefixIcon: LucideIcons.messageCircle,
                  enabled: !isSubmitting,
                  height: 120,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return localizations.translate('field-required');
                    }
                    if (value.length > 1500) {
                      return localizations.translate('character-limit-exceeded');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                          final reportMessage = reportController.text.trim();
                          if (reportMessage.isEmpty) {
                            getErrorSnackBar(
                                context, 'field-required');
                            return;
                          }
                          if (reportMessage.length > 1500) {
                            getErrorSnackBar(
                                context, 'character-limit-exceeded');
                            return;
                          }

                          setState(() => isSubmitting = true);

                          try {
                            final reportsNotifier =
                                ref.read(userReportsNotifierProvider.notifier);
                            await reportsNotifier.submitMessageReport(
                              messageId: message.id,
                              groupId: widget.conversationId,
                              userMessage: reportMessage,
                              messageSender: message.senderCpId,
                              messageContent: message.body,
                            );
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                            if (context.mounted) {
                              getSuccessSnackBar(
                                  context, 'message-reported-successfully');
                            }
                          } catch (e) {
                            String errorKey = 'error-reporting-message';
                            if (e.toString().contains('Exception: ')) {
                              final extractedKey =
                                  e.toString().replaceFirst('Exception: ', '');
                              if ([
                                'max-active-reports-reached',
                                'message-cannot-be-empty',
                                'message-exceeds-character-limit'
                              ].contains(extractedKey)) {
                                errorKey = extractedKey;
                              }
                            }
                            if (context.mounted) {
                              getErrorSnackBar(context, errorKey);
                            }
                          } finally {
                            if (mounted) {
                              setState(() => isSubmitting = false);
                            }
                          }
                        },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.error[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: isSubmitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: Spinner(
                              strokeWidth: 2,
                              valueColor: theme.grey[50],
                            ),
                          )
                        : Icon(LucideIcons.flag, size: 20),
                    label: Text(
                      localizations.translate('submit-report'),
                      style: TextStyles.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final chatTextSize = ref.watch(chatTextSizeProvider);

    // Check access
    final canAccessAsync =
        ref.watch(canAccessDirectChatProvider(widget.conversationId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(context, theme, localizations),
        backgroundColor: theme.backgroundColor,
        body: canAccessAsync.when(
          loading: () => const Center(child: Spinner()),
          error: (error, _) => Center(
            child: Text(
              'Error: $error',
              style: TextStyles.body.copyWith(color: theme.grey[600]),
            ),
          ),
          data: (canAccess) {
            if (!canAccess) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    localizations.translate('cannot-message-user-blocked'),
                    style: TextStyles.body.copyWith(color: theme.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: _buildMessagesList(
                      context, theme, localizations, chatTextSize),
                ),
                _buildInputArea(context, theme, localizations),
              ],
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations localizations,
  ) {
    final currentProfileAsync = ref.watch(currentCommunityProfileProvider);

    return currentProfileAsync.when(
      loading: () => appBar(context, ref, 'community-chats', false, true),
      error: (_, __) => appBar(context, ref, 'community-chats', false, true),
      data: (currentProfile) {
        if (currentProfile == null) {
          return appBar(context, ref, 'community-chats', false, true);
        }

        // Get conversation to find other participant
        ref
            .read(directChatRepositoryProvider)
            .clearCache(widget.conversationId);
        return AppBar(
          leading: IconButton(
            icon: Icon(
              Directionality.of(context) == TextDirection.RTL
                  ? LucideIcons.arrowRight
                  : LucideIcons.arrowLeft,
              color: theme.grey[900],
            ),
            onPressed: () => context.pop(),
          ),
          title: FutureBuilder(
            future: null,
            builder: (context, snapshot) {
              return StreamBuilder(
                stream: ref
                    .read(conversationsRepositoryProvider)
                    .watchUserConversations(currentProfile.id),
                builder: (context, conversationSnapshot) {
                  if (!conversationSnapshot.hasData) {
                    return Text(localizations.translate('community-chats'));
                  }

                  // Safely find the conversation
                  final conversation = conversationSnapshot.data!
                      .where((c) => c.id == widget.conversationId)
                      .firstOrNull;

                  if (conversation == null) {
                    return Text(localizations.translate('community-chats'));
                  }

                  final otherCpId =
                      conversation.getOtherParticipantCpId(currentProfile.id);
                  final otherProfileAsync =
                      ref.watch(communityProfileByIdProvider(otherCpId));

                  return otherProfileAsync.when(
                    loading: () => Text(localizations.translate('loading')),
                    error: (_, __) =>
                        Text(localizations.translate('community-chats')),
                    data: (otherProfile) {
                      if (otherProfile == null)
                        return Text(localizations.translate('community-chats'));

                      final displayName = otherProfile.isDeleted
                          ? localizations.translate('community-deleted-user')
                          : otherProfile.isAnonymous
                              ? localizations.translate('community-anonymous')
                              : otherProfile.displayName;

                      return Text(
                        displayName,
                        style: TextStyles.body.copyWith(
                          color: theme.grey[900],
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          actions: [
            // Block/Unblock Menu
            StreamBuilder(
              stream: ref
                  .read(conversationsRepositoryProvider)
                  .watchUserConversations(currentProfile.id),
              builder: (context, conversationSnapshot) {
                if (!conversationSnapshot.hasData) {
                  return const SizedBox.shrink();
                }

                // Safely find the conversation
                final conversation = conversationSnapshot.data!
                    .where((c) => c.id == widget.conversationId)
                    .firstOrNull;

                if (conversation == null) {
                  return const SizedBox.shrink();
                }

                final otherCpId =
                    conversation.getOtherParticipantCpId(currentProfile.id);

                // Check if user is blocked
                final isBlockedAsync =
                    ref.watch(didIBlockUserProvider(otherCpId));

                return isBlockedAsync.when(
                  data: (isBlocked) {
                    return PlatformPopupMenu(
                      icon: Icon(LucideIcons.moreVertical,
                          color: theme.grey[900]),
                      items: [
                        PlatformActionItem(
                          icon: LucideIcons.flag,
                          title: localizations.translate('report-user'),
                          isDestructive: false,
                          onTap: () {
                            _showReportUserDialog(context, otherCpId, currentProfile.id);
                          },
                        ),
                        PlatformActionItem(
                          icon: isBlocked
                              ? LucideIcons.userCheck
                              : LucideIcons.userX,
                          title: localizations.translate(
                            isBlocked ? 'unblock-user' : 'block-user',
                          ),
                          isDestructive: !isBlocked,
                          onTap: () {
                            if (isBlocked) {
                              _showUnblockConfirmation(
                                  context, otherCpId, currentProfile.id);
                            } else {
                              _showBlockConfirmation(
                                  context, otherCpId, currentProfile.id);
                            }
                          },
                        ),
                      ],
                    );
                  },
                  loading: () => IconButton(
                    icon: const SizedBox(
                      width: 18,
                      height: 18,
                      child: Spinner(),
                    ),
                    onPressed: null,
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            ),
          ],
          backgroundColor: theme.backgroundColor,
          elevation: 1,
        );
      },
    );
  }

  Widget _buildMessagesList(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations localizations,
    ChatTextSize chatTextSize,
  ) {
    final messagesAsync =
        ref.watch(directChatMessagesProvider(widget.conversationId));
    final currentProfileAsync = ref.watch(currentCommunityProfileProvider);

    return currentProfileAsync.when(
      loading: () => const Center(child: Spinner()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (currentProfile) {
        if (currentProfile == null) {
          return Center(
            child: Text(
              'Please create a community profile',
              style: TextStyles.body.copyWith(color: theme.grey[600]),
            ),
          );
        }

        return messagesAsync.when(
          loading: () => const Center(child: Spinner()),
          error: (error, _) => Center(
            child: Text(
              'Error loading messages: $error',
              style: TextStyles.body.copyWith(color: theme.grey[600]),
            ),
          ),
          data: (messages) {
            if (messages.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.messageSquare,
                      size: 48,
                      color: theme.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      localizations.translate('no-messages-yet'),
                      style: TextStyles.body.copyWith(color: theme.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localizations.translate('start-conversation'),
                      style: TextStyles.small.copyWith(color: theme.grey[500]),
                    ),
                  ],
                ),
              );
            }

            // Filter messages based on current user's visibility
            final visibleMessages = messages
                .where((msg) => msg.isVisibleToUser(currentProfile.id))
                .toList();

            // Sort messages by creation time (latest first for reverse ListView)
            final sortedMessages = List<DirectMessageEntity>.from(visibleMessages);
            sortedMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            // Auto-scroll to bottom when messages first load (only once)
            if (!_hasAutoScrolled && sortedMessages.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients && mounted) {
                  _scrollController.jumpTo(0); // Jump to bottom (latest messages)
                  _hasAutoScrolled = true;
                }
              });
            }

            return NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                // Load more messages when scrolling to the top (older messages)
                if (scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent * 0.9) {
                  // TODO: Implement pagination for DM messages
                  // _loadMoreMessages();
                }
                return false;
              },
              child: ListView.builder(
                controller: _scrollController,
                reverse: true, // Latest messages at bottom
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: (MediaQuery.of(context).size.width * 0.04).clamp(12.0, 20.0),
                  vertical: (MediaQuery.of(context).size.height * 0.01).clamp(6.0, 12.0),
                ),
                itemCount: sortedMessages.length,
                itemBuilder: (context, index) {
                  final message = sortedMessages[index];
                  final nextMessage = index < sortedMessages.length - 1
                      ? sortedMessages[index + 1]
                      : null;
                  final isCurrentUser = message.senderCpId == currentProfile.id;

                  return Column(
                    children: [
                      // Show date separator - fixed logic for reverse ListView
                      // We want the separator ABOVE the first message of each day (chronologically)
                      // In reverse ListView: last index = chronologically first message of the day
                      if (index == sortedMessages.length - 1 || // Last item (chronologically first)
                          (nextMessage != null &&
                              !_isSameDay(message.createdAt, nextMessage.createdAt)))
                        _buildDateSeparator(context, theme, localizations, message.createdAt),

                      _buildMessageBubble(
                        context,
                        theme,
                        localizations,
                        message,
                        isCurrentUser,
                        chatTextSize,
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations localizations,
    DirectMessageEntity message,
    bool isCurrentUser,
    ChatTextSize chatTextSize,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final currentProfileAsync = ref.watch(currentCommunityProfileProvider);
    final currentCpId = currentProfileAsync.valueOrNull?.id;

    // Calculate responsive dimensions
    final avatarSize = screenWidth * 0.08;
    final clampedAvatarSize = avatarSize.clamp(24.0, 36.0);

    // Message bubble widths
    final currentUserMaxWidth = screenWidth * 0.5;
    final otherUserMaxWidth = screenWidth * 0.65;

    // Responsive spacing
    final horizontalSpacing = screenWidth * 0.02;
    final clampedSpacing = horizontalSpacing.clamp(6.0, 12.0);

    // Get other participant's profile for displaying their name
    final conversationsAsync = ref
        .watch(
          conversationsRepositoryProvider,
        )
        .watchUserConversations(currentCpId ?? '');

    return _AnimatedSwipeMessage(
      key: Key(message.id),
      message: message,
      theme: theme,
      onLongPress: () => _showMessageOptions(message, isCurrentUser),
      onSwipeToReply: () => _startReplyToMessage(message),
      child: Container(
        margin: EdgeInsets.only(bottom: screenHeight * 0.02),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          textDirection: Directionality.of(context),
          children: [
            // For current user messages, add flexible space on the left
            if (isCurrentUser) const Expanded(child: SizedBox()),

            // Avatar - only show for other users' messages
            if (!isCurrentUser) ...[
              FutureBuilder(
                future: conversationsAsync.first,
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return SizedBox(width: clampedAvatarSize);

                  final conversation = snapshot.data!
                      .where((c) => c.id == widget.conversationId)
                      .firstOrNull;

                  if (conversation == null)
                    return SizedBox(width: clampedAvatarSize);

                  final otherCpId =
                      conversation.getOtherParticipantCpId(currentCpId ?? '');
                  final otherProfileAsync = ref.watch(
                    communityProfileByIdProvider(otherCpId),
                  );

                  return otherProfileAsync.when(
                    data: (profile) {
                      if (profile == null)
                        return SizedBox(width: clampedAvatarSize);

                      return Container(
                        width: clampedAvatarSize,
                        height: clampedAvatarSize,
                        decoration: BoxDecoration(
                          color: theme.primary[200],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: profile.avatarUrl != null && !profile.isAnonymous
                            ? ClipOval(
                                child: Image.network(
                                  profile.avatarUrl!,
                                  width: clampedAvatarSize,
                                  height: clampedAvatarSize,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildFallbackAvatar(
                                          profile, clampedAvatarSize),
                                ),
                              )
                            : _buildFallbackAvatar(profile, clampedAvatarSize),
                      );
                    },
                    loading: () => SizedBox(width: clampedAvatarSize),
                    error: (_, __) => SizedBox(width: clampedAvatarSize),
                  );
                },
              ),
              SizedBox(width: clampedSpacing),
            ],

            // For current user messages, add equivalent spacing
            if (isCurrentUser) SizedBox(width: clampedSpacing),

            // Message bubble
            Container(
              constraints: BoxConstraints(
                maxWidth:
                    isCurrentUser ? currentUserMaxWidth : otherUserMaxWidth,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.015,
              ),
              decoration: BoxDecoration(
                color: isCurrentUser ? theme.primary[50] : theme.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCurrentUser ? theme.primary[200]! : theme.grey[200]!,
                  width: 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name and time row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    textDirection: Directionality.of(context),
                    children: [
                      // Sender name
                      Text(
                        isCurrentUser
                            ? localizations.translate('you')
                            : _getOtherParticipantName(currentCpId),
                        style: TextStyles.smallBold.copyWith(
                          color: theme.grey[900],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const Spacer(),

                      // Time
                      Text(
                        DateFormat('HH:mm').format(message.createdAt),
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

                  // Reply preview
                  if (message.replyToMessageId != null)
                    _buildMessageReplyPreview(context, theme, message),

                  // Message content or under review placeholder
                  if (message.isUnderHighConfidenceReview)
                    // Show "under review" placeholder for high-confidence flagged messages
                    Text(
                      localizations.translate('message-under-review-short'),
                      style: TextStyles.small.copyWith(
                        color: theme.grey[500],
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                      ),
                    )
                  else
                    // Show normal message content
                  Text(
                    message.body,
                    style: _getMessageTextStyle(theme, chatTextSize),
                    textAlign: Directionality.of(context) == TextDirection.RTL
                        ? TextAlign.right
                        : TextAlign.left,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),

                  // Read receipt indicators (only for current user)
                  if (isCurrentUser) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: _buildReadReceipt(message),
                    ),
                  ],
                ],
              ),
            ),

            // For other user messages, add some spacing on the right
            if (!isCurrentUser) SizedBox(width: screenWidth * 0.12),
          ],
        ),
      ),
    );
  }

  void _startReplyToMessage(DirectMessageEntity message) {
    setState(() {
      _replyToMessage = message;
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
        _replyToMessage = null;
      });
    });
  }

  /// Check if two dates are on the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Build date separator widget
  Widget _buildDateSeparator(BuildContext context, CustomThemeData theme,
      AppLocalizations localizations, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final localDate = date.toLocal();
    final messageDate =
        DateTime(localDate.year, localDate.month, localDate.day);
    final screenHeight = MediaQuery.of(context).size.height;

    String dateText;
    if (messageDate == today) {
      dateText = localizations.translate('today');
    } else if (messageDate == yesterday) {
      dateText = localizations.translate('yesterday');
    } else {
      dateText = DateFormat('dd/MM/yyyy').format(localDate);
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

  Widget _buildReplyPreview(
      BuildContext context, CustomThemeData theme, AppLocalizations l10n) {
    final replyMessage = _replyToMessage!;
    final screenWidth = MediaQuery.of(context).size.width;

    // Get sender profile
    final senderProfileAsync = ref.watch(
      communityProfileByIdProvider(replyMessage.senderCpId),
    );
    final senderProfile = senderProfileAsync.valueOrNull;

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
                              senderProfile?.displayName ??
                                  l10n.translate('user'),
                              style: TextStyles.caption.copyWith(
                                color: theme.primary[700],
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (replyMessage.isUnderHighConfidenceReview)
                          Text(
                            l10n.translate('message-under-review-short'),
                            style: TextStyles.caption.copyWith(
                              color: theme.grey[500],
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                            ),
                          )
                        else
                        Text(
                          replyMessage.body,
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
      DirectMessageEntity message) {
    // Find the original message being replied to
    final messagesAsync = ref.watch(
      directChatMessagesProvider(widget.conversationId),
    );

    final originalMessage = messagesAsync.whenOrNull(
      data: (messages) =>
          messages.where((m) => m.id == message.replyToMessageId).firstOrNull,
    );

    if (originalMessage == null) {
      // Fallback if original message not found
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
        child: Text(
          message.quotedPreview ??
              AppLocalizations.of(context).translate('deleted-message'),
          style: TextStyles.small.copyWith(
            color: theme.grey[600],
            fontStyle: FontStyle.italic,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    // Get sender profile
    final senderProfileAsync = ref.watch(
      communityProfileByIdProvider(originalMessage.senderCpId),
    );
    final senderProfile = senderProfileAsync.valueOrNull;

    return GestureDetector(
      onTap: () {
        // Show original message in a modal
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
                  senderProfile?.displayName ??
                      AppLocalizations.of(context).translate('user'),
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
            if (originalMessage.isUnderHighConfidenceReview)
              Text(
                AppLocalizations.of(context).translate('message-under-review-short'),
                style: TextStyles.small.copyWith(
                  color: theme.grey[500],
                  fontStyle: FontStyle.italic,
                  fontSize: 11,
                ),
              )
            else
            Text(
              originalMessage.body,
              style: TextStyles.small.copyWith(
                color: theme.grey[600],
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

  /// Show original message in a simple modal bottom sheet
  void _showOriginalMessageModal(BuildContext context, CustomThemeData theme,
      DirectMessageEntity originalMessage) {
    final senderProfileAsync = ref.read(
      communityProfileByIdProvider(originalMessage.senderCpId),
    );
    final senderProfile = senderProfileAsync.valueOrNull;

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
                    AppLocalizations.of(context).translate('original-message'),
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
                          backgroundColor: theme.primary[300],
                          backgroundImage: senderProfile?.avatarUrl != null &&
                                  !(senderProfile?.isAnonymous ?? false)
                              ? NetworkImage(senderProfile!.avatarUrl!)
                              : null,
                          child: senderProfile?.avatarUrl == null ||
                                  (senderProfile?.isAnonymous ?? false)
                              ? (senderProfile?.isAnonymous ?? false
                                  ? const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 14,
                                    )
                                  : Text(
                                      senderProfile?.displayName.isNotEmpty ==
                                              true
                                          ? senderProfile!.displayName[0]
                                              .toUpperCase()
                                          : '?',
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
                          senderProfile?.displayName ??
                              AppLocalizations.of(context).translate('user'),
                          style: TextStyles.caption.copyWith(
                            color: theme.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatTime(originalMessage.createdAt),
                          style: TextStyles.caption.copyWith(
                            color: theme.grey[500],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Message content
                    if (originalMessage.isUnderHighConfidenceReview)
                      Text(
                        AppLocalizations.of(context).translate('message-under-review-short'),
                        style: TextStyles.body.copyWith(
                          color: theme.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                    Text(
                      originalMessage.body,
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

  Widget _buildFallbackAvatar(dynamic profile, double size) {
    return profile.isAnonymous
        ? Icon(
            Icons.person,
            color: Colors.white,
            size: size * 0.6,
          )
        : Center(
            child: Text(
              profile.displayName.isNotEmpty
                  ? profile.displayName[0].toUpperCase()
                  : '?',
              style: TextStyles.body.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.4,
              ),
            ),
          );
  }

  String _getOtherParticipantName(String? currentCpId) {
    if (currentCpId == null) return '';

    final conversationsAsync = ref
        .read(
          conversationsRepositoryProvider,
        )
        .watchUserConversations(currentCpId);

    return 'User';
  }

  /// Format DateTime to time string
  String _formatTime(DateTime dateTime) {
    final l10n = AppLocalizations.of(context);
    final local = dateTime.toLocal();
    final hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final amText = l10n.translate('am');
    final pmText = l10n.translate('pm');
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final period = hour >= 12 ? pmText : amText;

    return '$displayHour:$minute $period';
  }

  Widget _buildReadReceipt(DirectMessageEntity message) {
    final currentProfileAsync = ref.watch(currentCommunityProfileProvider);
    final currentCpId = currentProfileAsync.valueOrNull?.id;

    if (currentCpId == null) return const SizedBox.shrink();

    // Watch the conversation to get unreadBy status
    final conversationStream = ref
        .watch(
          conversationsRepositoryProvider,
        )
        .watchUserConversations(currentCpId);

    return FutureBuilder(
      future: conversationStream.first,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // Sent (single tick)
          return Icon(
            LucideIcons.check,
            size: 14,
            color: AppTheme.of(context).grey[600],
          );
        }

        final conversation = snapshot.data!
            .where((c) => c.id == widget.conversationId)
            .firstOrNull;

        if (conversation == null) {
          return Icon(
            LucideIcons.check,
            size: 14,
            color: AppTheme.of(context).grey[600],
          );
        }

        // Get other participant's ID
        final otherCpId = conversation.getOtherParticipantCpId(currentCpId);

        // Check if message is read by the other participant
        final unreadCount = conversation.unreadBy[otherCpId] ?? 0;
        final isRead = unreadCount == 0 ||
            message.createdAt
                .isBefore(DateTime.now().subtract(const Duration(seconds: 5)));

        if (isRead) {
          // Read (double blue ticks)
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.checkCheck,
                size: 14,
                color: AppTheme.of(context).primary[500],
              ),
            ],
          );
        } else {
          // Delivered (double gray ticks)
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.checkCheck,
                size: 14,
                color: AppTheme.of(context).grey[600],
              ),
            ],
          );
        }
      },
    );
  }

  TextStyle _getMessageTextStyle(CustomThemeData theme, ChatTextSize size) {
    switch (size) {
      case ChatTextSize.small:
        return TextStyles.small.copyWith(color: theme.grey[900]);
      case ChatTextSize.large:
        return TextStyles.bodyLarge.copyWith(color: theme.grey[900]);
      case ChatTextSize.medium:
        return TextStyles.body.copyWith(color: theme.grey[900]);
    }
  }

  Future<bool> _onWillPop() async {
    // Check if there's unsaved text
    if (_messageController.text.trim().isEmpty) {
      return true; // Allow navigation
    }

    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    // Show confirmation dialog
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          localizations.translate('unsaved-message'),
          style: TextStyles.h6.copyWith(color: theme.grey[900]),
        ),
        content: Text(
          localizations.translate('unsaved-message-warning'),
          style: TextStyles.body.copyWith(color: theme.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              localizations.translate('stay'),
              style: TextStyles.body.copyWith(color: theme.grey[700]),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              localizations.translate('discard'),
              style: TextStyles.body.copyWith(color: theme.error[600]),
            ),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  void _showMessageOptions(DirectMessageEntity message, bool isCurrentUser) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    // Get sender profile for display
    final senderProfileAsync = ref.read(
      communityProfileByIdProvider(message.senderCpId),
    );
    final senderProfile = senderProfileAsync.valueOrNull;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
              localizations.translate('message-actions'),
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
                      senderProfile?.displayName ??
                          localizations.translate('user'),
                      style: TextStyles.smallBold.copyWith(
                        color: theme.grey[900],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (message.isUnderHighConfidenceReview)
                      Text(
                        localizations.translate('message-under-review-short'),
                        style: TextStyles.body.copyWith(
                          color: theme.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                    Text(
                      message.body,
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

            // Actions with ActionModal styling
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Reply action
                  _buildActionItem(
                    context,
                    theme,
                    icon: LucideIcons.reply,
                    title: localizations.translate('reply'),
                    subtitle: localizations.translate('reply-to-message'),
                    onTap: () => _startReplyToMessage(message),
                    isDestructive: false,
                  ),

                  const SizedBox(height: 8),

                  // Delete action (only for current user)
                  if (isCurrentUser)
                    _buildActionItem(
                      context,
                      theme,
                      icon: LucideIcons.trash2,
                      title: localizations.translate('delete'),
                      subtitle: localizations.translate('delete-message'),
                      onTap: () => _deleteMessage(message),
                      isDestructive: true,
                    ),

                  // Report message action (only for other users' messages)
                  if (!isCurrentUser) ...[
                    const SizedBox(height: 8),
                    _buildActionItem(
                      context,
                      theme,
                      icon: LucideIcons.flag,
                      title: localizations.translate('report-message'),
                      subtitle: localizations.translate('report-inappropriate-message'),
                      onTap: () => _showReportMessageDialog(context, message),
                      isDestructive: true,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
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

  Future<void> _deleteMessage(DirectMessageEntity message) async {
    try {
      await ref
          .read(directChatControllerProvider.notifier)
          .deleteMessage(widget.conversationId, message.id);
      getSuccessSnackBar(context, 'message-deleted');
    } catch (error) {
      getErrorSnackBar(context, 'error-deleting-message');
    }
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
            if (_replyToMessage != null)
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
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),

                  // Send button
                  if (_messageController.text.isNotEmpty || _isSubmitting) ...[
                    SizedBox(width: (screenWidth * 0.02).clamp(6.0, 10.0)),
                    GestureDetector(
                      onTap: _isSubmitting ? null : () => _sendMessage(),
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
}

/// Animated swipe message widget for reply functionality
class _AnimatedSwipeMessage extends StatefulWidget {
  final DirectMessageEntity message;
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
    // Start of pan gesture
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final isRTL = Directionality.of(context) == TextDirection.RTL;
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
    final isRTL = Directionality.of(context) == TextDirection.RTL;
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate responsive swipe distances
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
