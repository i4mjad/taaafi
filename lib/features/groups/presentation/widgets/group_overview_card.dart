import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/groups/providers/group_membership_provider.dart';
import 'package:reboot_app_3/features/groups/presentation/widgets/admin_settings_sheet.dart';

class GroupOverviewCard extends ConsumerWidget {
  final bool isInMainScreen;

  const GroupOverviewCard({super.key, this.isInMainScreen = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final groupMembershipAsync = ref.watch(groupMembershipNotifierProvider);

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
                    horizontalSpace(Spacing.points8),
                    _buildStatChip(
                      context: context,
                      theme: theme,
                      icon: LucideIcons.calendar,
                      label: _formatCreatedTime(group.createdAt, l10n),
                      tooltip: _formatCreatedTime(group.createdAt, l10n),
                      isHighlight: false,
                    ),
                  ],
                ),

                if (!isInMainScreen) ...[
                  verticalSpace(Spacing.points12),

                  // Sharing Section

                  ..._buildJoinMethodContent(
                      group.joinMethod, isAdmin, group, theme, l10n, context),
                  // Admin Settings CTA (only for admins)
                  if (isAdmin) ...[
                    verticalSpace(Spacing.points12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showAdminSettingsSheet(context),
                        icon: Icon(
                          LucideIcons.settings,
                          size: 18,
                          color: theme.primary[600],
                        ),
                        label: Text(
                          l10n.translate('admin-settings'),
                          style: TextStyles.footnote.copyWith(
                            color: theme.primary[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          side:
                              BorderSide(color: theme.primary[300]!, width: 1),
                          backgroundColor: theme.primary[50],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAdminSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AdminSettingsSheet(),
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
            // Show join code if available
            if (group.joinCode != null) ...[
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
                      LucideIcons.key,
                      color: theme.primary[600],
                      size: 14,
                    ),
                    horizontalSpace(Spacing.points4),
                    Text(
                      '${l10n.translate('join-code')}: ',
                      style: TextStyles.small.copyWith(
                        color: theme.primary[700],
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      group.joinCode!,
                      style: TextStyles.small.copyWith(
                        color: theme.primary[900],
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () =>
                          _copyToClipboard(group.joinCode!, context, l10n),
                      child: Icon(
                        LucideIcons.copy,
                        color: theme.primary[600],
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                    l10n.translate('open-join-info'),
                    style: TextStyles.small.copyWith(
                      color: theme.primary[700],
                      height: 1.3,
                      fontSize: 11,
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
    getSuccessSnackBar(context, 'join-code-copied');
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

  String _formatCreatedTime(dynamic createdAt, AppLocalizations l10n) {
    DateTime dateTime;
    if (createdAt is DateTime) {
      dateTime = createdAt;
    } else {
      // Handle Firestore Timestamp
      dateTime = createdAt.toDate();
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return l10n
          .translate('group-months-ago')
          .replaceAll('{months}', months.toString());
    } else if (difference.inDays > 0) {
      return l10n
          .translate('group-days-ago')
          .replaceAll('{days}', difference.inDays.toString());
    } else if (difference.inHours > 0) {
      return l10n
          .translate('group-hours-ago')
          .replaceAll('{hours}', difference.inHours.toString());
    } else {
      return l10n.translate('just-created');
    }
  }
}
