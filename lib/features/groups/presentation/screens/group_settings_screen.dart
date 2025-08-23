import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/features/groups/presentation/screens/group_notification_settings_screen.dart';
import 'package:reboot_app_3/features/groups/presentation/screens/group_member_settings_screen.dart';
import 'package:reboot_app_3/features/groups/presentation/screens/group_privacy_settings_screen.dart';
import 'package:reboot_app_3/features/groups/presentation/screens/group_chat_settings_screen.dart';
import 'package:reboot_app_3/features/groups/presentation/widgets/leave_group_modal.dart';
import 'package:reboot_app_3/features/groups/presentation/widgets/group_details_widget.dart';

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
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  verticalSpace(Spacing.points16),

                  // Group Details Card
                  const GroupDetailsWidget(),

                  verticalSpace(Spacing.points24),

                  // Notification Settings
                  _buildSettingsItem(
                    context: context,
                    theme: theme,
                    l10n: l10n,
                    icon: LucideIcons.bell,
                    title: l10n.translate('notification-settings'),
                    onTap: () => _navigateToNotificationSettings(context),
                  ),

                  verticalSpace(Spacing.points8),

                  // Member Settings
                  _buildSettingsItem(
                    context: context,
                    theme: theme,
                    l10n: l10n,
                    icon: LucideIcons.users,
                    title: l10n.translate('member-settings'),
                    onTap: () => _navigateToMemberSettings(context),
                  ),

                  verticalSpace(Spacing.points8),

                  // Privacy Settings
                  _buildSettingsItem(
                    context: context,
                    theme: theme,
                    l10n: l10n,
                    icon: LucideIcons.shield,
                    title: l10n.translate('privacy-settings'),
                    onTap: () => _navigateToPrivacySettings(context),
                  ),

                  verticalSpace(Spacing.points8),

                  // Chat Settings
                  _buildSettingsItem(
                    context: context,
                    theme: theme,
                    l10n: l10n,
                    icon: LucideIcons.messageCircle,
                    title: l10n.translate('chat-settings'),
                    onTap: () => _navigateToChatSettings(context),
                  ),

                  const Spacer(),

                  // Leave Group - Destructive action at bottom
                  _buildDestructiveItem(
                    context: context,
                    theme: theme,
                    l10n: l10n,
                    icon: LucideIcons.logOut,
                    title: l10n.translate('leave-group'),
                    onTap: () => _showLeaveGroupDialog(context, l10n),
                  ),

                  verticalSpace(Spacing.points32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required BuildContext context,
    required CustomThemeData theme,
    required AppLocalizations l10n,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: theme.backgroundColor[500],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.grey[200]!,
            width: 0.75,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: theme.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 16,
                color: theme.grey[600],
              ),
            ),

            horizontalSpace(Spacing.points12),

            // Title
            Expanded(
              child: Text(
                title,
                style: TextStyles.body.copyWith(
                  color: theme.grey[900],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.right,
              ),
            ),

            horizontalSpace(Spacing.points8),

            // Arrow
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestructiveItem({
    required BuildContext context,
    required CustomThemeData theme,
    required AppLocalizations l10n,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: theme.error[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.grey[200]!,
            width: 0.75,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: theme.error[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 16,
                color: theme.error[500],
              ),
            ),

            horizontalSpace(Spacing.points12),

            // Title
            Expanded(
              child: Text(
                title,
                style: TextStyles.body.copyWith(
                  color: theme.error[500],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.right,
              ),
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

  void _navigateToMemberSettings(BuildContext context) {
    // TODO: Add GoRouter route for group member settings
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GroupMemberSettingsScreen(),
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
}
