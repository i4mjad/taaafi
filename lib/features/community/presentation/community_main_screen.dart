import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/premium_cta_button.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/presentation/forum/new_post_screen.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/threads_post_card.dart';
import 'package:reboot_app_3/features/community/presentation/providers/forum_providers.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/avatar_with_anonymity.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/community/data/models/post_category.dart';
import 'package:reboot_app_3/features/account/presentation/widgets/feature_access_guard.dart';
import 'package:reboot_app_3/features/authentication/application/user_subscription_sync_service.dart';
import 'package:reboot_app_3/features/community/presentation/community_onboarding_screen.dart';
import 'package:reboot_app_3/features/plus/data/notifiers/subscription_notifier.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityMainScreen extends ConsumerStatefulWidget {
  /// Optional initial tab to select when the screen opens
  final String? initialTab;

  const CommunityMainScreen({super.key, this.initialTab});

  @override
  ConsumerState<CommunityMainScreen> createState() =>
      _CommunityMainScreenState();
}

class _CommunityMainScreenState extends ConsumerState<CommunityMainScreen>
    with WidgetsBindingObserver {
  late String _selectedFilter;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Set initial filter based on widget parameter or default to 'posts'
    _selectedFilter = widget.initialTab ?? 'posts';

    // Add observer to detect when app comes to foreground
    WidgetsBinding.instance.addObserver(this);

    // Initialize community data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshCommunityStatus();
      _initializeMainScreen();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh community status when app comes back to foreground
      _refreshCommunityStatus();
    }
  }

  /// Refreshes community status and providers
  void _refreshCommunityStatus() {
    // Invalidate current profile to force fresh data
    ref.invalidate(currentCommunityProfileProvider);
  }

  /// Public method to force refresh the community status (can be called externally)
  void forceRefresh() {
    _refreshCommunityStatus();
  }

  /// Initialize main screen data
  void _initializeMainScreen() {
    // Sync community profile with latest subscription status
    _syncCommunityProfile();

    // Check current user and profile status
    _checkUserStatus();

    // Load different types of posts based on initial filter
    if (_selectedFilter == 'pinned') {
      ref
          .read(pinnedPostsPaginationProvider.notifier)
          .loadPosts(isPinned: true);
    } else if (_selectedFilter == 'news') {
      ref
          .read(newsPostsPaginationProvider.notifier)
          .loadPosts(category: 'aqOhcyOg1z8tcij0y1S4');
    } else {
      ref
          .read(postsPaginationProvider.notifier)
          .loadPosts(category: _getFilterCategory());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  /// Sync community profile with latest subscription status
  Future<void> _syncCommunityProfile() async {
    try {
      final syncService = ref.read(userSubscriptionSyncServiceProvider);
      if (await syncService.needsSync()) {
        await syncService.forceManualSync();
      }
    } catch (e) {
      // Don't block UI if sync fails
    }
  }

  /// Check user authentication and profile status for debugging
  Future<void> _checkUserStatus() async {
    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;

      if (user != null) {
        final profileAsync = ref.read(currentCommunityProfileProvider);
        profileAsync.when(
          data: (profile) {},
          loading: () {},
          error: (error, stack) {},
        );
      }
    } catch (e) {
      print('🎯 UserStatus: Error checking user status: $e');
    }
  }

  String? _getFilterCategory() {
    switch (_selectedFilter) {
      case 'posts':
        return null; // Show all posts
      case 'news':
        return 'news';
      case 'pinned':
        return 'pinned';
      case 'categories':
        return null; // This will be handled differently
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final communityProfileAsync = ref.watch(currentCommunityProfileProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: communityProfileAsync.when(
        loading: () => const Center(child: Spinner()),
        error: (error, stackTrace) {
          print('❌ Community Main Screen: Profile error: $error');
          print("stackTrace: $stackTrace");
          return const Center(child: Text('Error loading profile'));
        },
        data: (profile) {
          // Simple logic: if user has active profile, show main content; otherwise show onboarding
          if (profile != null && !profile.isDeleted) {
            return _buildMainCommunityContent();
          } else {
            return const CommunityOnboardingScreen();
          }
        },
      ),
    );
  }

  Widget _buildMainCommunityContent() {
    final theme = AppTheme.of(context);

    return Scaffold(
      appBar: appBar(
        context,
        ref,
        'community',
        false,
        false,
        actions: [
          PremiumCtaAppBarIcon(),
          Consumer(
            builder: (context, ref, child) {
              final communityProfileAsync =
                  ref.watch(currentCommunityProfileProvider);
              final isPlusUser = ref.watch(hasActiveSubscriptionProvider);

              return communityProfileAsync.when(
                data: (profile) {
                  if (profile != null) {
                    return GestureDetector(
                      onTap: () => context.push('/community/profile'),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16.0),
                        child: AvatarWithAnonymity(
                          isDeleted: profile.isDeleted,
                          cpId: profile.id,
                          isAnonymous: profile.isAnonymous,
                          isPlusUser: isPlusUser,
                          avatarUrl: profile.avatarUrl,
                          size: 32,
                        ),
                      ),
                    );
                  } else {
                    // Fallback to icon when no profile exists
                    return IconButton(
                      icon: const Icon(LucideIcons.user),
                      onPressed: () {
                        context.push('/community/profile');
                      },
                    );
                  }
                },
                loading: () => Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.grey[300],
                    ),
                    child: Icon(
                      LucideIcons.user,
                      size: 20,
                      color: theme.grey[600],
                    ),
                  ),
                ),
                error: (error, stackTrace) => IconButton(
                  icon: const Icon(LucideIcons.user),
                  onPressed: () {
                    context.push('/community/profile');
                  },
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: theme.backgroundColor,
      body: _buildForumTab(),
      floatingActionButton: CommunityPostGuard(
        onAccessGranted: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (context) => NewPostScreen(),
          );
        },
        child: FloatingActionButton(
          onPressed: null, // Handled by CommunityPostGuard
          backgroundColor: theme.primary[500],
          child: const Icon(LucideIcons.plus, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildForumTab() {
    // Disable refresh for challenges and categories tabs
    final shouldEnableRefresh =
        !['challenges', 'categories'].contains(_selectedFilter);

    Widget scrollView = CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Filter chips - sticky
        SliverPersistentHeader(
          pinned: true,
          delegate: _FilterChipsDelegate(
            filterChips: Container(
              height: 35,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip(
                    AppLocalizations.of(context).translate('community_pinned'),
                    'pinned',
                    LucideIcons.pin,
                    const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    AppLocalizations.of(context).translate('community_news'),
                    'news',
                    LucideIcons.newspaper,
                    const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    AppLocalizations.of(context).translate('community_posts'),
                    'posts',
                    LucideIcons.messageSquare,
                    const Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    AppLocalizations.of(context).translate('challenges'),
                    'challenges',
                    LucideIcons.star,
                    const Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    AppLocalizations.of(context)
                        .translate('community_categories'),
                    'categories',
                    LucideIcons.layoutGrid,
                    const Color(0xFF8B5CF6),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Scrollable Content
        SliverToBoxAdapter(
          child: _buildMainContent(),
        ),
      ],
    );

    // Conditionally wrap with RefreshIndicator
    if (shouldEnableRefresh) {
      return RefreshIndicator(
        onRefresh: () async {
          // Refresh based on selected filter
          switch (_selectedFilter) {
            case 'posts':
              await ref.read(postsPaginationProvider.notifier).refresh();
              break;
            case 'pinned':
              // Fix: Call refresh method instead of just invalidating
              await ref
                  .read(pinnedPostsPaginationProvider.notifier)
                  .refresh(isPinned: true);
              break;
            case 'news':
              // Fix: Call refresh method instead of just invalidating
              await ref
                  .read(newsPostsPaginationProvider.notifier)
                  .refresh(category: 'aqOhcyOg1z8tcij0y1S4');
              break;
            default:
              await ref.read(postsPaginationProvider.notifier).refresh();
          }
        },
        child: scrollView,
      );
    } else {
      return scrollView;
    }
  }

  Widget _buildMainContent() {
    switch (_selectedFilter) {
      case 'pinned':
        return _buildPinnedView();
      case 'posts':
        return _buildPostsView();
      case 'challenges':
        return _buildChallengesView();
      case 'news':
        return _buildNewsView();
      case 'categories':
        return _buildCategoriesView();
      default:
        return _buildPostsView();
    }
  }

  Widget _buildPinnedView() {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final postsState = ref.watch(pinnedPostsPaginationProvider);

    return Column(
      children: [
        // Description for pinned section
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            localizations.translate('pinned_section_description'),
            style: TextStyles.body.copyWith(
              color: theme.grey[700],
              height: 1.4,
            ),
          ),
        ),
        _buildPinnedPostsContent(postsState, localizations, theme),
      ],
    );
  }

  Widget _buildPostsView() {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    // Use the pagination provider instead of stream for better performance
    final postsState = ref.watch(postsPaginationProvider);

    return Column(
      children: [
        // Header with trend icon, "Latest Posts" text, count, and "See All" button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                LucideIcons.trendingUp,
                color: theme.primary[500],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                localizations.translate('latest_posts'),
                style: TextStyles.caption.copyWith(
                  color: theme.grey[900],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${localizations.translate('latest_50')})',
                style: TextStyles.caption.copyWith(
                  color: theme.grey[600],
                  fontWeight: FontWeight.normal,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  // Navigate to the full posts list screen
                  context.goNamed(RouteNames.allPosts.name);
                },
                child: Text(
                  localizations.translate('see_all'),
                  style: TextStyles.caption.copyWith(
                    color: theme.primary[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildPaginatedPostsContent(postsState, localizations, theme),
      ],
    );
  }

  Widget _buildChallengesView() {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description for challenges section
          Text(
            localizations.translate('challenges_section_description'),
            style: TextStyles.body.copyWith(
              color: theme.grey[700],
              height: 1.4,
            ),
          ),

          const SizedBox(height: 32),

          // Coming Soon Section
          Container(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Challenge Icon
                Icon(
                  LucideIcons.target,
                  size: 60,
                  color: theme.grey[600],
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  localizations.translate('challenges_coming_soon_title'),
                  style: TextStyles.h4.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.grey[900],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  localizations.translate('challenges_coming_soon_description'),
                  style: TextStyles.body.copyWith(
                    color: theme.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Features List
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildChallengeFeatureItem(
                        icon: LucideIcons.calendar,
                        title: localizations
                            .translate('challenges_feature_daily_goals'),
                        description: localizations
                            .translate('challenges_feature_daily_goals_desc'),
                        theme: theme,
                      ),
                      const SizedBox(height: 12),
                      _buildChallengeFeatureItem(
                        icon: LucideIcons.users,
                        title: localizations
                            .translate('challenges_feature_community'),
                        description: localizations
                            .translate('challenges_feature_community_desc'),
                        theme: theme,
                      ),
                      const SizedBox(height: 12),
                      _buildChallengeFeatureItem(
                        icon: LucideIcons.trophy,
                        title: localizations
                            .translate('challenges_feature_rewards'),
                        description: localizations
                            .translate('challenges_feature_rewards_desc'),
                        theme: theme,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Footer note
                Text(
                  localizations.translate('challenges_working_hard_message'),
                  style: TextStyles.caption.copyWith(
                    color: theme.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required dynamic theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.error[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: theme.error[600],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.grey[900],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyles.caption.copyWith(
                  color: theme.grey[600],
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNewsView() {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final postsState = ref.watch(newsPostsPaginationProvider);

    return Column(
      children: [
        // Description for news section
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            localizations.translate('news_section_description'),
            style: TextStyles.body.copyWith(
              color: theme.grey[700],
              height: 1.4,
            ),
          ),
        ),
        _buildNewsPostsContent(postsState, localizations, theme),
      ],
    );
  }

  Widget _buildCategoriesView() {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(postCategoriesProvider);

    return Column(
      children: [
        // Description for categories section
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            localizations.translate('categories_section_description'),
            style: TextStyles.body.copyWith(
              color: theme.grey[700],
              height: 1.4,
            ),
          ),
        ),
        // Categories content
        categoriesAsync.when(
          data: (categories) {
            // Filter out any categories with missing required data
            final validCategories = categories.where((category) {
              return category.id.isNotEmpty &&
                  category.name.isNotEmpty &&
                  category.isActive;
            }).toList();

            if (validCategories.isEmpty) {
              return Center(
                child: Text(
                  localizations.translate('no_categories_found'),
                  style: TextStyles.body.copyWith(
                    color: theme.grey[600],
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: validCategories.length,
                itemBuilder: (context, index) {
                  final category = validCategories[index];
                  return _buildCategoryCard(category, localizations);
                },
              ),
            );
          },
          loading: () => const Center(
            child: Spinner(),
          ),
          error: (error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  localizations.translate('error_loading_categories'),
                  style: TextStyles.body.copyWith(
                    color: theme.error[500],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.refresh(postCategoriesProvider);
                  },
                  child: Text(localizations.translate('retry')),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
      PostCategory category, AppLocalizations localizations) {
    final theme = AppTheme.of(context);

    // Safe fallbacks for potentially null values
    final categoryColor = category.color;
    final categoryIcon = category.icon;
    final displayName = _getSafeCategoryName(category, localizations);

    return GestureDetector(
      onTap: () {
        // Navigate to category posts screen
        final categoryId = Uri.encodeComponent(category.id);
        final categoryName = Uri.encodeComponent(category.name);
        final categoryNameAr = Uri.encodeComponent(category.nameAr);
        final categoryIcon = Uri.encodeComponent(category.iconName);
        final categoryColor = Uri.encodeComponent(category.colorHex);

        context.pushNamed(
          RouteNames.categoryPosts.name,
          pathParameters: {
            'categoryId': categoryId,
            'categoryName': categoryName,
            'categoryNameAr': categoryNameAr,
            'categoryIcon': categoryIcon,
            'categoryColor': categoryColor,
          },
        );
      },
      child: WidgetsContainer(
        backgroundColor: categoryColor.withValues(alpha: 0.1),
        borderSide: BorderSide(
          color: categoryColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        cornerSmoothing: 0.8,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              categoryIcon,
              size: 28,
              color: categoryColor,
            ),
            const SizedBox(height: 8),
            Text(
              displayName,
              style: TextStyles.body.copyWith(
                color: categoryColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getSafeCategoryName(
      PostCategory category, AppLocalizations localizations) {
    try {
      // Check if locale is Arabic and use nameAr, otherwise use name
      final isArabic = localizations.locale.languageCode == 'ar';

      if (isArabic && category.nameAr.isNotEmpty) {
        return category.nameAr;
      } else if (category.name.isNotEmpty) {
        return category.name;
      } else {
        // Fallback to ID if both names are empty
        return category.id;
      }
    } catch (e) {
      // Ultimate fallback - return category ID
      return category.id.isNotEmpty ? category.id : 'Unknown';
    }
  }

  Widget _buildPaginatedPostsContent(
      dynamic postsState, AppLocalizations localizations, theme) {
    if (postsState.posts.isEmpty && postsState.isLoading) {
      return const Center(
        child: Spinner(),
      );
    }

    if (postsState.posts.isEmpty && postsState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              localizations.translate('error_loading_posts'),
              style: TextStyles.body.copyWith(
                color: theme.error[500],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(postsPaginationProvider.notifier).refresh();
              },
              child: Text(localizations.translate('retry')),
            ),
          ],
        ),
      );
    }

    final posts = postsState.posts;

    if (posts.isEmpty) {
      return Container(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              localizations.translate('no_posts_found'),
              style: TextStyles.body.copyWith(
                color: theme.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Posts list
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return ThreadsPostCard(
              post: post,
              onTap: () {
                context.push('/community/forum/post/${post.id}');
              },
            );
          },
        ),

        // Show All button at the end
        if (posts.length >=
            20) // Show button when there are enough posts to warrant "Show All"
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: ElevatedButton(
              onPressed: () {
                context.goNamed(RouteNames.allPosts.name);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary[500],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    localizations.translate('show_all_posts'),
                    style: TextStyles.body.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    LucideIcons.arrowRight,
                    size: 18,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPinnedPostsContent(
      dynamic postsState, AppLocalizations localizations, theme) {
    if (postsState.posts.isEmpty && postsState.isLoading) {
      return const Center(
        child: Spinner(),
      );
    }

    if (postsState.posts.isEmpty && postsState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              localizations.translate('error_loading_posts'),
              style: TextStyles.body.copyWith(
                color: theme.error[500],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(pinnedPostsPaginationProvider.notifier)
                    .refresh(isPinned: true);
              },
              child: Text(localizations.translate('retry')),
            ),
          ],
        ),
      );
    }

    if (postsState.posts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.pin,
              size: 64,
              color: theme.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              localizations.translate('no_pinned_posts_title'),
              style: TextStyles.h5.copyWith(
                color: theme.grey[700],
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              localizations.translate('no_pinned_posts_message'),
              style: TextStyles.caption.copyWith(
                color: theme.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Show only first 5 posts as preview
    final previewPosts = postsState.posts.take(5).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: previewPosts.length,
      itemBuilder: (context, index) {
        final post = previewPosts[index];
        return ThreadsPostCard(
          post: post,
          onTap: () {
            context.push('/community/forum/post/${post.id}');
          },
        );
      },
    );
  }

  Widget _buildNewsPostsContent(
      dynamic postsState, AppLocalizations localizations, theme) {
    if (postsState.posts.isEmpty && postsState.isLoading) {
      return const Center(
        child: Spinner(),
      );
    }

    if (postsState.posts.isEmpty && postsState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              localizations.translate('error_loading_posts'),
              style: TextStyles.body.copyWith(
                color: theme.error[500],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(newsPostsPaginationProvider.notifier)
                    .refresh(category: 'aqOhcyOg1z8tcij0y1S4');
              },
              child: Text(localizations.translate('retry')),
            ),
          ],
        ),
      );
    }

    if (postsState.posts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.newspaper,
              size: 64,
              color: theme.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              localizations.translate('no_news_posts_title'),
              style: TextStyles.h5.copyWith(
                color: theme.grey[700],
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              localizations.translate('no_news_posts_message'),
              style: TextStyles.caption.copyWith(
                color: theme.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Show only first 5 posts as preview
    final previewPosts = postsState.posts.take(5).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: previewPosts.length,
      itemBuilder: (context, index) {
        final post = previewPosts[index];
        return ThreadsPostCard(
          post: post,
          onTap: () {
            context.push('/community/forum/post/${post.id}');
          },
        );
      },
    );
  }

  Widget _buildFilterChip(
      String label, String filterValue, IconData icon, Color color) {
    final theme = AppTheme.of(context);
    final isSelected = _selectedFilter == filterValue;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filterValue;
        });

        // Load appropriate data based on filter
        switch (filterValue) {
          case 'pinned':
            ref
                .read(pinnedPostsPaginationProvider.notifier)
                .refresh(isPinned: true);
            break;
          case 'news':
            ref
                .read(newsPostsPaginationProvider.notifier)
                .refresh(category: 'aqOhcyOg1z8tcij0y1S4');
            break;
          case 'posts':
            ref.read(postsPaginationProvider.notifier).refresh();
            break;
          case 'challenges':
          case 'categories':
            // No additional loading needed for these tabs
            break;
        }
      },
      child: WidgetsContainer(
        padding: const EdgeInsets.only(left: 8, right: 8, top: 2, bottom: 2),
        backgroundColor: isSelected
            ? color.withValues(alpha: 0.15)
            : color.withValues(alpha: 0.1),
        borderSide: BorderSide(
          color: isSelected ? color : theme.grey[200]!,
          width: isSelected ? 2.0 : 1.0, // Thicker border for selected
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? color : theme.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyles.caption.copyWith(
                fontSize: 12,
                color: isSelected ? color : theme.grey[900],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Delegate for sticky filter chips
class _FilterChipsDelegate extends SliverPersistentHeaderDelegate {
  final Widget filterChips;

  _FilterChipsDelegate({
    required this.filterChips,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = AppTheme.of(context);
    return Container(
      color: theme.backgroundColor,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: filterChips,
    );
  }

  @override
  double get maxExtent => 51; // 35 + 8 + 8 padding

  @override
  double get minExtent => 51;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
