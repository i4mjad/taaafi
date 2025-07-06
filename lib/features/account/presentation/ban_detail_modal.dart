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
import 'package:reboot_app_3/features/account/data/models/ban.dart';
import 'package:reboot_app_3/features/account/utils/ban_display_formatter.dart';

class BanDetailModal extends ConsumerWidget {
  final Ban ban;

  const BanDetailModal({
    super.key,
    required this.ban,
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
                    color: _getBanScopeColor(ban.scope, theme).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    ban.scope == BanScope.app_wide
                        ? LucideIcons.shieldOff
                        : LucideIcons.shieldAlert,
                    color: _getBanScopeColor(ban.scope, theme),
                    size: 24,
                  ),
                ),
                horizontalSpace(Spacing.points16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).translate('ban-details'),
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
                          color: _getBanScopeColor(ban.scope, theme),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          ban.scope == BanScope.app_wide
                              ? AppLocalizations.of(context)
                                  .translate('app-wide')
                              : AppLocalizations.of(context)
                                  .translate('feature-specific'),
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
                    ban.reason,
                    LucideIcons.messageCircle,
                  ),

                  if (ban.description != null) ...[
                    verticalSpace(Spacing.points20),
                    _buildDetailSection(
                      context,
                      theme,
                      AppLocalizations.of(context).translate('description'),
                      ban.description!,
                      LucideIcons.fileText,
                    ),
                  ],

                  verticalSpace(Spacing.points20),

                  // Ban details grid
                  _buildDetailsGrid(context, theme, locale),

                  if (ban.restrictedFeatures != null &&
                      ban.restrictedFeatures!.isNotEmpty) ...[
                    verticalSpace(Spacing.points20),
                    _buildRestrictedFeaturesSection(context, theme),
                  ],

                  if (ban.relatedContent != null) ...[
                    verticalSpace(Spacing.points20),
                    _buildRelatedContentSection(context, theme),
                  ],

                  verticalSpace(Spacing.points24),

                  // Appeal information
                  _buildAppealInformation(context, theme),

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
            AppLocalizations.of(context).translate('ban-information'),
            style: TextStyles.body.copyWith(
              color: theme.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          verticalSpace(Spacing.points12),
          _buildDetailRow(
            context,
            theme,
            AppLocalizations.of(context).translate('ban-type'),
            _getBanTypeText(ban.type, context),
            LucideIcons.tag,
          ),
          verticalSpace(Spacing.points8),
          _buildDetailRow(
            context,
            theme,
            AppLocalizations.of(context).translate('severity'),
            _getBanSeverityText(ban.severity, context),
            LucideIcons.alertTriangle,
          ),
          verticalSpace(Spacing.points8),
          _buildDetailRow(
            context,
            theme,
            AppLocalizations.of(context).translate('issued-date'),
            getDisplayDate(ban.issuedAt, locale?.languageCode ?? 'en'),
            LucideIcons.calendar,
          ),
          verticalSpace(Spacing.points8),
          _buildDetailRow(
            context,
            theme,
            AppLocalizations.of(context).translate('duration'),
            BanDisplayFormatter.formatBanDuration(ban, context),
            LucideIcons.clock,
          ),
          if (ban.expiresAt != null) ...[
            verticalSpace(Spacing.points8),
            _buildDetailRow(
              context,
              theme,
              AppLocalizations.of(context).translate('expires-on'),
              getDisplayDate(ban.expiresAt!, locale?.languageCode ?? 'en'),
              LucideIcons.calendarX,
            ),
          ],
          verticalSpace(Spacing.points8),
          _buildDetailRow(
            context,
            theme,
            AppLocalizations.of(context).translate('status'),
            ban.isActive
                ? AppLocalizations.of(context).translate('active')
                : AppLocalizations.of(context).translate('inactive'),
            ban.isActive ? LucideIcons.alertCircle : LucideIcons.checkCircle,
          ),
          verticalSpace(Spacing.points8),
          _buildDetailRow(
            context,
            theme,
            AppLocalizations.of(context).translate('ban-id'),
            ban.id,
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

  Widget _buildRestrictedFeaturesSection(
    BuildContext context,
    CustomThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.lock,
              color: theme.grey[600],
              size: 18,
            ),
            horizontalSpace(Spacing.points8),
            Text(
              AppLocalizations.of(context).translate('restricted-features'),
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
            color: theme.error[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.error[200]!, width: 1),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ban.restrictedFeatures!
                .map((feature) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.error[100],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: theme.error[300]!, width: 1),
                      ),
                      child: Text(
                        AppLocalizations.of(context).translate(feature),
                        style: TextStyles.small.copyWith(
                          color: theme.error[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedContentSection(
    BuildContext context,
    CustomThemeData theme,
  ) {
    final relatedContent = ban.relatedContent!;

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

  Widget _buildAppealInformation(
    BuildContext context,
    CustomThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primary[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primary[200]!, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.messageSquare,
            color: theme.primary[600],
            size: 20,
          ),
          horizontalSpace(Spacing.points12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).translate('appeal-information'),
                  style: TextStyles.body.copyWith(
                    color: theme.primary[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                verticalSpace(Spacing.points4),
                Text(
                  AppLocalizations.of(context)
                      .translate('ban-appeal-description'),
                  style: TextStyles.small.copyWith(
                    color: theme.primary[700],
                    height: 1.4,
                  ),
                ),
                verticalSpace(Spacing.points8),
                Text(
                  '${AppLocalizations.of(context).translate('reference-id')}: ${ban.id}',
                  style: TextStyles.small.copyWith(
                    color: theme.primary[600],
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getBanScopeColor(BanScope scope, CustomThemeData theme) {
    switch (scope) {
      case BanScope.app_wide:
        return theme.error[600]!;
      case BanScope.feature_specific:
        return theme.warn[600]!;
    }
  }

  String _getBanTypeText(BanType type, BuildContext context) {
    switch (type) {
      case BanType.user_ban:
        return AppLocalizations.of(context).translate('user-ban');
      case BanType.device_ban:
        return AppLocalizations.of(context).translate('device-ban');
      case BanType.feature_ban:
        return AppLocalizations.of(context).translate('feature-ban');
    }
  }

  String _getBanSeverityText(BanSeverity severity, BuildContext context) {
    switch (severity) {
      case BanSeverity.temporary:
        return AppLocalizations.of(context).translate('temporary');
      case BanSeverity.permanent:
        return AppLocalizations.of(context).translate('permanent');
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
