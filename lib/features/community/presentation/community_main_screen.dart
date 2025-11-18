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
import 'package:reboot_app_3/features/community/data/models/post.dart';
import 'package:reboot_app_3/features/account/presentation/widgets/feature_access_guard.dart';
import 'package:reboot_app_3/features/authentication/application/user_subscription_sync_service.dart';
import 'package:reboot_app_3/features/community/presentation/community_onboarding_screen.dart';
import 'package:reboot_app_3/features/plus/data/notifiers/subscription_notifier.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Shorebird update imports
import 'package:reboot_app_3/features/home/presentation/home/widgets/shorebird_update_widget.dart';
import 'package:reboot_app_3/features/authentication/providers/account_status_provider.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';
import 'package:reboot_app_3/core/shared_widgets/account_action_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/complete_registration_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/confirm_details_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/confirm_email_banner.dart';
import 'package:reboot_app_3/features/direct_messaging/presentation/screens/community_chats_screen.dart';
import 'package:reboot_app_3/features/groups/presentation/screens/groups_main_screen.dart';

class CommunityMainScreen extends ConsumerStatefulWidget {
  /// Optional initial tab to select when the screen opens
  final String? initialTab;

  const CommunityMainScreen({super.key, this.initialTab});

  @override
  ConsumerState<CommunityMainScreen> createState() =>
      _CommunityMainScreenState();
}

class _CommunityMainScreenState extends ConsumerState<CommunityMainScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late String _selectedFilter;
  final ScrollController _scrollController = ScrollController();
  TabController? _tabController;
  bool _pinnedExpanded = true;
  bool _newsExpanded = true;

  @override
  void initState() {
    super.initState();

    // Initialize tab controller with 3 tabs (Community, Chats, and Groups)
    // Dispose any existing controller first (in case of hot reload)
    _tabController?.dispose();
    _tabController = TabController(length: 3, vsync: this);

    // Listen to tab changes to update UI (e.g., floating action button)
    _tabController!.addListener(() {
      setState(() {});
    });

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

    // Always load pinned and news posts for the sections above tabs
      ref
          .read(pinnedPostsPaginationProvider.notifier)
          .loadPosts(isPinned: true);
      ref
          .read(newsPostsPaginationProvider.notifier)
          .loadPosts(category: 'aqOhcyOg1z8tcij0y1S4');

    // Load posts based on initial filter
      ref
          .read(postsPaginationProvider.notifier)
          .loadPosts(category: _getFilterCategory());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _tabController?.dispose();
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
    final accountStatus = ref.watch(accountStatusProvider);
    final userDocAsync = ref.watch(userDocumentsNotifierProvider);
    final shorebirdUpdateState = ref.watch(shorebirdUpdateProvider);
    final communityProfileAsync = ref.watch(currentCommunityProfileProvider);

    // Check if Shorebird update requires blocking the entire screen
    final shouldBlockForShorebird =
        _shouldBlockForShorebirdUpdate(shorebirdUpdateState.status);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: userDocAsync.when(
        loading: () => const Center(child: Spinner()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (_) {
          // Priority 1: Check if Shorebird update requires blocking (highest priority)
          if (shouldBlockForShorebird) {
            return const ShorebirdUpdateBlockingWidget();
          }

          // Priority 2: Check account status
          switch (accountStatus) {
            case AccountStatus.loading:
              return Center(
                child: Spinner(),
              );
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
              // Priority 3: Check community profile status
              return communityProfileAsync.when(
                loading: () => Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: const Center(child: Spinner()),
                ),
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
              );
          }
        },
      ),
    );
  }

  Widget _buildMainCommunityContent() {
    final theme = AppTheme.of(context);
    final shorebirdUpdateState = ref.watch(shorebirdUpdateProvider);
    final shouldBlockForShorebird =
        _shouldBlockForShorebirdUpdate(shorebirdUpdateState.status);

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
                    child: Center(
                      child: Icon(
                        LucideIcons.user,
                        size: 20,
                        color: theme.grey[600],
                      ),
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
      body: Column(
        children: [
          // Tab bar
          TabBar(
            controller: _tabController!,
            indicatorColor: theme.primary[600],
            labelColor: theme.primary[600],
            unselectedLabelColor: theme.grey[600],
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.users,
                      size: 18,
                      color: _tabController!.index == 0
                          ? theme.primary[600]
                          : theme.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context).translate('community'),
                      style: (_tabController!.index == 0
                              ? TextStyles.footnoteSelected
                              : TextStyles.footnote)
                          .copyWith(
                              color: _tabController!.index == 0
                                  ? theme.primary[600]
                                  : theme.grey[600],
                              fontSize: 12),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.messageSquare,
                      size: 18,
                      color: _tabController!.index == 1
                          ? theme.primary[600]
                          : theme.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context).translate('community-chats'),
                      style: (_tabController!.index == 1
                              ? TextStyles.footnoteSelected
                              : TextStyles.footnote)
                          .copyWith(
                              color: _tabController!.index == 1
                                  ? theme.primary[600]
                                  : theme.grey[600],
                              fontSize: 12),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.users2,
                      size: 18,
                      color: _tabController!.index == 2
                          ? theme.primary[600]
                          : theme.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context).translate('group'),
                      style: (_tabController!.index == 2
                              ? TextStyles.footnoteSelected
                              : TextStyles.footnote)
                          .copyWith(
                              color: _tabController!.index == 2
                                  ? theme.primary[600]
                                  : theme.grey[600],
                              fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Tab bar view
          Expanded(
            child: TabBarView(
              controller: _tabController!,
              children: [
                _buildForumTab(),
                const CommunityChatsScreen(showAppBar: false),
                const GroupsMainScreen(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton:
          !shouldBlockForShorebird && _tabController!.index == 0
              ? CommunityPostGuard(
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
                )
              : null,
    );
  }

  Widget _buildForumTab() {
    // Disable refresh for categories tab
    final shouldEnableRefresh = _selectedFilter != 'categories';

    Widget scrollView = CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Pinned Posts Section (above tabs)
        SliverToBoxAdapter(
          child: _buildPinnedSection(),
        ),

        // News Posts Section (above tabs)
        SliverToBoxAdapter(
          child: _buildNewsSection(),
        ),

        // Header row with Latest Posts and actions
        SliverPersistentHeader(
          pinned: true,
          delegate: _FilterChipsDelegate(
            filterChips: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Latest Posts with icon
                  Icon(
                    LucideIcons.trendingUp,
                    size: 16,
                    color: AppTheme.of(context).grey[700],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context).translate('latest_posts'),
                    style: TextStyles.footnoteSelected.copyWith(
                      color: AppTheme.of(context).grey[900],
                    ),
                  ),
                  const Spacer(),
                  // View All
                  GestureDetector(
                    onTap: () {
                      context.goNamed(RouteNames.allPosts.name);
                    },
                    child: Text(
                      AppLocalizations.of(context).translate('see_all'),
                      style: TextStyles.caption.copyWith(
                        color: AppTheme.of(context).primary[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Dot separator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '•',
                      style: TextStyles.caption.copyWith(
                        color: AppTheme.of(context).grey[400],
                      ),
                    ),
                  ),
                  // Categories
                  GestureDetector(
                    onTap: () {
                      context.push('/community/categories');
                    },
                    child: Text(
                      AppLocalizations.of(context).translate('community_categories'),
                      style: TextStyles.caption.copyWith(
                        color: AppTheme.of(context).primary[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
          // Refresh pinned and news sections
              await ref
                  .read(pinnedPostsPaginationProvider.notifier)
                  .refresh(isPinned: true);
              await ref
                  .read(newsPostsPaginationProvider.notifier)
                  .refresh(category: 'aqOhcyOg1z8tcij0y1S4');
          
          // Refresh posts
              await ref.read(postsPaginationProvider.notifier).refresh();
        },
        child: scrollView,
      );
    } else {
      return scrollView;
    }
  }

  Widget _buildMainContent() {
        return _buildPostsView();
  }

  /// Build the pinned posts section that appears above the tabs
  Widget _buildPinnedSection() {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final postsState = ref.watch(pinnedPostsPaginationProvider);
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    // Don't show section if loading initially or if there are no pinned posts
    if (postsState.posts.isEmpty && postsState.isLoading) {
      return const SizedBox.shrink();
    }

    if (postsState.posts.isEmpty) {
      return const SizedBox.shrink();
    }

    final pinnedPosts = postsState.posts.take(6).toList(); // Show max 6 pinned posts

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        // Section header with icon and expand/collapse
        GestureDetector(
          onTap: () {
            setState(() {
              _pinnedExpanded = !_pinnedExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                  LucideIcons.pin,
                  size: 16,
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 6),
              Text(
                  localizations.translate('community_pinned'),
                  style: TextStyles.footnoteSelected.copyWith(
                  color: theme.grey[900],
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _pinnedExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    LucideIcons.chevronDown,
                    size: 16,
                    color: theme.grey[600],
                  ),
                ),
            ],
          ),
        ),
        ),
        if (_pinnedExpanded)
          AnimatedOpacity(
            opacity: _pinnedExpanded ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Column(
              children: [
                const SizedBox(height: 4),
                // Horizontal scrollable cards
                SizedBox(
                  height: 114, // Increased to give shadows space to breathe
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    itemCount: pinnedPosts.length,
                    itemBuilder: (context, index) {
                      final post = pinnedPosts[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          right: isRTL ? 0 : (index < pinnedPosts.length - 1 ? 12 : 0),
                          left: isRTL ? (index < pinnedPosts.length - 1 ? 12 : 0) : 0,
                        ),
                        child: _buildPinnedPostCard(post, theme, localizations),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
      ],
    );
  }

  /// Build a rectangular card for pinned posts
  Widget _buildPinnedPostCard(
      Post post, dynamic theme, AppLocalizations localizations) {
    // Get first 50 characters of body
    final bodyPreview = post.body.length > 50
        ? '${post.body.substring(0, 50)}...'
        : post.body;

    return GestureDetector(
      onTap: () {
        context.goNamed(RouteNames.postDetail.name,
            pathParameters: {'postId': post.id});
      },
      child: WidgetsContainer(
        width: 240,
        height: 80,
        padding: const EdgeInsets.all(10),
        backgroundColor: theme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: Shadows.mainShadows,
        borderSide: BorderSide(
          width: 0.25,
          color: theme.grey[100],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title
            Text(
              post.title,
              style: TextStyles.small.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Body preview
            Text(
              bodyPreview,
              style: TextStyles.bodyTiny.copyWith(
                color: theme.grey[600],
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsView() {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    // Use the pagination provider instead of stream for better performance
    final postsState = ref.watch(postsPaginationProvider);

    return _buildPaginatedPostsContent(postsState, localizations, theme);
  }

  /// Build the news posts section that appears above the tabs
  Widget _buildNewsSection() {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final postsState = ref.watch(newsPostsPaginationProvider);
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    // Don't show section if loading initially or if there are no news posts
    if (postsState.posts.isEmpty && postsState.isLoading) {
      return const SizedBox.shrink();
    }

    if (postsState.posts.isEmpty) {
      return const SizedBox.shrink();
    }

    final newsPosts = postsState.posts.take(6).toList(); // Show max 6 news posts

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        // Section header with icon and expand/collapse
        GestureDetector(
              onTap: () {
            setState(() {
              _newsExpanded = !_newsExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                Icon(
                  LucideIcons.newspaper,
                  size: 16,
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(width: 6),
                  Text(
                  localizations.translate('community_news'),
                  style: TextStyles.footnoteSelected.copyWith(
                    color: theme.grey[900],
                  ),
                ),
                const Spacer(),
                  AnimatedRotation(
                  turns: _newsExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    LucideIcons.chevronDown,
                    size: 16,
                    color: theme.grey[600],
                  ),
                  ),
                ],
              ),
            ),
          ),
        if (_newsExpanded)
          AnimatedOpacity(
            opacity: _newsExpanded ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Column(
              children: [
                const SizedBox(height: 4),
                // Horizontal scrollable cards
                SizedBox(
                  height: 94, // Increased to give shadows space to breathe
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    itemCount: newsPosts.length,
                    itemBuilder: (context, index) {
                      final post = newsPosts[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          right: isRTL ? 0 : (index < newsPosts.length - 1 ? 12 : 0),
                          left: isRTL ? (index < newsPosts.length - 1 ? 12 : 0) : 0,
                        ),
                        child: _buildNewsPostCard(post, theme, localizations),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
      ],
    );
  }

  /// Build a rectangular card for news posts (similar to community cards in home)
  Widget _buildNewsPostCard(
      Post post, dynamic theme, AppLocalizations localizations) {
    // Get first 50 characters of body
    final bodyPreview = post.body.length > 50
        ? '${post.body.substring(0, 50)}...'
        : post.body;

    return GestureDetector(
      onTap: () {
        context.goNamed(RouteNames.postDetail.name,
            pathParameters: {'postId': post.id});
      },
      child: WidgetsContainer(
        width: 240,
        height: 80,
        padding: const EdgeInsets.all(10),
        backgroundColor: theme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: Shadows.mainShadows,
        borderSide: BorderSide(
          width: 0.25,
          color: theme.grey[100],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title
            Text(
              post.title,
              style: TextStyles.small.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Body preview
            Text(
              bodyPreview,
              style: TextStyles.bodyTiny.copyWith(
                color: theme.grey[600],
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        ),
      );
    }


  Widget _buildPaginatedPostsContent(
      dynamic postsState, AppLocalizations localizations, theme) {
    if (postsState.posts.isEmpty && postsState.isLoading) {
      return Container(
        width: double.infinity,
        height: 200,
        child: const Center(
          child: Spinner(),
        ),
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

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        // Safe index access to prevent range errors
        if (index >= posts.length) return Container();

        final post = posts[index];
        return ThreadsPostCard(
          post: post,
          onTap: () {
            context.goNamed(RouteNames.postDetail.name,
                pathParameters: {'postId': post.id});
          },
        );
      },
    );
  }



  /// Determines if Shorebird update status should block the entire screen
  bool _shouldBlockForShorebirdUpdate(AppUpdateStatus status) {
    return status == AppUpdateStatus.available ||
        status == AppUpdateStatus.downloading ||
        status == AppUpdateStatus.completed;
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
      child: filterChips,
    );
  }

  @override
  double get maxExtent => 40;

  @override
  double get minExtent => 40;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
