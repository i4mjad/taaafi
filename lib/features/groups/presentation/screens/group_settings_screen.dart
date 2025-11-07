import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/features/groups/presentation/screens/group_notification_settings_screen.dart';

import 'package:reboot_app_3/features/groups/presentation/screens/group_privacy_settings_screen.dart';
import 'package:reboot_app_3/features/groups/presentation/screens/group_chat_settings_screen.dart';
import 'package:reboot_app_3/features/groups/presentation/screens/group_capacity_settings_screen.dart';
import 'package:reboot_app_3/features/groups/presentation/screens/edit_group_details_screen.dart';
import 'package:reboot_app_3/features/groups/presentation/widgets/leave_group_modal.dart';
import 'package:reboot_app_3/features/groups/presentation/widgets/group_overview_card.dart';
import 'package:reboot_app_3/features/groups/presentation/widgets/group_members_list.dart';
import 'package:reboot_app_3/features/groups/providers/group_membership_provider.dart';

class GroupSettingsScreen extends ConsumerStatefulWidget {
  const GroupSettingsScreen({super.key});

  @override
  ConsumerState<GroupSettingsScreen> createState() =>
      _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends ConsumerState<GroupSettingsScreen> {
  void _handleLeaveSuccess() {
    print(
        'GroupSettingsScreen: User left group successfully, navigating to groups main');

    // Navigate to groups main screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.goNamed(RouteNames.groups.name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, "group-settings", false, true),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Group Overview Card (combines details and join code)
              const GroupOverviewCard(),

              verticalSpace(Spacing.points16),

              // Settings actions row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    // Notifications
                    Expanded(
                      child: _buildActionCard(
                        context: context,
                        theme: theme,
                        l10n: l10n,
                        icon: LucideIcons.bell,
                        title: l10n.translate('notifications'),
                        onTap: () => _navigateToNotificationSettings(context),
                      ),
                    ),

                    horizontalSpace(Spacing.points8),

                    // Chat
                    Expanded(
                      child: _buildActionCard(
                        context: context,
                        theme: theme,
                        l10n: l10n,
                        icon: LucideIcons.messageCircle,
                        title: l10n.translate('chat'),
                        onTap: () => _navigateToChatSettings(context),
                      ),
                    ),

                    horizontalSpace(Spacing.points8),

                    // Privacy
                    Expanded(
                      child: _buildActionCard(
                        context: context,
                        theme: theme,
                        l10n: l10n,
                        icon: LucideIcons.shield,
                        title: l10n.translate('privacy'),
                        onTap: () => _navigateToPrivacySettings(context),
                      ),
                    ),

                    horizontalSpace(Spacing.points8),

                    // Leave
                    Expanded(
                      child: _buildActionCard(
                        context: context,
                        theme: theme,
                        l10n: l10n,
                        icon: LucideIcons.logOut,
                        title: l10n.translate('leave'),
                        onTap: () => _showLeaveGroupDialog(context, l10n),
                        isDestructive: true,
                      ),
                    ),
                  ],
                ),
              ),

              verticalSpace(Spacing.points24),

              // Admin Settings Section (only for admins)
              _buildAdminSection(context, theme, l10n, ref),

              verticalSpace(Spacing.points24),

              // Group Members List
              const GroupMembersList(),

              verticalSpace(Spacing.points24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminSection(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations l10n,
    WidgetRef ref,
  ) {
    final groupMembershipAsync = ref.watch(groupMembershipNotifierProvider);

    return groupMembershipAsync.when(
      data: (groupMembership) {
        if (groupMembership == null ||
            groupMembership.memberRole != 'admin') {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.translate('admin-settings'),
              style: TextStyles.h5.copyWith(color: theme.grey[900]),
            ),
            verticalSpace(Spacing.points12),
            _buildSettingsCard(
              context: context,
              theme: theme,
              l10n: l10n,
              icon: LucideIcons.users,
              title: l10n.translate('group-capacity'),
              subtitle:
                  '${groupMembership.group.capacity} ${l10n.translate('members')}',
              onTap: () => _navigateToCapacitySettings(context),
            ),
            verticalSpace(Spacing.points8),
            _buildSettingsCard(
              context: context,
              theme: theme,
              l10n: l10n,
              icon: LucideIcons.edit,
              title: l10n.translate('edit-group-details'),
              subtitle: l10n.translate('name-and-description'),
              onTap: () => _navigateToEditDetails(context),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSettingsCard({
    required BuildContext context,
    required CustomThemeData theme,
    required AppLocalizations l10n,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: WidgetsContainer(
        padding: const EdgeInsets.all(16),
        backgroundColor: theme.backgroundColor,
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: theme.grey[100]!, width: 0.75),
        cornerSmoothing: 1,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.primary[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: theme.primary[600],
              ),
            ),
            horizontalSpace(Spacing.points12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyles.body.copyWith(
                      color: theme.grey[900],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  verticalSpace(Spacing.points4),
                  Text(
                    subtitle,
                    style: TextStyles.small.copyWith(
                      color: theme.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: theme.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required CustomThemeData theme,
    required AppLocalizations l10n,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: WidgetsContainer(
        padding: const EdgeInsets.all(12),
        backgroundColor:
            isDestructive ? theme.error[50] : theme.backgroundColor,
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: isDestructive ? theme.error[200]! : theme.grey[100]!,
          width: 0.75,
        ),
        cornerSmoothing: 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isDestructive ? theme.error[600] : theme.grey[700],
              ),
            ),

            verticalSpace(Spacing.points8),

            // Title
            Text(
              title,
              style: TextStyles.small.copyWith(
                color: isDestructive ? theme.error[700] : theme.grey[900],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showLeaveGroupDialog(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.of(context).backgroundColor,
      builder: (context) =>
          LeaveGroupModal(onLeaveSuccess: _handleLeaveSuccess),
    );
  }

  void _navigateToNotificationSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GroupNotificationSettingsScreen(),
      ),
    );
  }

  void _navigateToPrivacySettings(BuildContext context) {
    // TODO: Add GoRouter route for group privacy settings
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GroupPrivacySettingsScreen(),
      ),
    );
  }

  void _navigateToChatSettings(BuildContext context) {
    // TODO: Add GoRouter route for group chat settings
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GroupChatSettingsScreen(),
      ),
    );
  }

  void _navigateToCapacitySettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GroupCapacitySettingsScreen(),
      ),
    );
  }

  void _navigateToEditDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EditGroupDetailsScreen(),
      ),
    );
  }
}
