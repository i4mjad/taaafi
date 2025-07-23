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
import 'package:reboot_app_3/features/community/data/models/post.dart';
import 'package:reboot_app_3/features/community/data/models/comment.dart';

enum ReportContentType { post, comment }

class ReportContentModal extends ConsumerStatefulWidget {
  final ReportContentType contentType;
  final Post? post;
  final Comment? comment;

  const ReportContentModal({
    super.key,
    required this.contentType,
    this.post,
    this.comment,
  }) : assert(
          (contentType == ReportContentType.post && post != null) ||
              (contentType == ReportContentType.comment && comment != null),
        );

  @override
  ConsumerState<ReportContentModal> createState() => _ReportContentModalState();
}

class _ReportContentModalState extends ConsumerState<ReportContentModal> {
  final TextEditingController _justificationController =
      TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _justificationController.dispose();
    super.dispose();
  }

  String? _validateJustification(String? value) {
    final localization = AppLocalizations.of(context);
    if (value == null || value.trim().isEmpty) {
      return localization.translate('report_justification_required');
    }
    if (value.length > 500) {
      return localization.translate('report_justification_too_long');
    }
    return null;
  }

  String get _contentPreview {
    switch (widget.contentType) {
      case ReportContentType.post:
        final post = widget.post!;
        final title = post.title.isNotEmpty ? post.title : 'No title';
        final body = post.body.length > 100
            ? '${post.body.substring(0, 100)}...'
            : post.body;
        return '$title\n\n$body';
      case ReportContentType.comment:
        final comment = widget.comment!;
        return comment.body.length > 150
            ? '${comment.body.substring(0, 150)}...'
            : comment.body;
    }
  }

  String get _contentId {
    switch (widget.contentType) {
      case ReportContentType.post:
        return widget.post!.id;
      case ReportContentType.comment:
        return widget.comment!.id;
    }
  }

  Future<void> _submitReport() async {
    if (_validateJustification(_justificationController.text) != null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final reportsNotifier = ref.read(userReportsNotifierProvider.notifier);
      final justification = _justificationController.text.trim();

      String reportId;
      switch (widget.contentType) {
        case ReportContentType.post:
          reportId = await reportsNotifier.submitPostReport(
            postId: _contentId,
            userMessage: justification,
          );
          break;
        case ReportContentType.comment:
          reportId = await reportsNotifier.submitCommentReport(
            commentId: _contentId,
            userMessage: justification,
          );
          break;
      }

      if (mounted) {
        Navigator.of(context).pop();
        context.pushNamed(
          RouteNames.reportConversation.name,
          pathParameters: {'reportId': reportId},
        );

        final contentType =
            widget.contentType == ReportContentType.post ? 'post' : 'comment';
        getSuccessSnackBar(context, 'report_${contentType}_submitted');
      }
    } catch (e) {
      if (mounted) {
        // Extract the localization key from the exception message
        String errorKey = 'report_submission_failed';
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
    final contentType = widget.contentType == ReportContentType.post
        ? localization.translate('post')
        : localization.translate('comment');

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
                    localization.translate('report_content').replaceAll(
                        '{type}', localization.translate(contentType)),
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

            // Warning message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.warn[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.warn[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.alertTriangle,
                    size: 20,
                    color: theme.warn[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      localization.translate('report_responsibility_warning'),
                      style: TextStyles.caption.copyWith(
                        color: theme.warn[700],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            verticalSpace(Spacing.points16),

            // Content preview
            Text(
              localization.translate('report_content_being_reported'),
              style: TextStyles.body.copyWith(
                color: theme.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),

            verticalSpace(Spacing.points8),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.grey[200]!),
              ),
              child: Text(
                _contentPreview,
                style: TextStyles.caption.copyWith(
                  color: theme.grey[700],
                  height: 1.4,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            verticalSpace(Spacing.points16),

            // Justification input
            Text(
              localization.translate('report_justification_label'),
              style: TextStyles.body.copyWith(
                color: theme.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),

            verticalSpace(Spacing.points8),

            CustomTextArea(
              controller: _justificationController,
              hint: localization.translate('report_justification_placeholder'),
              prefixIcon: LucideIcons.fileText,
              validator: _validateJustification,
              enabled: !_isSubmitting,
              height: 120,
            ),

            verticalSpace(Spacing.points8),

            // Character count
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  localization
                      .translate('character_count')
                      .replaceAll('{current}',
                          _justificationController.text.length.toString())
                      .replaceAll('{max}', '500'),
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
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.error[600],
                  foregroundColor: theme.grey[50],
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                    : Icon(LucideIcons.flag, size: 20),
                label: Text(
                  localization.translate('submit_report'),
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
