import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/home/data/models/user_report.dart';
import 'package:reboot_app_3/features/home/data/user_reports_notifier.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textarea.dart';

class DataErrorReportModal extends ConsumerStatefulWidget {
  const DataErrorReportModal({super.key});

  @override
  ConsumerState<DataErrorReportModal> createState() =>
      _DataErrorReportModalState();
}

class _DataErrorReportModalState extends ConsumerState<DataErrorReportModal> {
  final _textController = TextEditingController();
  // final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  UserReport? _existingReport;
  bool _isLoadingReport = true;

  @override
  void initState() {
    super.initState();
    _checkExistingReport();
  }

  Future<void> _checkExistingReport() async {
    try {
      final reportsNotifier = ref.read(userReportsNotifierProvider.notifier);
      final report = await reportsNotifier.getMostRecentReportOfTypeDataIssue();
      if (mounted) {
        setState(() {
          _existingReport = report;
          _isLoadingReport = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingReport = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String? _validateJustification(String? value) {
    final localization = AppLocalizations.of(context);
    if (value == null || value.trim().isEmpty) {
      return localization.translate('field-required');
    }
    if (value.length > 220) {
      return localization.translate('character-limit-exceeded');
    }
    return null;
  }

  Future<void> _submitReport() async {
    if (_validateJustification(_textController.text) != null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final reportsNotifier = ref.read(userReportsNotifierProvider.notifier);
      await reportsNotifier.submitDataErrorReport(
        userMessage: _textController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        getSuccessSnackBar(context, 'report-submitted-successfully');
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

  Widget _buildNewReportForm() {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localization.translate('report-data-error-description'),
          style: TextStyles.body.copyWith(
            color: theme.grey[700],
            height: 1.4,
          ),
        ),
        verticalSpace(Spacing.points16),
        // User justification text area
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localization.translate('user-justification'),
              style: TextStyles.footnote,
            ),
            verticalSpace(Spacing.points8),
            CustomTextArea(
              controller: _textController,
              hint: localization.translate('user-justification-placeholder'),
              prefixIcon: LucideIcons.messageSquare,
              validator: _validateJustification,
              enabled: !_isSubmitting,
              height: 120,
            ),
          ],
        ),
        verticalSpace(Spacing.points24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary[600],
                  foregroundColor: theme.grey[50],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: Spinner(
                          strokeWidth: 2,
                          valueColor: theme.grey[50],
                        ),
                      )
                    : Text(
                        localization.translate('submit-report'),
                        style: TextStyles.body.copyWith(
                          color: theme.grey[50],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            horizontalSpace(Spacing.points12),
            Expanded(
              child: OutlinedButton(
                onPressed:
                    _isSubmitting ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.grey[700],
                  side: BorderSide(color: theme.grey[300]!),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  localization.translate('cancel'),
                  style: TextStyles.body.copyWith(
                    color: theme.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExistingReportView() {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);
    final report = _existingReport!;

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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WidgetsContainer(
          padding: EdgeInsets.all(16),
          backgroundColor: theme.backgroundColor,
          borderSide: BorderSide.none,
          boxShadow: Shadows.mainShadows,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.clock,
                    size: 16,
                    color: theme.grey[600],
                  ),
                  horizontalSpace(Spacing.points4),
                  Text(
                    localization.translate('submitted-at'),
                    style: TextStyles.small.copyWith(
                      color: theme.grey[600],
                    ),
                  ),
                  horizontalSpace(Spacing.points4),
                  Text(
                    getDisplayDateTime(
                      report.time,
                      localization.locale.languageCode,
                    ),
                    style: TextStyles.small.copyWith(
                      color: theme.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              verticalSpace(Spacing.points8),
              Row(
                children: [
                  Icon(
                    LucideIcons.info,
                    size: 16,
                    color: statusColor,
                  ),
                  horizontalSpace(Spacing.points4),
                  Text(
                    localization.translate('report-status'),
                    style: TextStyles.small.copyWith(
                      color: theme.grey[600],
                    ),
                  ),
                  horizontalSpace(Spacing.points4),
                  Text(
                    localization.translate(statusKey),
                    style: TextStyles.small.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        verticalSpace(Spacing.points16),
        Text(
          localization.translate('initial-message'),
          style: TextStyles.body.copyWith(
            color: theme.grey[800],
            fontWeight: FontWeight.w500,
          ),
        ),
        verticalSpace(Spacing.points8),
        WidgetsContainer(
          padding: EdgeInsets.all(12),
          backgroundColor: theme.backgroundColor,
          borderSide: BorderSide(color: theme.grey[300]!, width: 1),
          child: Text(
            report.initialMessage,
            style: TextStyles.body.copyWith(
              color: theme.grey[700],
              height: 1.4,
            ),
          ),
        ),
        verticalSpace(Spacing.points16),
        Row(
          children: [
            Text(
              localization.translate('messages-count'),
              style: TextStyles.body.copyWith(
                color: theme.grey[600],
              ),
            ),
            horizontalSpace(Spacing.points8),
            Text(
              report.messagesCount.toString(),
              style: TextStyles.body.copyWith(
                color: theme.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        verticalSpace(Spacing.points24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.pushNamed(
                    RouteNames.reportConversation.name,
                    pathParameters: {'reportId': report.id},
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary[600],
                  foregroundColor: theme.grey[50],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  localization.translate('view-report'),
                  style: TextStyles.body.copyWith(
                    color: theme.grey[50],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            horizontalSpace(Spacing.points12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.grey[700],
                  side: BorderSide(color: theme.grey[300]!),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  localization.translate('close'),
                  style: TextStyles.body.copyWith(
                    color: theme.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);

    return Container(
      color: theme.backgroundColor,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: IntrinsicHeight(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.alertTriangle,
                    color: theme.warn[600],
                    size: 24,
                  ),
                  horizontalSpace(Spacing.points8),
                  Expanded(
                    child: Text(
                      localization.translate('report-data-error'),
                      style: TextStyles.h6.copyWith(
                        color: theme.grey[900],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(
                      LucideIcons.x,
                      color: theme.grey[500],
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _isLoadingReport
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Spinner(),
                        ),
                      )
                    : _existingReport != null
                        ? _buildExistingReportView()
                        : _buildNewReportForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
