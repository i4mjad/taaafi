import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/shared/data/models/user_report.dart';
import 'package:reboot_app_3/features/shared/data/notifiers/user_reports_notifier.dart';

class ReportConversationScreen extends ConsumerStatefulWidget {
  final String reportId;

  const ReportConversationScreen({
    super.key,
    required this.reportId,
  });

  @override
  ConsumerState<ReportConversationScreen> createState() =>
      _ReportConversationScreenState();
}

class _ReportConversationScreenState
    extends ConsumerState<ReportConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSubmitting = false;
  int _previousMessageCount = 0;
  bool _showNewMessageIndicator = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String? _validateMessage(String? value) {
    final localization = AppLocalizations.of(context);
    if (value == null || value.trim().isEmpty) {
      return localization.translate('field-required');
    }
    if (value.length > 220) {
      return localization.translate('character-limit-exceeded');
    }
    return null;
  }

  Future<void> _sendMessage() async {
    if (_validateMessage(_messageController.text) != null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final reportsNotifier = ref.read(userReportsNotifierProvider.notifier);
      await reportsNotifier.addMessageToReport(
        reportId: widget.reportId,
        message: _messageController.text.trim(),
      );

      _messageController.clear();

      if (mounted) {
        getSuccessSnackBar(context, 'message-sent');
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
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);
    final messagesAsyncValue =
        ref.watch(reportMessagesStreamProvider(widget.reportId));
    final reportAsyncValue = ref.watch(userReportsStreamProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, 'report-conversation', false, true),
      body: Column(
        children: [
          // Report info header
          reportAsyncValue.when(
            data: (reports) {
              final report = reports.firstWhere(
                (r) => r.id == widget.reportId,
                orElse: () => throw Exception('Report not found'),
              );
              return ReportInfoHeader(
                report: report,
                showNewMessageIndicator: _showNewMessageIndicator,
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (error, stackTrace) => Container(
              color: theme.error[50],
              padding: EdgeInsets.all(16),
              child: Text(
                'Error loading report: $error',
                style: TextStyles.small.copyWith(color: theme.error[600]),
              ),
            ),
          ),

          // Roadmap/Timeline
          Expanded(
            child: messagesAsyncValue.when(
              data: (messages) {
                // Auto-scroll when new messages arrive
                if (messages.length > _previousMessageCount &&
                    _previousMessageCount > 0) {
                  _scrollToBottom();
                  setState(() {
                    _showNewMessageIndicator = true;
                  });

                  // Hide indicator after 2 seconds
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) {
                      setState(() {
                        _showNewMessageIndicator = false;
                      });
                    }
                  });
                }
                _previousMessageCount = messages.length;

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.mapPin,
                          size: 64,
                          color: theme.grey[400],
                        ),
                        verticalSpace(Spacing.points16),
                        Text(
                          localization.translate('no-messages-yet'),
                          style: TextStyles.h6.copyWith(
                            color: theme.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.all(16),
                  child: ReportRoadmap(messages: messages),
                );
              },
              loading: () => const Center(child: Spinner()),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.alertCircle,
                      size: 64,
                      color: theme.error[600],
                    ),
                    verticalSpace(Spacing.points16),
                    Text(
                      'Error: $error',
                      style: TextStyles.body.copyWith(
                        color: theme.error[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Message input (only if report allows new messages)
          reportAsyncValue.when(
            data: (reports) {
              final report = reports.firstWhere(
                (r) => r.id == widget.reportId,
                orElse: () => throw Exception('Report not found'),
              );

              final canSendMessage = report.status != ReportStatus.closed &&
                  report.status != ReportStatus.finalized &&
                  report.status != ReportStatus.waitingForAdminResponse;

              if (!canSendMessage) {
                return Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.backgroundColor,
                    border: Border(top: BorderSide(color: theme.grey[300]!)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.lock,
                        size: 16,
                        color: theme.grey[600],
                      ),
                      horizontalSpace(Spacing.points8),
                      Expanded(
                        child: Text(
                          localization.translate('cannot-send-message'),
                          style: TextStyles.small.copyWith(
                            color: theme.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return MessageInput(
                controller: _messageController,
                isSubmitting: _isSubmitting,
                onSend: _sendMessage,
                validator: _validateMessage,
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class ReportInfoHeader extends StatelessWidget {
  final UserReport report;
  final bool showNewMessageIndicator;

  const ReportInfoHeader({
    super.key,
    required this.report,
    this.showNewMessageIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);

    String statusKey;
    Color statusColor;

    switch (report.status) {
      case ReportStatus.pending:
        statusKey = 'pending';
        statusColor = theme.warn[600]!;
        break;
      case ReportStatus.inProgress:
        statusKey = 'in-progress';
        statusColor = theme.primary[600]!;
        break;
      case ReportStatus.waitingForAdminResponse:
        statusKey = 'waiting-for-admin-response';
        statusColor = theme.primary[400]!;
        break;
      case ReportStatus.closed:
        statusKey = 'closed';
        statusColor = theme.grey[600]!;
        break;
      case ReportStatus.finalized:
        statusKey = 'finalized';
        statusColor = theme.success[600]!;
        break;
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        border: Border(bottom: BorderSide(color: theme.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  localization.translate('report-progress'),
                  style: TextStyles.h6.copyWith(color: theme.grey[900]),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  localization.translate(statusKey),
                  style: TextStyles.small.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          verticalSpace(Spacing.points8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.clock,
                    size: 14,
                    color: theme.grey[500],
                  ),
                  horizontalSpace(Spacing.points4),
                  Flexible(
                    child: Text(
                      '${localization.translate("submitted-at")} ${getDisplayDateTime(report.time, localization.locale.languageCode)}',
                      style: TextStyles.small.copyWith(color: theme.grey[500]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  horizontalSpace(Spacing.points12),
                  // Real-time indicator with pulsing animation
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PulsingDot(color: theme.success[500]!),
                      horizontalSpace(Spacing.points4),
                      Text(
                        'Live',
                        style: TextStyles.small.copyWith(
                          color: theme.success[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (showNewMessageIndicator) ...[
                verticalSpace(Spacing.points4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.primary[500]!.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: theme.primary[500]!.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.zap,
                        size: 12,
                        color: theme.primary[600],
                      ),
                      horizontalSpace(Spacing.points4),
                      Text(
                        'New Update',
                        style: TextStyles.small.copyWith(
                          color: theme.primary[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class ReportRoadmap extends StatelessWidget {
  final List<ReportMessage> messages;

  const ReportRoadmap({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Column(
      children: [
        for (int i = 0; i < messages.length; i++)
          RoadmapUpdate(
            message: messages[i],
            isFirst: i == 0,
            isLast: i == messages.length - 1,
            updateNumber: i + 1,
          ),
      ],
    );
  }
}

class RoadmapUpdate extends StatelessWidget {
  final ReportMessage message;
  final bool isFirst;
  final bool isLast;
  final int updateNumber;

  const RoadmapUpdate({
    super.key,
    required this.message,
    required this.isFirst,
    required this.isLast,
    required this.updateNumber,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);
    final isUser = message.senderRole == 'user';

    final updateColor = isUser ? theme.primary[600]! : theme.success[600]!;
    final updateIcon = isUser ? LucideIcons.user : LucideIcons.shield;
    final updateTitle = isUser
        ? localization.translate('you')
        : localization.translate('admin-response');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Top line (hidden for first update)
                if (!isFirst)
                  Container(
                    width: 2,
                    height: 24,
                    color: theme.grey[300],
                  ),

                // Update circle
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: updateColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.grey[300]!, width: 2),
                  ),
                  child: Icon(
                    updateIcon,
                    size: 16,
                    color: Colors.white,
                  ),
                ),

                // Bottom line (hidden for last update)
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: theme.grey[300],
                    ),
                  ),
              ],
            ),
          ),

          horizontalSpace(Spacing.points16),

          // Update content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : 24,
              ),
              child: WidgetsContainer(
                padding: EdgeInsets.all(16),
                backgroundColor: theme.backgroundColor,
                borderSide:
                    BorderSide(color: updateColor.withValues(alpha: 0.2)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Update header
                    Row(
                      children: [
                        WidgetsContainer(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          backgroundColor: updateColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(
                              color: updateColor.withValues(alpha: 0.5)),
                          child: Text(
                            '${localization.translate("update")} $updateNumber',
                            style: TextStyles.small.copyWith(
                              color: updateColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        horizontalSpace(Spacing.points8),
                        Text(
                          updateTitle,
                          style: TextStyles.footnoteSelected.copyWith(
                            color: theme.grey[700],
                          ),
                        ),
                      ],
                    ),

                    verticalSpace(Spacing.points12),

                    // Message content
                    Text(
                      message.message,
                      style: TextStyles.caption.copyWith(
                        color: theme.grey[800],
                        height: 1.5,
                      ),
                    ),

                    verticalSpace(Spacing.points8),

                    // Timestamp
                    Row(
                      children: [
                        Icon(
                          LucideIcons.clock,
                          size: 12,
                          color: theme.grey[500],
                        ),
                        horizontalSpace(Spacing.points4),
                        Text(
                          getDisplayDateTime(
                            message.timestamp,
                            localization.locale.languageCode,
                          ),
                          style: TextStyles.small.copyWith(
                            color: theme.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSend;
  final String? Function(String?) validator;

  const MessageInput({
    super.key,
    required this.controller,
    required this.isSubmitting,
    required this.onSend,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        border: Border(top: BorderSide(color: theme.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            controller: controller,
            hint: localization.translate('add-update'),
            prefixIcon: LucideIcons.messageCircle,
            validator: validator,
            inputType: TextInputType.multiline,
            enabled: !isSubmitting,
          ),
          verticalSpace(Spacing.points8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${controller.text.length}/220',
                style: TextStyles.small.copyWith(
                  color: controller.text.length > 220
                      ? theme.error[600]
                      : theme.grey[500],
                ),
              ),
              ElevatedButton.icon(
                onPressed: isSubmitting ? null : onSend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary[600],
                  foregroundColor: theme.grey[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: isSubmitting
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: Spinner(
                          strokeWidth: 2,
                          valueColor: theme.grey[50],
                        ),
                      )
                    : Icon(LucideIcons.send, size: 16),
                label: Text(
                  localization.translate('add-update'),
                  style: TextStyles.body.copyWith(color: theme.grey[50]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;

  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
