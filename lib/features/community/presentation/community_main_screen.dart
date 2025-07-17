import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/threads_post_card.dart';
import 'package:reboot_app_3/features/community/presentation/providers/forum_providers.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/avatar_with_anonymity.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/community/data/models/post_category.dart';

class CommunityMainScreen extends ConsumerStatefulWidget {
  const CommunityMainScreen({super.key});

  @override
  ConsumerState<CommunityMainScreen> createState() =>
      _CommunityMainScreenState();
}

class _CommunityMainScreenState extends ConsumerState<CommunityMainScreen> {
  String _selectedFilter = 'posts';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load posts when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(postsPaginationProvider.notifier)
          .loadPosts(category: _getFilterCategory());
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

    return Scaffold(
      appBar: appBar(
        context,
        ref,
        'community',
        false,
        false,
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final communityProfileAsync =
                  ref.watch(currentCommunityProfileProvider);

              return communityProfileAsync.when(
                data: (profile) {
                  if (profile != null) {
                    return GestureDetector(
                      onTap: () => context.push('/community/profile'),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16.0),
                        child: AvatarWithAnonymity(
                          cpId: profile.id,
                          isAnonymous: profile.isAnonymous,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.pushNamed(RouteNames.newPost.name);
        },
        backgroundColor: theme.primary[500],
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  Widget _buildForumTab() {
    return CustomScrollView(
      controller: _scrollController,
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
                    AppLocalizations.of(context).translate('community_news'),
                    'news',
                    LucideIcons.newspaper,
                    const Color(0xFF10B981),
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
    final postsState = ref.watch(postsPaginationProvider);

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
        _buildPostsContent(postsState, localizations, theme),
      ],
    );
  }

  Widget _buildPostsView() {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final postsState = ref.watch(postsPaginationProvider);

    return Column(
      children: [
        // Header with trend icon, "Latest Posts" text, and "See All" button
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
        _buildPostsContent(postsState, localizations, theme),
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

          const SizedBox(height: 16),

          // Challenge Cards
          SizedBox(
            height: 140,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildChallengeHighlightCard(
                  title: '30-Day Recovery Challenge',
                  participants: 1847,
                  onTap: () => context.push('/community/challenges'),
                ),
                const SizedBox(width: 12),
                _buildChallengeHighlightCard(
                  title: '7-Day Mindfulness Journey',
                  participants: 432,
                  onTap: () => context.push('/community/challenges'),
                ),
                const SizedBox(width: 12),
                _buildChallengeHighlightCard(
                  title: 'Weekly Motivation Challenge',
                  participants: 891,
                  onTap: () => context.push('/community/challenges'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeHighlightCard({
    required String title,
    required int participants,
    required VoidCallback onTap,
  }) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyles.body.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primary[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    LucideIcons.users,
                    color: theme.primary[600],
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        participants >= 1000
                            ? '${(participants / 1000).toStringAsFixed(1)}k'
                            : participants.toString(),
                        style: TextStyles.caption.copyWith(
                          color: theme.grey[900],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        localizations.translate('participants'),
                        style: TextStyles.tiny.copyWith(
                          color: theme.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsView() {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final postsState = ref.watch(postsPaginationProvider);

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
        _buildPostsContent(postsState, localizations, theme),
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
            child: CircularProgressIndicator(),
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
    final categoryColor = category.color ?? theme.grey[500]!;
    final categoryIcon = category.icon ?? LucideIcons.hash;
    final displayName = _getSafeCategoryName(category, localizations);

    return GestureDetector(
      onTap: () {
        // Handle category tap - navigate to posts with this category
        setState(() {
          _selectedFilter = 'posts';
        });
        ref
            .read(postsPaginationProvider.notifier)
            .refresh(category: category.id);
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

  Widget _buildPostsContent(
      dynamic postsState, AppLocalizations localizations, theme) {
    if (postsState.posts.isEmpty && postsState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (postsState.posts.isEmpty && postsState.error != null) {
      print('❌ Error loading posts: ${postsState.error}');
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
                    .read(postsPaginationProvider.notifier)
                    .refresh(category: _getFilterCategory());
              },
              child: Text(localizations.translate('retry')),
            ),
          ],
        ),
      );
    }

    if (postsState.posts.isEmpty) {
      return Center(
        child: Text(localizations.translate('no_posts_found')),
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
        // Refresh posts with new filter only if not categories
        if (filterValue != 'categories') {
          ref
              .read(postsPaginationProvider.notifier)
              .refresh(category: _getFilterCategory());
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
