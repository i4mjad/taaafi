import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/community/presentation/providers/forum_providers.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/community_profile_tabs.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/avatar_with_anonymity.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/threads_post_card.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/comment_tile_widget.dart';
import 'package:reboot_app_3/features/community/presentation/profile/edit_community_profile_modal.dart';
import 'package:reboot_app_3/features/community/data/models/post.dart';
import 'package:reboot_app_3/features/community/data/models/comment.dart';

class CommunityProfileSettingsScreen extends ConsumerStatefulWidget {
  const CommunityProfileSettingsScreen({super.key});

  @override
  ConsumerState<CommunityProfileSettingsScreen> createState() =>
      _CommunityProfileSettingsScreenState();
}

class _CommunityProfileSettingsScreenState
    extends ConsumerState<CommunityProfileSettingsScreen> {
  int selectedTabIndex = 0;
  late ScrollController _postsScrollController;
  late ScrollController _commentsScrollController;
  late ScrollController _likesScrollController;

  @override
  void initState() {
    super.initState();
    _postsScrollController = ScrollController();
    _commentsScrollController = ScrollController();
    _likesScrollController = ScrollController();

    // Add scroll listeners for pagination
    _postsScrollController.addListener(_onPostsScroll);
    _commentsScrollController.addListener(_onCommentsScroll);
    _likesScrollController.addListener(_onLikesScroll);

    // Load initial data after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _postsScrollController.dispose();
    _commentsScrollController.dispose();
    _likesScrollController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    final profileAsync = ref.read(currentCommunityProfileProvider);
    profileAsync.whenData((profile) {
      if (profile != null) {
        final userCPId = profile.id;
        ref.read(userPostsPaginationProvider(userCPId).notifier).loadPosts();
        ref
            .read(userCommentsPaginationProvider(userCPId).notifier)
            .loadComments();
        ref
            .read(userLikedPostsPaginationProvider(userCPId).notifier)
            .loadLikedItems();
      }
    });
  }

  void _onPostsScroll() {
    if (_postsScrollController.position.pixels >=
        _postsScrollController.position.maxScrollExtent * 0.8) {
      final profileAsync = ref.read(currentCommunityProfileProvider);
      profileAsync.whenData((profile) {
        if (profile != null) {
          ref
              .read(userPostsPaginationProvider(profile.id).notifier)
              .loadMorePosts();
        }
      });
    }
  }

  void _onCommentsScroll() {
    if (_commentsScrollController.position.pixels >=
        _commentsScrollController.position.maxScrollExtent * 0.8) {
      final profileAsync = ref.read(currentCommunityProfileProvider);
      profileAsync.whenData((profile) {
        if (profile != null) {
          ref
              .read(userCommentsPaginationProvider(profile.id).notifier)
              .loadMoreComments();
        }
      });
    }
  }

  void _onLikesScroll() {
    if (_likesScrollController.position.pixels >=
        _likesScrollController.position.maxScrollExtent * 0.8) {
      final profileAsync = ref.read(currentCommunityProfileProvider);
      profileAsync.whenData((profile) {
        if (profile != null) {
          ref
              .read(userLikedPostsPaginationProvider(profile.id).notifier)
              .loadMoreLikedItems();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final profileAsyncValue = ref.watch(currentCommunityProfileProvider);

    return Scaffold(
      appBar: appBar(context, ref, "community-profile-settings", false, true),
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
                          isAnonymous: profile.isAnonymous,
                          size: 80,
                          avatarUrl: profile.avatarUrl,
                        ),
                        const SizedBox(width: 16),
                        // Profile Stats
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.isAnonymous
                                    ? localizations
                                        .translate('community-anonymous')
                                    : profile.displayName,
                                style: TextStyles.h5.copyWith(
                                  color: theme.grey[900],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
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
                              style: TextStyles.caption.copyWith(
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
        loading: () => const Center(child: Spinner()),
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
    final profileAsync = ref.watch(currentCommunityProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

        final postsState = ref.watch(userPostsPaginationProvider(profile.id));

        if (postsState.posts.isEmpty && !postsState.isLoading) {
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

        return RefreshIndicator(
          onRefresh: () async {
            ref
                .read(userPostsPaginationProvider(profile.id).notifier)
                .refresh();
          },
          child: ListView.builder(
            controller: _postsScrollController,
            itemCount: postsState.posts.length + (postsState.isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == postsState.posts.length) {
                // Loading indicator
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final post = postsState.posts[index];
              return ThreadsPostCard(
                post: post,
                onTap: () {
                  // Navigate to post details if needed
                },
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.alertCircle,
              size: 48,
              color: theme.error[500],
            ),
            const SizedBox(height: 16),
            Text(
              localizations.translate('community-profile-error'),
              style: TextStyles.body.copyWith(color: theme.error[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsTab(theme, localizations) {
    final profileAsync = ref.watch(currentCommunityProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

        final commentsState =
            ref.watch(userCommentsPaginationProvider(profile.id));

        if (commentsState.comments.isEmpty && !commentsState.isLoading) {
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

        return RefreshIndicator(
          onRefresh: () async {
            ref
                .read(userCommentsPaginationProvider(profile.id).notifier)
                .refresh();
          },
          child: ListView.builder(
            controller: _commentsScrollController,
            itemCount: commentsState.comments.length +
                (commentsState.isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == commentsState.comments.length) {
                // Loading indicator
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final comment = commentsState.comments[index];
              return CommentTileWidget(
                comment: comment,
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.alertCircle,
              size: 48,
              color: theme.error[500],
            ),
            const SizedBox(height: 16),
            Text(
              localizations.translate('community-profile-error'),
              style: TextStyles.body.copyWith(color: theme.error[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLikesTab(theme, localizations) {
    final profileAsync = ref.watch(currentCommunityProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

        final likedPostsState =
            ref.watch(userLikedPostsPaginationProvider(profile.id));
        final likedCommentsState =
            ref.watch(userLikedCommentsPaginationProvider(profile.id));

        final totalItems =
            likedPostsState.items.length + likedCommentsState.items.length;
        final isLoading =
            likedPostsState.isLoading || likedCommentsState.isLoading;

        if (totalItems == 0 && !isLoading) {
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

        // Combine liked posts and comments, sort by creation date
        final allLikedItems = <dynamic>[];
        allLikedItems.addAll(likedPostsState.items);
        allLikedItems.addAll(likedCommentsState.items);

        // Sort by createdAt in descending order
        allLikedItems.sort((a, b) {
          final aDate = a is Post ? a.createdAt : (a as Comment).createdAt;
          final bDate = b is Post ? b.createdAt : (b as Comment).createdAt;
          return bDate.compareTo(aDate);
        });

        return RefreshIndicator(
          onRefresh: () async {
            ref
                .read(userLikedPostsPaginationProvider(profile.id).notifier)
                .refresh();
            ref
                .read(userLikedCommentsPaginationProvider(profile.id).notifier)
                .refresh();
          },
          child: ListView.builder(
            controller: _likesScrollController,
            itemCount: allLikedItems.length + (isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == allLikedItems.length) {
                // Loading indicator
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final item = allLikedItems[index];
              if (item is Post) {
                return ThreadsPostCard(
                  post: item,
                  onTap: () {
                    // Navigate to post details if needed
                  },
                );
              } else if (item is Comment) {
                return CommentTileWidget(
                  comment: item,
                );
              }

              return const SizedBox.shrink();
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.alertCircle,
              size: 48,
              color: theme.error[500],
            ),
            const SizedBox(height: 16),
            Text(
              localizations.translate('community-profile-error'),
              style: TextStyles.body.copyWith(color: theme.error[500]),
            ),
          ],
        ),
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
