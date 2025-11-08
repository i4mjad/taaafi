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
import 'package:reboot_app_3/features/groups/presentation/screens/group_activity_insights_screen.dart';
import 'package:reboot_app_3/features/groups/presentation/widgets/leave_group_modal.dart';
import 'package:reboot_app_3/features/groups/presentation/widgets/group_overview_card.dart';
import 'package:reboot_app_3/features/groups/presentation/widgets/group_members_list.dart';
import 'package:reboot_app_3/features/groups/presentation/widgets/edit_member_profile_modal.dart';
import 'package:reboot_app_3/features/groups/providers/group_membership_provider.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';

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

              // My Group Profile Card (Sprint 4 - Feature 4.1)
              _buildMyProfileCard(context, theme, l10n, ref),

              verticalSpace(Spacing.points16),

              // Settings actions row
              _buildActionsRow(context, theme, l10n, ref),

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

  Widget _buildActionsRow(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations l10n,
    WidgetRef ref,
  ) {
    final groupMembershipAsync = ref.watch(groupMembershipNotifierProvider);

    return groupMembershipAsync.when(
      data: (groupMembership) {
        final isAdmin = groupMembership?.memberRole == 'admin';

        // Build list of all action buttons
        final actions = <Widget>[];

        // Activity Insights (Admin only - Sprint 2)
        if (isAdmin) {
          actions.add(
            _buildActionCard(
              context: context,
              theme: theme,
              l10n: l10n,
              icon: LucideIcons.barChart2,
              title: l10n.translate('activity'),
              onTap: () => _navigateToActivityInsights(
                  context, groupMembership!.group.id),
            ),
          );
        }

        // Notifications
        actions.add(
          _buildActionCard(
            context: context,
            theme: theme,
            l10n: l10n,
            icon: LucideIcons.bell,
            title: l10n.translate('notifications'),
            onTap: () => _navigateToNotificationSettings(context),
          ),
        );

        // Privacy
        actions.add(
          _buildActionCard(
            context: context,
            theme: theme,
            l10n: l10n,
            icon: LucideIcons.shield,
            title: l10n.translate('privacy'),
            onTap: () => _navigateToPrivacySettings(context),
          ),
        );

        // Leave
        actions.add(
          _buildActionCard(
            context: context,
            theme: theme,
            l10n: l10n,
            icon: LucideIcons.logOut,
            title: l10n.translate('leave'),
            onTap: () => _showLeaveGroupDialog(context, l10n),
            isDestructive: true,
          ),
        );

        // Build rows with 2 items each
        final rows = <Widget>[];
        for (int i = 0; i < actions.length; i += 2) {
          final row = Row(
            children: [
              Expanded(child: actions[i]),
              if (i + 1 < actions.length) ...[
                horizontalSpace(Spacing.points8),
                Expanded(child: actions[i + 1]),
              ] else
                const Expanded(child: SizedBox.shrink()),
            ],
          );
          rows.add(row);
          if (i + 2 < actions.length) {
            rows.add(verticalSpace(Spacing.points8));
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: rows,
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        backgroundColor:
            isDestructive ? theme.error[50] : theme.backgroundColor,
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: isDestructive ? theme.error[200]! : theme.grey[100]!,
          width: 0.75,
        ),
        cornerSmoothing: 1,
        child: Row(
          children: [
            // Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDestructive
                    ? theme.error[100]!.withOpacity(0.5)
                    : theme.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isDestructive ? theme.error[600] : theme.grey[700],
              ),
            ),

            horizontalSpace(Spacing.points12),

            // Title
            Expanded(
              child: Text(
                title,
                style: TextStyles.footnote.copyWith(
                  color: isDestructive ? theme.error[700] : theme.grey[900],
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

  void _navigateToPrivacySettings(BuildContext context) {
    // TODO: Add GoRouter route for group privacy settings
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GroupPrivacySettingsScreen(),
      ),
    );
  }

  void _navigateToActivityInsights(BuildContext context, String groupId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GroupActivityInsightsScreen(groupId: groupId),
      ),
    );
  }

  Widget _buildMyProfileCard(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations l10n,
    WidgetRef ref,
  ) {
    final profileAsync = ref.watch(currentCommunityProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

        final hasProfile = profile.hasBio() || profile.hasInterests();

        return GestureDetector(
          onTap: () => _showEditProfileModal(context, profile, ref),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: WidgetsContainer(
              padding: const EdgeInsets.all(16),
              backgroundColor: hasProfile ? theme.success[50] : theme.tint[50],
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: hasProfile ? theme.success[100]! : theme.tint[100]!,
                width: 0.75,
              ),
              cornerSmoothing: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        hasProfile ? LucideIcons.userCheck : LucideIcons.user,
                        size: 20,
                        color:
                            hasProfile ? theme.success[600] : theme.tint[600],
                      ),
                      horizontalSpace(Spacing.points8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.translate('my-group-profile'),
                              style: TextStyles.h6.copyWith(
                                color: theme.grey[900],
                              ),
                            ),
                            verticalSpace(Spacing.points4),
                            Text(
                              hasProfile
                                  ? l10n.translate('profile-completed')
                                  : l10n.translate('add-bio'),
                              style: TextStyles.caption.copyWith(
                                color: hasProfile
                                    ? theme.success[700]
                                    : theme.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? LucideIcons.chevronLeft
                            : LucideIcons.chevronRight,
                        size: 18,
                        color: theme.grey[400],
                      ),
                    ],
                  ),
                  if (profile.hasBio() || profile.hasInterests()) ...[
                    verticalSpace(Spacing.points12),
                    if (profile.hasBio())
                      Text(
                        profile.groupBio!,
                        style: TextStyles.caption.copyWith(
                          color: theme.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (profile.hasInterests()) ...[
                      verticalSpace(Spacing.points8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: profile.interests.take(3).map((interest) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.tint[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              l10n.translate('interest-$interest'),
                              style: TextStyles.tiny.copyWith(
                                color: theme.tint[700],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showEditProfileModal(
      BuildContext context, profile, WidgetRef ref) async {
    print('✏️ [SETTINGS EDIT] Opening edit modal');
    print('✏️ [SETTINGS EDIT] Profile ID: ${profile.id}');
    print('✏️ [SETTINGS EDIT] Current Bio: "${profile.groupBio}"');
    print('✏️ [SETTINGS EDIT] Current Interests: ${profile.interests}');

    // Force fresh fetch before editing
    ref.invalidate(currentCommunityProfileProvider);
    final freshProfile = await ref.read(currentCommunityProfileProvider.future);

    if (freshProfile == null) {
      print('❌ [SETTINGS EDIT] Failed to fetch fresh profile');
      return;
    }

    print('✅ [SETTINGS EDIT] Fresh profile fetched!');
    print('✅ [SETTINGS EDIT] Fresh Bio: "${freshProfile.groupBio}"');
    print('✅ [SETTINGS EDIT] Fresh Interests: ${freshProfile.interests}');

    showEditProfileModal(
      context: context,
      profile: freshProfile,
      onSave: (bio, interests) async {
        try {
          final repository = ref.read(communityRepositoryProvider);

          // Update bio
          if (bio != profile.groupBio) {
            await repository.updateGroupBio(profile.id, bio);
          }

          // Update interests
          if (interests.toString() != profile.interests.toString()) {
            await repository.updateInterests(profile.id, interests);
          }

          // Refresh profile
          ref.invalidate(currentCommunityProfileProvider);

          if (context.mounted) {
            getSuccessSnackBar(
              context,
              "group-profile-updated",
            );
          }
        } catch (e) {
          if (context.mounted) {
            getErrorSnackBar(context, 'Failed to update profile');
          }
          rethrow;
        }
      },
    );
  }
}
