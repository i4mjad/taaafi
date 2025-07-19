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
import 'package:reboot_app_3/features/home/data/user_reports_notifier.dart';

class CommunityFeedbackModal extends ConsumerStatefulWidget {
  const CommunityFeedbackModal({super.key});

  @override
  ConsumerState<CommunityFeedbackModal> createState() =>
      _CommunityFeedbackModalState();
}

class _CommunityFeedbackModalState
    extends ConsumerState<CommunityFeedbackModal> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;

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
    if (value.length > 220) {
      return localization.translate('character-limit-exceeded');
    }
    return null;
  }

  Future<void> _submitFeedback() async {
    if (_validateMessage(_messageController.text) != null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final reportsNotifier = ref.read(userReportsNotifierProvider.notifier);
      final reportId = await reportsNotifier.submitCommunityFeedbackReport(
        userMessage: _messageController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        context.pushNamed(
          RouteNames.reportConversation.name,
          pathParameters: {'reportId': reportId},
        );

        getSuccessSnackBar(context, 'community-feedback-submitted');
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
                    localization.translate('community-feedback'),
                    style: TextStyles.h5.copyWith(color: theme.grey[900]),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(
                    LucideIcons.x,
                    size: 24,
                    color: theme.grey[600],
                  ),
                ),
              ],
            ),

            verticalSpace(Spacing.points16),

            // Description
            Text(
              localization.translate('community-feedback-description'),
              style: TextStyles.body.copyWith(
                color: theme.grey[700],
                height: 1.5,
              ),
            ),

            verticalSpace(Spacing.points24),

            // Message input
            CustomTextArea(
              controller: _messageController,
              hint: localization.translate('community-feedback-placeholder'),
              prefixIcon: LucideIcons.messageSquare,
              validator: _validateMessage,
              enabled: !_isSubmitting,
              height: 120,
            ),

            verticalSpace(Spacing.points8),

            // Helper note
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  localization.translate('community-feedback-note'),
                  style: TextStyles.small.copyWith(
                    color: theme.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),

            verticalSpace(Spacing.points24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary[600],
                  foregroundColor: theme.grey[50],
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isSubmitting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: Spinner(
                          strokeWidth: 2,
                          valueColor: theme.grey[50],
                        ),
                      )
                    : Icon(LucideIcons.send, size: 20),
                label: Text(
                  localization.translate('submit-feedback'),
                  style: TextStyles.body.copyWith(
                    color: theme.grey[50],
                    fontWeight: FontWeight.w500,
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
