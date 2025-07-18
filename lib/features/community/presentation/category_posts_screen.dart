import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/threads_post_card.dart';
import 'package:reboot_app_3/features/community/presentation/providers/forum_providers.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/advanced_search_modal.dart';
import 'package:reboot_app_3/features/community/data/models/post_category.dart';

class CategoryPostsScreen extends ConsumerStatefulWidget {
  final PostCategory category;

  const CategoryPostsScreen({
    super.key,
    required this.category,
  });

  @override
  ConsumerState<CategoryPostsScreen> createState() =>
      _CategoryPostsScreenState();
}

class _CategoryPostsScreenState extends ConsumerState<CategoryPostsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, dynamic>? _activeFilters;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    // Load posts for this category when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(postsPaginationProvider.notifier)
          .loadPosts(category: widget.category.id);
    });
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

    // Load more posts when near the bottom
    if (scrollPosition >= _scrollController.position.maxScrollExtent - 200) {
      ref
          .read(postsPaginationProvider.notifier)
          .loadMorePosts(category: widget.category.id);
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
    // TODO: Implement search logic with category filter
    setState(() {
      _searchQuery = _searchController.text;
    });
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
        // TODO: Apply filters to post loading
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _activeFilters = null;
    });
    // Refresh posts for this category without filters
    ref
        .read(postsPaginationProvider.notifier)
        .refresh(category: widget.category.id);
  }

  String _getCategoryDisplayName() {
    final localizations = AppLocalizations.of(context);
    try {
      // Check if locale is Arabic and use nameAr, otherwise use name
      final isArabic = localizations.locale.languageCode == 'ar';

      if (isArabic && widget.category.nameAr.isNotEmpty) {
        return widget.category.nameAr;
      } else if (widget.category.name.isNotEmpty) {
        return widget.category.name;
      } else {
        // Fallback to ID if both names are empty
        return widget.category.id;
      }
    } catch (e) {
      // Ultimate fallback - return category ID
      return widget.category.id.isNotEmpty ? widget.category.id : 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: plainAppBar(
        context,
        ref,
        _getCategoryDisplayName(),
        false,
        true,
      ),
      backgroundColor: theme.backgroundColor,
      body: Column(
        children: [
          // Category Info Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.category.color.withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(
                  color: theme.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  widget.category.icon,
                  color: widget.category.color,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getCategoryDisplayName(),
                        style: TextStyles.h6.copyWith(
                          color: widget.category.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        localizations.translate('category_posts_subtitle'),
                        style: TextStyles.caption.copyWith(
                          color: theme.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

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
                              if (_activeFilters?['author']?.isNotEmpty == true)
                                _buildFilterChip(
                                  label:
                                      '${localizations.translate('author')}: ${_activeFilters!['author']}',
                                  onRemove: () {
                                    setState(() {
                                      _activeFilters!['author'] = '';
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),

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
    final postsState = ref.watch(postsPaginationProvider);

    if (postsState.posts.isEmpty && postsState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
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
                ref
                    .read(postsPaginationProvider.notifier)
                    .refresh(category: widget.category.id);
              },
              child: Text(localizations.translate('retry')),
            ),
          ],
        ),
      );
    }

    if (postsState.posts.isEmpty) {
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
              _searchQuery.isNotEmpty || _activeFilters != null
                  ? localizations.translate('no_results_found')
                  : localizations.translate('no_posts_in_category'),
              style: TextStyles.body.copyWith(
                color: theme.grey[600],
              ),
            ),
            if (_searchQuery.isNotEmpty || _activeFilters != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextButton(
                  onPressed: _clearFilters,
                  child: Text(localizations.translate('clear_filters')),
                ),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(postsPaginationProvider.notifier)
            .refresh(category: widget.category.id);
      },
      child: ListView.builder(
        controller: _scrollController,
        itemCount: postsState.posts.length + (postsState.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == postsState.posts.length) {
            // Loading indicator at the bottom
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final post = postsState.posts[index];
          return ThreadsPostCard(
            post: post,
            onTap: () {
              context.push('/community/forum/post/${post.id}');
            },
          );
        },
      ),
    );
  }
}
