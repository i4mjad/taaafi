import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/features/groups/domain/entities/group_entity.dart';

class GroupDetailsModal extends ConsumerWidget {
  final GroupEntity group;
  final VoidCallback? onJoin;

  const GroupDetailsModal({
    super.key,
    required this.group,
    this.onJoin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return SafeArea(
        child: Container(
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
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

            // Close button
            Padding(
              padding: EdgeInsets.only(
                top: Spacing.points8.value,
                right: Spacing.points16.value,
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: EdgeInsets.all(Spacing.points8.value),
                    decoration: BoxDecoration(
                      color: theme.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      LucideIcons.x,
                      size: 20,
                      color: theme.grey[600],
                    ),
                  ),
                ),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.all(Spacing.points20.value),
              child: Column(
                children: [
                  // Group icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.primary[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      LucideIcons.users,
                      color: theme.primary[600],
                      size: 40,
                    ),
                  ),

                  verticalSpace(Spacing.points16),

                  // Group name
                  Text(
                    group.name,
                    style: TextStyles.h4.copyWith(
                      color: theme.grey[900],
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  verticalSpace(Spacing.points8),

                  // Member count and capacity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.users,
                        size: 16,
                        color: theme.grey[600],
                      ),
                      horizontalSpace(Spacing.points4),
                      Text(
                        '${group.memberCount}/${group.memberCapacity} ${l10n.translate('members')}',
                        style: TextStyles.body.copyWith(
                          color: theme.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Description
            if (group.description.isNotEmpty)
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: Spacing.points20.value),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('description'),
                      style: TextStyles.h6.copyWith(
                        color: theme.grey[900],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    verticalSpace(Spacing.points8),
                    WidgetsContainer(
                      backgroundColor: theme.grey[50],
                      width: double.infinity,
                      borderSide: BorderSide(color: theme.grey[200]!),
                      padding: EdgeInsets.all(Spacing.points16.value),
                      child: Text(
                        group.description,
                        style: TextStyles.body.copyWith(
                          color: theme.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ),
                    verticalSpace(Spacing.points20),
                  ],
                ),
              ),

            // Group details
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Spacing.points20.value),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.translate('group-details'),
                    style: TextStyles.h6.copyWith(
                      color: theme.grey[900],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  verticalSpace(Spacing.points12),

                  // Group details grid
                  WidgetsContainer(
                    backgroundColor: theme.grey[50],
                    borderSide: BorderSide(color: theme.grey[200]!),
                    padding: EdgeInsets.all(Spacing.points16.value),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          context,
                          theme,
                          l10n,
                          LucideIcons.globe,
                          l10n.translate('visibility'),
                          _getVisibilityText(group.visibility, l10n),
                        ),
                        _buildDivider(theme),
                        _buildDetailRow(
                          context,
                          theme,
                          l10n,
                          LucideIcons.userPlus,
                          l10n.translate('join-method'),
                          _getJoinMethodText(group.joinMethod, l10n),
                        ),
                        _buildDivider(theme),
                        _buildDetailRow(
                          context,
                          theme,
                          l10n,
                          LucideIcons.languages,
                          l10n.translate('preferred-language'),
                          _getLanguageText(group.preferredLanguage, l10n),
                        ),
                        _buildDivider(theme),
                        _buildDetailRow(
                          context,
                          theme,
                          l10n,
                          LucideIcons.users2,
                          l10n.translate('gender-restriction'),
                          _getGenderRestrictionText(group.gender, l10n),
                        ),
                        _buildDivider(theme),
                        _buildDetailRow(
                          context,
                          theme,
                          l10n,
                          LucideIcons.calendar,
                          l10n.translate('created'),
                          _formatDate(group.createdAt, l10n),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Join button (if onJoin callback is provided)
            if (onJoin != null)
              Padding(
                padding: EdgeInsets.all(Spacing.points20.value),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: onJoin,
                      child: WidgetsContainer(
                        backgroundColor: theme.primary[600]!,
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                        padding: EdgeInsets.all(Spacing.points16.value),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.userPlus,
                              color: Colors.white,
                              size: 20,
                            ),
                            horizontalSpace(Spacing.points8),
                            Text(
                              l10n.translate('join-group'),
                              style: TextStyles.h6.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    verticalSpace(Spacing.points12),
                    Text(
                      l10n.translate('group-join-disclaimer'),
                      style: TextStyles.caption.copyWith(
                        color: theme.grey[600],
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

            // Bottom padding
            verticalSpace(Spacing.points20),
          ],
        ),
      ),
    ));
  }

  Widget _buildDetailRow(
    BuildContext context,
    theme,
    AppLocalizations l10n,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Spacing.points8.value),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.grey[600],
          ),
          horizontalSpace(Spacing.points12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyles.body.copyWith(
                color: theme.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyles.body.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(theme) {
    return Divider(
      color: theme.grey[200],
      height: 1,
    );
  }

  String _getVisibilityText(String visibility, AppLocalizations l10n) {
    switch (visibility) {
      case 'public':
        return l10n.translate('public');
      case 'private':
        return l10n.translate('private');
      default:
        return visibility;
    }
  }

  String _getJoinMethodText(String joinMethod, AppLocalizations l10n) {
    switch (joinMethod) {
      case 'any':
        return l10n.translate('anyone-can-join');
      case 'admin_only':
        return l10n.translate('admin-approval-required');
      case 'code_only':
        return l10n.translate('join-code-required');
      default:
        return joinMethod;
    }
  }

  String _getLanguageText(String? language, AppLocalizations l10n) {
    switch (language?.toLowerCase()) {
      case 'arabic':
        return l10n.translate('arabic');
      case 'english':
        return l10n.translate('english');
      default:
        // Fallback to Arabic if language is null, empty, or unrecognized
        return l10n.translate('arabic');
    }
  }

  String _getGenderRestrictionText(String gender, AppLocalizations l10n) {
    switch (gender.toLowerCase()) {
      case 'male':
        return l10n.translate('male-only');
      case 'female':
        return l10n.translate('female-only');
      default:
        return l10n.translate('mixed-gender');
    }
  }

  String _formatDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      return l10n.translate('today');
    } else if (difference.inDays == 1) {
      return l10n.translate('yesterday');
    } else if (difference.inDays < 7) {
      return l10n
          .translate('days-ago')
          .replaceAll('{count}', difference.inDays.toString());
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return l10n
          .translate('weeks-ago')
          .replaceAll('{count}', weeks.toString());
    } else {
      final months = (difference.inDays / 30).floor();
      return l10n
          .translate('months-ago')
          .replaceAll('{count}', months.toString());
    }
  }
}
