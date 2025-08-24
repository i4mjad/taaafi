import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/groups/providers/group_membership_provider.dart';

class GroupOverviewCard extends ConsumerWidget {
  const GroupOverviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final groupMembershipAsync = ref.watch(groupMembershipNotifierProvider);
    final locale = Localizations.localeOf(context);

    return groupMembershipAsync.when(
      loading: () => WidgetsContainer(
        width: MediaQuery.of(context).size.width - 32,
        padding: const EdgeInsets.all(16),
        backgroundColor: theme.backgroundColor,
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: theme.grey[900]!, width: 0.25),
        cornerSmoothing: 1,
        child: const Center(child: Spinner()),
      ),
      error: (error, _) => WidgetsContainer(
        width: MediaQuery.of(context).size.width - 32,
        padding: const EdgeInsets.all(16),
        backgroundColor: theme.backgroundColor,
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: theme.error[300]!, width: 0.25),
        cornerSmoothing: 1,
        child: Row(
          children: [
            Icon(
              LucideIcons.alertCircle,
              color: theme.error[600],
              size: 20,
            ),
            horizontalSpace(Spacing.points8),
            Expanded(
              child: Text(
                l10n.translate('error-loading-group'),
                style: TextStyles.body.copyWith(color: theme.error[700]),
              ),
            ),
          ],
        ),
      ),
      data: (groupMembership) {
        if (groupMembership == null) {
          return WidgetsContainer(
            width: MediaQuery.of(context).size.width - 32,
            padding: const EdgeInsets.all(16),
            backgroundColor: theme.backgroundColor,
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: theme.grey[300]!, width: 0.25),
            cornerSmoothing: 1,
            child: Row(
              children: [
                Icon(
                  LucideIcons.users,
                  color: theme.grey[600],
                  size: 20,
                ),
                horizontalSpace(Spacing.points8),
                Expanded(
                  child: Text(
                    l10n.translate('no-group-found'),
                    style: TextStyles.body.copyWith(color: theme.grey[700]),
                  ),
                ),
              ],
            ),
          );
        }

        final group = groupMembership.group;
        final isAdmin = groupMembership.memberRole == 'admin';

        return Padding(
          padding: const EdgeInsets.all(4.0),
          child: WidgetsContainer(
            width: MediaQuery.of(context).size.width - 32,
            padding: const EdgeInsets.all(16),
            backgroundColor: theme.backgroundColor,
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: theme.grey[900]!, width: 0.25),
            cornerSmoothing: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section - Group Icon, Name, Role
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getGenderColor(group.gender, theme),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        LucideIcons.users,
                        color: _getGenderIconColor(group.gender, theme),
                        size: 24,
                      ),
                    ),

                    horizontalSpace(Spacing.points12),

                    // Group Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name and Role Badge Row
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  group.name,
                                  style: TextStyles.footnoteSelected.copyWith(
                                    color: theme.grey[900],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              horizontalSpace(Spacing.points8),
                              // Member role badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isAdmin
                                      ? theme.primary[100]
                                      : theme.grey[100],
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isAdmin
                                        ? theme.primary[300]!
                                        : theme.grey[300]!,
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isAdmin
                                          ? LucideIcons.crown
                                          : LucideIcons.user,
                                      size: 10,
                                      color: isAdmin
                                          ? theme.primary[600]
                                          : theme.grey[600],
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      isAdmin
                                          ? l10n.translate('group-admin')
                                          : l10n.translate('group-member'),
                                      style: TextStyles.small.copyWith(
                                        color: isAdmin
                                            ? theme.primary[700]
                                            : theme.grey[600],
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Description
                          if (group.description.isNotEmpty) ...[
                            verticalSpace(Spacing.points4),
                            Text(
                              group.description,
                              style: TextStyles.caption.copyWith(
                                color: theme.grey[600],
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                verticalSpace(Spacing.points12),

                // Stats Section
                Row(
                  children: [
                    // Member count
                    _buildStatChip(
                      context: context,
                      theme: theme,
                      icon: LucideIcons.users,
                      label: '${group.memberCount}/${group.capacity}',
                      tooltip: l10n.translate('members'),
                    ),

                    horizontalSpace(Spacing.points8),

                    // Gender
                    _buildStatChip(
                      context: context,
                      theme: theme,
                      icon: group.gender == 'male'
                          ? LucideIcons.userCheck
                          : LucideIcons.userX,
                      label: l10n.translate(group.gender),
                      tooltip: l10n.translate('group-gender'),
                    ),

                    if (groupMembership.totalPoints > 0) ...[
                      horizontalSpace(Spacing.points8),
                      // Points
                      _buildStatChip(
                        context: context,
                        theme: theme,
                        icon: LucideIcons.star,
                        label: '${groupMembership.totalPoints}',
                        tooltip: l10n.translate('total-points'),
                        isHighlight: true,
                      ),
                    ],
                  ],
                ),

                verticalSpace(Spacing.points12),

                // Dates Section
                Column(
                  children: [
                    // Joined date
                    Row(
                      children: [
                        Icon(
                          LucideIcons.calendar,
                          size: 12,
                          color: theme.grey[500],
                        ),
                        horizontalSpace(Spacing.points4),
                        Flexible(
                          child: Text(
                            '${l10n.translate('joined')}: ${getDisplayDateTime(groupMembership.joinedAt, locale.languageCode)}',
                            style: TextStyles.small.copyWith(
                              color: theme.grey[500],
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    verticalSpace(Spacing.points12),
                    // Created date
                    Row(
                      children: [
                        Icon(
                          LucideIcons.plus,
                          size: 12,
                          color: theme.grey[500],
                        ),
                        horizontalSpace(Spacing.points4),
                        Flexible(
                          child: Text(
                            '${l10n.translate('created')}: ${getDisplayDateTime(group.createdAt, locale.languageCode)}',
                            style: TextStyles.small.copyWith(
                              color: theme.grey[500],
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                verticalSpace(Spacing.points12),

                // Sharing Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.grey[200]!, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sharing Header
                      Row(
                        children: [
                          Icon(
                            _getIconForJoinMethod(group.joinMethod),
                            color: theme.primary[600],
                            size: 16,
                          ),
                          horizontalSpace(Spacing.points4),
                          Text(
                            l10n.translate('group-sharing'),
                            style: TextStyles.small.copyWith(
                              color: theme.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      verticalSpace(Spacing.points4),

                      // Join method specific content
                      ..._buildJoinMethodContent(group.joinMethod, isAdmin,
                          group, theme, l10n, context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildJoinMethodContent(
    String joinMethod,
    bool isAdmin,
    dynamic group,
    CustomThemeData theme,
    AppLocalizations l10n,
    BuildContext context,
  ) {
    switch (joinMethod) {
      case 'code_only':
        if (isAdmin) {
          return [
            Text(
              l10n.translate('code-only-admin-desc'),
              style: TextStyles.caption.copyWith(
                color: theme.grey[600],
                height: 1.3,
              ),
            ),
            verticalSpace(Spacing.points4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.warn[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: theme.warn[200]!, width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.alertTriangle,
                    color: theme.warn[600],
                    size: 14,
                  ),
                  horizontalSpace(Spacing.points4),
                  Expanded(
                    child: Text(
                      l10n.translate('join-code-not-retrievable'),
                      style: TextStyles.small.copyWith(
                        color: theme.warn[700],
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ];
        } else {
          return [
            Text(
              l10n.translate('code-only-member-desc'),
              style: TextStyles.caption.copyWith(
                color: theme.grey[600],
                height: 1.3,
              ),
            ),
          ];
        }

      case 'any':
        return [
          Text(
            l10n.translate('any-join-desc'),
            style: TextStyles.caption.copyWith(
              color: theme.grey[600],
              height: 1.3,
            ),
          ),
          verticalSpace(Spacing.points8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: theme.primary[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: theme.primary[200]!, width: 0.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate('group-id'),
                        style: TextStyles.small.copyWith(
                          color: theme.grey[600],
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        group.id,
                        style: TextStyles.caption.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                          color: theme.grey[900],
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _copyToClipboard(group.id, context, l10n),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.primary[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      LucideIcons.copy,
                      color: theme.primary[600],
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ];

      case 'admin_only':
        return [
          Text(
            isAdmin
                ? l10n.translate('admin-only-admin-desc')
                : l10n.translate('admin-only-member-desc'),
            style: TextStyles.caption.copyWith(
              color: theme.grey[600],
              height: 1.3,
            ),
          ),
          if (isAdmin) ...[
            verticalSpace(Spacing.points4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.primary[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: theme.primary[200]!, width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.info,
                    color: theme.primary[600],
                    size: 14,
                  ),
                  horizontalSpace(Spacing.points4),
                  Expanded(
                    child: Text(
                      l10n.translate('invitation-feature-coming-soon'),
                      style: TextStyles.small.copyWith(
                        color: theme.primary[700],
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ];

      default:
        return [];
    }
  }

  Widget _buildStatChip({
    required BuildContext context,
    required CustomThemeData theme,
    required IconData icon,
    required String label,
    required String tooltip,
    bool isHighlight = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isHighlight ? theme.primary[50] : theme.grey[50],
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isHighlight ? theme.primary[200]! : theme.grey[200]!,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 10,
              color: isHighlight ? theme.primary[600] : theme.grey[600],
            ),
            const SizedBox(width: 2),
            Text(
              label,
              style: TextStyles.small.copyWith(
                color: isHighlight ? theme.primary[700] : theme.grey[600],
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForJoinMethod(String joinMethod) {
    switch (joinMethod) {
      case 'code_only':
        return LucideIcons.key;
      case 'any':
        return LucideIcons.users;
      case 'admin_only':
        return LucideIcons.userCheck;
      default:
        return LucideIcons.share;
    }
  }

  void _copyToClipboard(
      String text, BuildContext context, AppLocalizations l10n) {
    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.translate('copied-to-clipboard')),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.of(context).success[600],
      ),
    );
  }

  Color _getGenderColor(String gender, CustomThemeData theme) {
    switch (gender.toLowerCase()) {
      case 'male':
        return theme.primary[50]!;
      case 'female':
        return theme.secondary[50]!;
      default:
        return theme.grey[50]!;
    }
  }

  Color _getGenderIconColor(String gender, CustomThemeData theme) {
    switch (gender.toLowerCase()) {
      case 'male':
        return theme.primary[600]!;
      case 'female':
        return theme.secondary[600]!;
      default:
        return theme.grey[600]!;
    }
  }
}
