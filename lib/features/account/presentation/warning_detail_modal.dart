import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/features/account/data/models/warning.dart';

class WarningDetailModal extends ConsumerWidget {
  final Warning warning;

  const WarningDetailModal({
    super.key,
    required this.warning,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final locale = ref.watch(localeNotifierProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: theme.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(warning.severity, theme)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.alertTriangle,
                    color: _getSeverityColor(warning.severity, theme),
                    size: 24,
                  ),
                ),
                horizontalSpace(Spacing.points16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)
                            .translate('warning-details'),
                        style: TextStyles.h5.copyWith(
                          color: theme.grey[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      verticalSpace(Spacing.points4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(warning.severity, theme),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getSeverityText(warning.severity, context),
                          style: TextStyles.small.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    LucideIcons.x,
                    color: theme.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main reason
                  _buildDetailSection(
                    context,
                    theme,
                    AppLocalizations.of(context).translate('reason'),
                    warning.reason,
                    LucideIcons.messageCircle,
                  ),

                  if (warning.description != null) ...[
                    verticalSpace(Spacing.points20),
                    _buildDetailSection(
                      context,
                      theme,
                      AppLocalizations.of(context).translate('description'),
                      warning.description!,
                      LucideIcons.fileText,
                    ),
                  ],

                  verticalSpace(Spacing.points20),

                  // Warning details grid
                  _buildDetailsGrid(context, theme, locale),

                  if (warning.relatedContent != null) ...[
                    verticalSpace(Spacing.points20),
                    _buildRelatedContentSection(context, theme),
                  ],

                  verticalSpace(Spacing.points24),

                  // Important notice
                  _buildImportantNotice(context, theme),

                  verticalSpace(Spacing.points24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(
    BuildContext context,
    CustomThemeData theme,
    String title,
    String content,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: theme.grey[600],
              size: 18,
            ),
            horizontalSpace(Spacing.points8),
            Text(
              title,
              style: TextStyles.body.copyWith(
                color: theme.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        verticalSpace(Spacing.points8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.grey[200]!, width: 1),
          ),
          child: Text(
            content,
            style: TextStyles.body.copyWith(
              color: theme.grey[800],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsGrid(
    BuildContext context,
    CustomThemeData theme,
    Locale? locale,
  ) {
    return WidgetsContainer(
      padding: const EdgeInsets.all(16),
      backgroundColor: theme.grey[50],
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).translate('warning-information'),
            style: TextStyles.body.copyWith(
              color: theme.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          verticalSpace(Spacing.points12),
          _buildDetailRow(
            context,
            theme,
            AppLocalizations.of(context).translate('warning-type'),
            _getWarningTypeText(warning.type, context),
            LucideIcons.tag,
          ),
          verticalSpace(Spacing.points8),
          _buildDetailRow(
            context,
            theme,
            AppLocalizations.of(context).translate('issued-date'),
            getDisplayDate(warning.issuedAt, locale?.languageCode ?? 'en'),
            LucideIcons.calendar,
          ),
          verticalSpace(Spacing.points8),
          _buildDetailRow(
            context,
            theme,
            AppLocalizations.of(context).translate('status'),
            warning.isActive
                ? AppLocalizations.of(context).translate('active')
                : AppLocalizations.of(context).translate('inactive'),
            warning.isActive
                ? LucideIcons.alertCircle
                : LucideIcons.checkCircle,
          ),
          verticalSpace(Spacing.points8),
          _buildDetailRow(
            context,
            theme,
            AppLocalizations.of(context).translate('warning-id'),
            warning.id,
            LucideIcons.hash,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    CustomThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: theme.grey[500],
          size: 16,
        ),
        horizontalSpace(Spacing.points8),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyles.small.copyWith(
              color: theme.grey[600],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyles.small.copyWith(
              color: theme.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedContentSection(
    BuildContext context,
    CustomThemeData theme,
  ) {
    final relatedContent = warning.relatedContent!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.link,
              color: theme.grey[600],
              size: 18,
            ),
            horizontalSpace(Spacing.points8),
            Text(
              AppLocalizations.of(context).translate('related-content'),
              style: TextStyles.body.copyWith(
                color: theme.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        verticalSpace(Spacing.points8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.primary[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.primary[200]!, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.primary[600],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getLocalizedContentType(relatedContent.type, context),
                      style: TextStyles.small.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (relatedContent.title != null) ...[
                verticalSpace(Spacing.points8),
                Text(
                  relatedContent.title!,
                  style: TextStyles.body.copyWith(
                    color: theme.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              verticalSpace(Spacing.points4),
              Text(
                '${AppLocalizations.of(context).translate('id')}: ${relatedContent.id}',
                style: TextStyles.small.copyWith(
                  color: theme.grey[600],
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImportantNotice(
    BuildContext context,
    CustomThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.warn[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.warn[200]!, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.info,
            color: theme.warn[600],
            size: 20,
          ),
          horizontalSpace(Spacing.points12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).translate('important-notice'),
                  style: TextStyles.body.copyWith(
                    color: theme.warn[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                verticalSpace(Spacing.points4),
                Text(
                  AppLocalizations.of(context)
                      .translate('warning-notice-description'),
                  style: TextStyles.small.copyWith(
                    color: theme.warn[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(WarningSeverity severity, CustomThemeData theme) {
    switch (severity) {
      case WarningSeverity.low:
        return theme.primary[500]!;
      case WarningSeverity.medium:
        return theme.warn[500]!;
      case WarningSeverity.high:
        return theme.error[500]!;
      case WarningSeverity.critical:
        return theme.error[700]!;
    }
  }

  String _getSeverityText(WarningSeverity severity, BuildContext context) {
    switch (severity) {
      case WarningSeverity.low:
        return AppLocalizations.of(context).translate('low');
      case WarningSeverity.medium:
        return AppLocalizations.of(context).translate('medium');
      case WarningSeverity.high:
        return AppLocalizations.of(context).translate('high');
      case WarningSeverity.critical:
        return AppLocalizations.of(context).translate('critical');
    }
  }

  String _getWarningTypeText(WarningType type, BuildContext context) {
    switch (type) {
      case WarningType.content_violation:
        return AppLocalizations.of(context).translate('content-violation');
      case WarningType.inappropriate_behavior:
        return AppLocalizations.of(context).translate('inappropriate-behavior');
      case WarningType.spam:
        return AppLocalizations.of(context).translate('spam');
      case WarningType.harassment:
        return AppLocalizations.of(context).translate('harassment');
      case WarningType.other:
        return AppLocalizations.of(context).translate('other');
    }
  }

  String _getLocalizedContentType(String type, BuildContext context) {
    switch (type.toLowerCase()) {
      case 'user':
        return AppLocalizations.of(context).translate('related-content-user');
      case 'report':
        return AppLocalizations.of(context).translate('related-content-report');
      case 'post':
        return AppLocalizations.of(context).translate('related-content-post');
      case 'comment':
        return AppLocalizations.of(context)
            .translate('related-content-comment');
      case 'message':
        return AppLocalizations.of(context)
            .translate('related-content-message');
      case 'group':
        return AppLocalizations.of(context).translate('related-content-group');
      case 'other':
        return AppLocalizations.of(context).translate('related-content-other');
      default:
        return AppLocalizations.of(context).translate('related-content-other');
    }
  }
}
