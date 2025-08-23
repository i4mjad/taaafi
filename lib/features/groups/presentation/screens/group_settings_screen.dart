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
import 'package:reboot_app_3/features/groups/presentation/widgets/leave_group_modal.dart';
import 'package:reboot_app_3/features/groups/presentation/widgets/group_details_widget.dart';
import 'package:reboot_app_3/features/groups/presentation/widgets/group_members_list.dart';

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
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  verticalSpace(Spacing.points16),

                  // Group Details Card
                  const GroupDetailsWidget(),

                  verticalSpace(Spacing.points16),

                  // Settings actions row
                  Row(
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

                  verticalSpace(Spacing.points24),

                  // Group Members List
                  const GroupMembersList(),

                  verticalSpace(Spacing.points24),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
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
}
