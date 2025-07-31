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

class FeatureSuggestionModal extends ConsumerStatefulWidget {
  const FeatureSuggestionModal({super.key});

  @override
  ConsumerState<FeatureSuggestionModal> createState() =>
      _FeatureSuggestionModalState();
}

class _FeatureSuggestionModalState
    extends ConsumerState<FeatureSuggestionModal> {
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

  Future<void> _submitFeatureSuggestion() async {
    if (_validateMessage(_messageController.text) != null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final reportsNotifier = ref.read(userReportsNotifierProvider.notifier);
      final reportId = await reportsNotifier.submitFeatureSuggestionReport(
        userMessage: _messageController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        context.pushNamed(
          RouteNames.reportConversation.name,
          pathParameters: {'reportId': reportId},
        );

        getSuccessSnackBar(context, 'feature-suggestion-submitted');
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
                    localization.translate('suggest-feature'),
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
              localization.translate('feature-suggestion-description'),
              style: TextStyles.body.copyWith(
                color: theme.grey[700],
                height: 1.5,
              ),
            ),

            verticalSpace(Spacing.points16),

            // Enhanced note about feature evaluation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primary[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.primary[200]!,
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.lightbulb,
                    size: 20,
                    color: theme.primary[600],
                  ),
                  horizontalSpace(Spacing.points8),
                  Expanded(
                    child: Text(
                      localization.translate('feature-suggestion-note'),
                      style: TextStyles.footnote.copyWith(
                        color: theme.primary[700],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            verticalSpace(Spacing.points24),

            // Message input
            CustomTextArea(
              controller: _messageController,
              hint: localization.translate('feature-suggestion-placeholder'),
              prefixIcon: LucideIcons.lightbulb,
              validator: _validateMessage,
              enabled: !_isSubmitting,
              height: 140,
            ),

            verticalSpace(Spacing.points8),

            // Character count
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitFeatureSuggestion,
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
                        child: Spinner(),
                      )
                    : Icon(LucideIcons.send, size: 20),
                label: Text(
                  localization.translate('submit-suggestion'),
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
