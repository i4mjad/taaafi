import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/features/groups/providers/groups_status_provider.dart';
import 'package:reboot_app_3/features/authentication/providers/account_status_provider.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';
import 'package:reboot_app_3/core/shared_widgets/account_action_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/complete_registration_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/confirm_details_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/confirm_email_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/features/community/presentation/community_profile_setup_modal.dart';
import 'package:reboot_app_3/features/groups/presentation/screens/modals/join_group_modal.dart';
import 'package:reboot_app_3/features/groups/presentation/screens/modals/create_group_modal.dart';
import 'package:reboot_app_3/features/groups/presentation/screens/modals/group_invitations_modal.dart';
import 'package:reboot_app_3/features/shared/models/group_invitation_entity.dart';
import 'package:reboot_app_3/features/groups/presentation/screens/group_screen.dart';
import 'package:reboot_app_3/features/groups/presentation/widgets/join_cooldown_timer.dart';

class GroupsMainScreen extends ConsumerWidget {
  const GroupsMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final accountStatus = ref.watch(accountStatusProvider);
    final userDocAsync = ref.watch(userDocumentsNotifierProvider);
    final groupsStatusAsync = ref.watch(groupsStatusProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: userDocAsync.when(
        loading: () => const Center(child: Spinner()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (_) {
          switch (accountStatus) {
            case AccountStatus.loading:
              return const Center(child: Spinner());
            case AccountStatus.needCompleteRegistration:
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: CompleteRegistrationBanner(isFullScreen: true),
                ),
              );
            case AccountStatus.needConfirmDetails:
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: ConfirmDetailsBanner(isFullScreen: true),
                ),
              );
            case AccountStatus.needEmailVerification:
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: ConfirmEmailBanner(isFullScreen: true),
                ),
              );
            case AccountStatus.pendingDeletion:
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: AccountActionBanner(isFullScreen: true),
                ),
              );
            case AccountStatus.ok:
              return groupsStatusAsync.when(
                data: (groupsStatus) => _buildGroupsContent(
                    context, ref, theme, l10n, groupsStatus),
                loading: () => const Center(child: Spinner()),
                error: (err, _) => Center(child: Text(err.toString())),
              );
          }
        },
      ),
    );
  }

  Widget _buildGroupsContent(BuildContext context, WidgetRef ref,
      CustomThemeData theme, AppLocalizations l10n, GroupsStatus groupsStatus) {
    switch (groupsStatus) {
      case GroupsStatus.loading:
        return const Center(child: Spinner());

      case GroupsStatus.needsCommunityProfile:
        return _buildNeedsCommunityProfileScreen(context, ref, theme, l10n);

      case GroupsStatus.cooldownActive:
        return _buildCooldownActiveScreen(context, ref, theme, l10n);

      case GroupsStatus.alreadyInGroup:
        return const GroupScreen();

      case GroupsStatus.hasInvitations:
        return _buildHasInvitationsScreen(context, ref, theme, l10n);

      case GroupsStatus.canJoinGroup:
      case GroupsStatus.canCreateGroup:
        return _buildGroupsIntroScreen(context, ref, theme, l10n);
    }
  }

  Widget _buildGroupsIntroScreen(BuildContext context, WidgetRef ref,
      CustomThemeData theme, AppLocalizations l10n) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Main illustration
              Center(
                child: SvgPicture.asset(
                  'asset/illustrations/groups-main-illustration.svg',
                  height: 200,
                ),
              ),

              const SizedBox(height: 40),

              // Main title
              Text(
                l10n.translate('groups-main-title'),
                style: TextStyles.h2.copyWith(
                  color: theme.grey[900],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Feature items
              _buildFeatureItem(
                context,
                theme,
                l10n.translate('groups-main-feature-1-title'),
                l10n.translate('groups-main-feature-1-desc'),
                LucideIcons.users,
              ),

              const SizedBox(height: 24),

              _buildFeatureItem(
                context,
                theme,
                l10n.translate('groups-main-feature-2-title'),
                l10n.translate('groups-main-feature-2-desc'),
                LucideIcons.shield,
              ),

              const SizedBox(height: 24),

              _buildFeatureItem(
                context,
                theme,
                l10n.translate('groups-main-feature-3-title'),
                l10n.translate('groups-main-feature-3-desc'),
                LucideIcons.trophy,
              ),

              const SizedBox(height: 24),

              _buildFeatureItem(
                context,
                theme,
                l10n.translate('groups-main-feature-4-title'),
                l10n.translate('groups-main-feature-4-desc'),
                LucideIcons.layers,
              ),

              const SizedBox(height: 48),

              // Action buttons for joining/creating groups
              _buildJoinAndCreateButtons(context, ref, theme, l10n),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNeedsCommunityProfileScreen(BuildContext context, WidgetRef ref,
      CustomThemeData theme, AppLocalizations l10n) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Main illustration
              Center(
                child: SvgPicture.asset(
                  'asset/illustrations/groups-main-illustration.svg',
                  height: 200,
                ),
              ),

              const SizedBox(height: 40),

              // Main title
              Text(
                l10n.translate('groups-main-title'),
                style: TextStyles.h2.copyWith(
                  color: theme.grey[900],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Need profile message
              Text(
                l10n.translate('groups-need-profile-message'),
                style: TextStyles.body.copyWith(
                  color: theme.grey[700],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Setup Profile button
              _buildNeedsCommunityProfileButton(context, ref, theme, l10n),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHasInvitationsScreen(BuildContext context, WidgetRef ref,
      CustomThemeData theme, AppLocalizations l10n) {
    // Demo invitations - in real implementation, this would come from a provider
    final invitations = _getDemoInvitations();

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Main illustration
              Center(
                child: SvgPicture.asset(
                  'asset/illustrations/groups-main-illustration.svg',
                  height: 200,
                ),
              ),

              const SizedBox(height: 40),

              // Main title
              Text(
                l10n.translate('groups-main-title'),
                style: TextStyles.h2.copyWith(
                  color: theme.grey[900],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Invitations message
              Text(
                l10n.translate('you-have-invitations').replaceAll(
                      '{count}',
                      invitations.length.toString(),
                    ),
                style: TextStyles.body.copyWith(
                  color: theme.grey[700],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Quick preview of first invitation
              if (invitations.isNotEmpty) ...[
                WidgetsContainer(
                  backgroundColor: theme.primary[50],
                  borderSide: BorderSide(
                    color: theme.primary[200]!,
                    width: 1,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.primary[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          LucideIcons.mail,
                          size: 20,
                          color: theme.primary[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invitations.first.groupName,
                              style: TextStyles.body.copyWith(
                                color: theme.primary[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.translate('invited-by').replaceAll(
                                    '{inviter}',
                                    invitations.first.inviterName,
                                  ),
                              style: TextStyles.caption.copyWith(
                                color: theme.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (invitations.length > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.primary[600],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '+${invitations.length - 1}',
                            style: TextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // View Invitations button
              GestureDetector(
                onTap: () => _showInvitationsModal(context, invitations),
                child: WidgetsContainer(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  backgroundColor: theme.primary[600],
                  borderRadius: BorderRadius.circular(10.5),
                  borderSide: BorderSide.none,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.mail,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.translate('view-invitations'),
                        style: TextStyles.footnote.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Join Other Group button
              GestureDetector(
                onTap: () => _showJoinGroupModal(context, ref),
                child: WidgetsContainer(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  backgroundColor: theme.primary[100],
                  borderRadius: BorderRadius.circular(10.5),
                  borderSide: BorderSide(
                    color: theme.primary[200]!,
                    width: 1,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.translate('join-other-group'),
                        style: TextStyles.footnote.copyWith(
                          color: theme.primary[900],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNeedsCommunityProfileButton(BuildContext context, WidgetRef ref,
      CustomThemeData theme, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => _showProfileSetupModal(context, ref),
      child: WidgetsContainer(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        backgroundColor: theme.primary[600],
        borderRadius: BorderRadius.circular(10.5),
        borderSide: BorderSide.none,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.userPlus,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.translate('groups-setup-button'),
              style: TextStyles.footnote.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinAndCreateButtons(BuildContext context, WidgetRef ref,
      CustomThemeData theme, AppLocalizations l10n) {
    return Column(
      children: [
        // Join Group button
        GestureDetector(
          onTap: () => _showJoinGroupModal(context, ref),
          child: WidgetsContainer(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            backgroundColor: theme.primary[600],
            borderRadius: BorderRadius.circular(10.5),
            borderSide: BorderSide.none,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.translate('groups-main-join-button'),
                  style: TextStyles.footnote.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Create Group button
        GestureDetector(
          onTap: () => _showCreateGroupModal(context, ref),
          child: WidgetsContainer(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            backgroundColor: theme.primary[100],
            borderRadius: BorderRadius.circular(10.5),
            borderSide: BorderSide(
              color: theme.primary[200]!,
              width: 1,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.translate('groups-main-create-button'),
                  style: TextStyles.footnote.copyWith(
                    color: theme.primary[900],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(BuildContext context, CustomThemeData theme,
      String title, String description, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.primary[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: theme.primary[600],
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyles.h5.copyWith(
                  color: theme.primary[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyles.footnote.copyWith(
                  color: theme.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showProfileSetupModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CommunityProfileSetupModal(),
    );
  }

  void _showJoinGroupModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const JoinGroupModal(),
    );
  }

  void _showCreateGroupModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateGroupModal(),
    );
  }

  void _showInvitationsModal(
      BuildContext context, List<GroupInvitationEntity> invitations) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GroupInvitationsModal(invitations: invitations),
    );
  }

  Widget _buildCooldownActiveScreen(BuildContext context, WidgetRef ref,
      CustomThemeData theme, AppLocalizations l10n) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // Main illustration
              Center(
                child: SvgPicture.asset(
                  'asset/illustrations/groups-main-illustration.svg',
                  height: 200,
                ),
              ),

              const SizedBox(height: 40),

              // Main title
              Text(
                l10n.translate('groups-cooldown-title'),
                style: TextStyles.h3.copyWith(
                  color: theme.grey[900],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Cooldown message
              Text(
                l10n.translate('groups-cooldown-message'),
                style: TextStyles.body.copyWith(
                  color: theme.grey[700],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Countdown Timer
              const JoinCooldownTimer(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  List<GroupInvitationEntity> _getDemoInvitations() {
    // Demo data - in real implementation, this would come from a provider
    return [
      GroupInvitationEntity(
        id: '1',
        groupId: 'group1',
        groupName: 'Recovery Support Circle',
        inviterName: 'أحمد محمد',
        invitedAt: DateTime.now().subtract(const Duration(hours: 2)),
        groupDescription: 'A supportive community for people in recovery',
        memberCount: 12,
        groupType: 'private',
      ),
      GroupInvitationEntity(
        id: '2',
        groupId: 'group2',
        groupName: 'Daily Motivation Group',
        inviterName: 'سارة علي',
        invitedAt: DateTime.now().subtract(const Duration(days: 1)),
        groupDescription: 'Share daily motivation and support each other',
        memberCount: 25,
        groupType: 'public',
      ),
      GroupInvitationEntity(
        id: '3',
        groupId: 'group3',
        groupName: 'Weekend Warriors',
        inviterName: 'محمد حسن',
        invitedAt: DateTime.now().subtract(const Duration(days: 3)),
        memberCount: 8,
        groupType: 'private',
      ),
    ];
  }
}
