import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textarea.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/shared/data/notifiers/user_reports_notifier.dart';
import '../screens/group_chat_screen.dart';

class MessageReportModal extends ConsumerStatefulWidget {
  final String reason;
  final ChatMessage message;
  final String groupId;
  final bool dismissMultipleModals;

  const MessageReportModal({
    super.key,
    required this.reason,
    required this.message,
    required this.groupId,
    this.dismissMultipleModals = false,
  });

  @override
  ConsumerState<MessageReportModal> createState() => _MessageReportModalState();
}

class _MessageReportModalState extends ConsumerState<MessageReportModal> {
  final TextEditingController _messageController = TextEditingController();
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
    super.dispose();
  }

  String? _validateMessage(String? value) {
    final localization = AppLocalizations.of(context);
    if (value == null || value.trim().isEmpty) {
      return localization.translate('field-required');
    }
    if (value.length > 500) {
      return localization.translate('character-limit-exceeded');
    }
    return null;
  }

  Future<void> _submitMessageReport() async {
    if (_validateMessage(_messageController.text) != null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final reportsNotifier = ref.read(userReportsNotifierProvider.notifier);

      // Create a comprehensive report message with reason and user input
      final reasonText =
          AppLocalizations.of(context).translate('report-${widget.reason}');
      final messagePreview = widget.message.content.length > 100
          ? '${widget.message.content.substring(0, 100)}...'
          : widget.message.content;

      final reportMessage = '''
$reasonText

${AppLocalizations.of(context).translate('additional-details')}:
${_messageController.text.trim()}

${AppLocalizations.of(context).translate('reported-message')}:
"$messagePreview"
      '''
          .trim();

      final reportId = await reportsNotifier.submitMessageReport(
        messageId: widget.message.id,
        groupId: widget.groupId,
        userMessage: reportMessage,
        messageSender: widget.message.senderCpId,
        messageContent: widget.message.content,
      );

      if (mounted) {
        // Dismiss this modal
        Navigator.of(context).pop();

        // If we need to dismiss multiple modals (e.g., underlying options modal)
        if (widget.dismissMultipleModals) {
          Navigator.of(context).pop();
        }

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

    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    localization.translate('report-message'),
                    style: TextStyles.h5.copyWith(color: theme.grey[900]),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    if (widget.dismissMultipleModals) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Icon(
                    LucideIcons.x,
                    size: 24,
                    color: theme.grey[600],
                  ),
                ),
              ],
            ),

            verticalSpace(Spacing.points16),

            // Selected reason display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.error[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.error[200]!,
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.flag,
                    size: 20,
                    color: theme.error[600],
                  ),
                  horizontalSpace(Spacing.points8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localization.translate('selected-reason'),
                          style: TextStyles.small.copyWith(
                            color: theme.error[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        verticalSpace(Spacing.points4),
                        Text(
                          localization.translate('report-${widget.reason}'),
                          style: TextStyles.footnote.copyWith(
                            color: theme.error[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            verticalSpace(Spacing.points16),

            // Description
            Text(
              localization.translate('message-report-description'),
              style: TextStyles.body.copyWith(
                color: theme.grey[700],
                height: 1.5,
              ),
            ),

            verticalSpace(Spacing.points24),

            // Message input
            CustomTextArea(
              controller: _messageController,
              hint: localization.translate('message-report-placeholder'),
              prefixIcon: LucideIcons.messageSquare,
              validator: _validateMessage,
              enabled: !_isSubmitting,
              height: 140,
            ),

            verticalSpace(Spacing.points8),

            // Character count and helper text
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    localization.translate('message-report-note'),
                    style: TextStyles.small.copyWith(
                      color: theme.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                Text(
                  '${_messageController.text.length}/500',
                  style: TextStyles.small.copyWith(
                    color: theme.grey[500],
                  ),
                ),
              ],
            ),

            verticalSpace(Spacing.points24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitMessageReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.error[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: Spinner(
                              strokeWidth: 2,
                            ),
                          ),
                          horizontalSpace(Spacing.points8),
                          Text(
                            localization.translate('submitting'),
                            style: TextStyles.footnote.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        localization.translate('submit-report'),
                        style: TextStyles.footnote.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
