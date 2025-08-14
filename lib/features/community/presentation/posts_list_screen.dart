import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/threads_post_card.dart';
import 'package:reboot_app_3/features/community/presentation/providers/forum_providers.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/advanced_search_modal.dart';
import 'package:reboot_app_3/features/community/data/models/post_search_filters.dart';
import 'package:reboot_app_3/features/community/data/models/post_category.dart';

class PostsListScreen extends ConsumerStatefulWidget {
  const PostsListScreen({super.key});

  @override
  ConsumerState<PostsListScreen> createState() => _PostsListScreenState();
}

class _PostsListScreenState extends ConsumerState<PostsListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, dynamic>? _activeFilters;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    // Load posts when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePosts();
    });
  }

  /// Initialize posts loading with debugging
  void _initializePosts() {
    ref.read(postsPaginationProvider.notifier).loadPosts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final scrollPosition = _scrollController.position.pixels;

    // Only auto-load for search results, not for regular posts (which use manual pagination)
    if (scrollPosition >= _scrollController.position.maxScrollExtent - 200) {
      final hasActiveSearch = _searchQuery.isNotEmpty || _activeFilters != null;

      if (hasActiveSearch) {
        // Load more search results automatically for search
        ref
            .read(searchPostsPaginationProvider.notifier)
            .loadMoreSearchResults();
      }
      // Regular posts now use manual "Load More" button instead of auto-pagination
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    // Trigger search when user stops typing (debounce can be added here if needed)
    _performSearch();
  }

  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text;
    });

    // Create search filters with current query and any active filters
    final filters = PostSearchFilters(
      searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      category: _activeFilters?['category'],
      sortBy: _activeFilters?['sortBy'] ?? 'newest_first',
      startDate: _activeFilters?['startDate'],
      endDate: _activeFilters?['endDate'],
    );

    // Perform search if we have any filters or query
    if (filters.hasActiveFilters) {
      ref.read(searchPostsPaginationProvider.notifier).searchPosts(filters);
    } else {
      // Clear search if no filters
      ref.read(searchPostsPaginationProvider.notifier).clearSearch();
    }
  }

  void _showAdvancedSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const AdvancedSearchModal(),
      ),
    ).then((filters) {
      if (filters != null) {
        setState(() {
          _activeFilters = filters;
        });
        // Apply the filters immediately
        _performSearch();
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _activeFilters = null;
    });
    // Clear search results and refresh regular posts
    ref.read(searchPostsPaginationProvider.notifier).clearSearch();
    ref.read(postsPaginationProvider.notifier).refresh();
  }

  String _getCategoryDisplayName(String categoryId) {
    final localizations = AppLocalizations.of(context);
    final categoriesAsync = ref.read(postCategoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        try {
          final category = categories.firstWhere(
            (cat) => cat.id == categoryId,
          );
          return category.getDisplayName(localizations.locale.languageCode);
        } catch (e) {
          // Category not found, return the ID as fallback
          return categoryId;
        }
      },
      loading: () => categoryId,
      error: (_, __) => categoryId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    // Listen to community state changes and load posts
    ref.listen<CommunityScreenState>(communityScreenStateProvider,
        (previous, next) {
      if (next == CommunityScreenState.showMainContent && previous != next) {
        Future.delayed(Duration(milliseconds: 100), () {
          ref.read(postsPaginationProvider.notifier).loadPosts();
        });
      }
    });

    return Scaffold(
      appBar: appBar(
        context,
        ref,
        "community_posts",
        false,
        true,
      ),
      backgroundColor: theme.backgroundColor,
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.backgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: theme.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Search Bar
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _searchController,

                        prefixIcon: LucideIcons.search,
                        inputType: TextInputType.text,
                        validator: (value) =>
                            null, // No validation needed for search
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: theme.grey[900]!, width: 1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Advanced Search Button
                    GestureDetector(
                      onTap: _showAdvancedSearch,
                      child: WidgetsContainer(
                        padding: const EdgeInsets.all(12),
                        backgroundColor: theme.primary[500],
                        child: Icon(
                          LucideIcons.sliders,
                          color: theme.grey[50],
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),

                // Filter Chips Row
                Row(
                  children: [
                    // Active Filters Indicator
                    if (_activeFilters != null || _searchQuery.isNotEmpty)
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (_searchQuery.isNotEmpty)
                                _buildFilterChip(
                                  label:
                                      '${localizations.translate('search')}: "$_searchQuery"',
                                  onRemove: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                ),
                              if (_activeFilters?['category']?.isNotEmpty ==
                                  true)
                                _buildFilterChip(
                                  label:
                                      '${localizations.translate('category')}: ${_getCategoryDisplayName(_activeFilters!['category'])}',
                                  onRemove: () {
                                    setState(() {
                                      _activeFilters!['category'] = '';
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    // Expanded(
                    //   child: Text(
                    //     localizations.translate('search_in_posts'),
                    //     style: TextStyles.caption.copyWith(
                    //       color: theme.grey[600],
                    //     ),
                    //   ),
                    // ),

                    // Clear All Filters
                    if (_activeFilters != null || _searchQuery.isNotEmpty)
                      TextButton(
                        onPressed: _clearFilters,
                        child: Text(
                          localizations.translate('clear_filters'),
                          style: TextStyles.caption.copyWith(
                            color: theme.primary[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Posts List
          Expanded(
            child: _buildPostsList(localizations),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    final theme = AppTheme.of(context);

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: WidgetsContainer(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        backgroundColor: theme.primary[100],
        borderSide: BorderSide(color: theme.primary[300]!),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyles.caption.copyWith(
                color: theme.primary[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRemove,
              child: Icon(
                LucideIcons.x,
                size: 14,
                color: theme.primary[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsList(AppLocalizations localizations) {
    final theme = AppTheme.of(context);

    // Check if we have active search filters
    final hasActiveSearch = _searchQuery.isNotEmpty || _activeFilters != null;

    if (hasActiveSearch) {
      // Show search results
      final searchState = ref.watch(searchPostsPaginationProvider);

      if (searchState.posts.isEmpty && searchState.isLoading) {
        return const Center(
          child: Spinner(),
        );
      }

      if (searchState.posts.isEmpty && searchState.error != null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.alertCircle,
                size: 48,
                color: theme.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                localizations.translate('error_searching_posts'),
                style: TextStyles.body.copyWith(
                  color: theme.error[500],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _performSearch,
                child: Text(localizations.translate('retry')),
              ),
            ],
          ),
        );
      }

      if (searchState.posts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.search,
                size: 48,
                color: theme.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                localizations.translate('no_search_results'),
                style: TextStyles.body.copyWith(
                  color: theme.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _clearFilters,
                child: Text(
                  localizations.translate('clear_filters'),
                  style: TextStyles.caption.copyWith(
                    color: theme.primary[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          await ref.read(searchPostsPaginationProvider.notifier).refresh();
        },
        child: ListView.builder(
          controller: _scrollController,
          itemCount: searchState.posts.length + (searchState.isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == searchState.posts.length) {
              // Loading indicator at the bottom
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Spinner(),
                ),
              );
            }

            final post = searchState.posts[index];
            return ThreadsPostCard(
              post: post,
              onTap: () {
                context.goNamed(RouteNames.postDetail.name,
                    pathParameters: {'postId': post.id});
              },
            );
          },
        ),
      );
    } else {
      // Show regular posts with manual pagination

      final postsState = ref.watch(postsPaginationProvider);

      if (postsState.posts.isEmpty && postsState.isLoading) {
        return const Center(child: Spinner());
      }

      if (postsState.posts.isEmpty && postsState.error != null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.alertCircle,
                size: 48,
                color: theme.grey[400],
              ),
              const SizedBox(height: 16),
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

      if (postsState.posts.isEmpty && !postsState.hasMore) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.search,
                size: 48,
                color: theme.grey[400],
              ),
              const SizedBox(height: 16),
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

      return RefreshIndicator(
        onRefresh: () async {
          await ref.read(postsPaginationProvider.notifier).refresh();
        },
        child: ListView.builder(
          controller: _scrollController,
          itemCount: postsState.posts.length + (postsState.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == postsState.posts.length) {
              // Load More button at the bottom
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: postsState.isLoading
                    ? const Center(child: Spinner())
                    : ElevatedButton(
                        onPressed: () {
                          ref
                              .read(postsPaginationProvider.notifier)
                              .loadMorePosts();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary[500],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.plus,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              localizations.translate('load_more'),
                              style: TextStyles.body.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
              );
            }

            final post = postsState.posts[index];
            return ThreadsPostCard(
              post: post,
              onTap: () {
                context.goNamed(RouteNames.postDetail.name,
                    pathParameters: {'postId': post.id});
              },
            );
          },
        ),
      );
    }
  }
}
