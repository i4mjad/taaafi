import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/community_profile_tabs.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/avatar_with_anonymity.dart';
import 'package:reboot_app_3/features/community/presentation/profile/edit_community_profile_modal.dart';

class CommunityProfileSettingsScreen extends ConsumerStatefulWidget {
  const CommunityProfileSettingsScreen({super.key});

  @override
  ConsumerState<CommunityProfileSettingsScreen> createState() =>
      _CommunityProfileSettingsScreenState();
}

class _CommunityProfileSettingsScreenState
    extends ConsumerState<CommunityProfileSettingsScreen> {
  int selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final profileAsyncValue = ref.watch(currentCommunityProfileProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        surfaceTintColor: theme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.grey[900]),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.moreHorizontal, color: theme.grey[900]),
            onPressed: () {
              // TODO: Implement more options menu
            },
          ),
        ],
      ),
      backgroundColor: theme.backgroundColor,
      body: profileAsyncValue.when(
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.user,
                    size: 64,
                    color: theme.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations.translate('community-profile-not-found'),
                    style: TextStyles.h6.copyWith(color: theme.grey[600]),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Profile Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Profile Avatar
                        AvatarWithAnonymity(
                          cpId: profile.id,
                          isAnonymous: profile.postAnonymouslyByDefault,
                          size: 80,
                        ),
                        const SizedBox(width: 16),
                        // Profile Stats
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.postAnonymouslyByDefault
                                    ? localizations
                                        .translate('community-anonymous')
                                    : profile.displayName,
                                style: TextStyles.h5.copyWith(
                                  color: theme.grey[900],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getUserDisplayEmail(),
                                style: TextStyles.body.copyWith(
                                  color: theme.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '0 ${localizations.translate('community-followers')}',
                                style: TextStyles.caption.copyWith(
                                  color: theme.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _showEditProfileModal(context, profile);
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: theme.grey[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              localizations.translate('community-edit-profile'),
                              style: TextStyles.body.copyWith(
                                color: theme.grey[900],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              // TODO: Implement share profile functionality
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: theme.grey[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              localizations
                                  .translate('community-share-profile'),
                              style: TextStyles.body.copyWith(
                                color: theme.grey[900],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Tabs
              CommunityProfileTabs(
                onTabChanged: (index) {
                  setState(() {
                    selectedTabIndex = index;
                  });
                },
                initialIndex: selectedTabIndex,
              ),
              // Tab Content
              Expanded(
                child: _buildTabContent(theme, localizations),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.alertCircle,
                size: 64,
                color: theme.error[500],
              ),
              const SizedBox(height: 16),
              Text(
                localizations.translate('community-profile-error'),
                style: TextStyles.h6.copyWith(color: theme.error[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getUserDisplayEmail() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email != null) {
      return user!.email!;
    }
    return 'user@example.com';
  }

  Widget _buildTabContent(theme, localizations) {
    switch (selectedTabIndex) {
      case 0:
        return _buildPostsTab(theme, localizations);
      case 1:
        return _buildCommentsTab(theme, localizations);
      case 2:
        return _buildLikesTab(theme, localizations);
      default:
        return _buildPostsTab(theme, localizations);
    }
  }

  Widget _buildPostsTab(theme, localizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.messageSquare,
            size: 48,
            color: theme.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            localizations.translate('community-no-posts'),
            style: TextStyles.body.copyWith(
              color: theme.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsTab(theme, localizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.messageCircle,
            size: 48,
            color: theme.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            localizations.translate('community-no-comments'),
            style: TextStyles.body.copyWith(
              color: theme.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLikesTab(theme, localizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.heart,
            size: 48,
            color: theme.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            localizations.translate('community-no-likes'),
            style: TextStyles.body.copyWith(
              color: theme.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileModal(BuildContext context, profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditCommunityProfileModal(profile: profile),
    );
  }
}
