import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/threads_post_card.dart';
import 'package:reboot_app_3/features/community/presentation/providers/forum_providers.dart';

class CommunityMainScreen extends ConsumerStatefulWidget {
  const CommunityMainScreen({super.key});

  @override
  ConsumerState<CommunityMainScreen> createState() =>
      _CommunityMainScreenState();
}

class _CommunityMainScreenState extends ConsumerState<CommunityMainScreen> {
  bool _isChallengesSectionExpanded = true;
  String _selectedFilter = 'all';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load posts when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(postsPaginationProvider.notifier)
          .loadPosts(category: _selectedFilter);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more posts when near the bottom
      ref
          .read(postsPaginationProvider.notifier)
          .loadMorePosts(category: _selectedFilter);
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
          IconButton(
            icon: const Icon(LucideIcons.user),
            onPressed: () {
              context.push('/community/profile');
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
    return Column(
      children: [
        // Challenges Section
        _buildChallengesSection(),

        // Filter chips
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip('community-all', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('community-general', 'general'),
              const SizedBox(width: 8),
              _buildFilterChip('community-questions', 'question'),
              const SizedBox(width: 8),
              _buildFilterChip('community-tips', 'tip'),
              const SizedBox(width: 8),
              _buildFilterChip('community-support', 'support'),
            ],
          ),
        ),

        // Posts list
        Expanded(
          child: _buildPostsList(),
        ),
      ],
    );
  }

  Widget _buildChallengesSection() {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          GestureDetector(
            onTap: () {
              setState(() {
                _isChallengesSectionExpanded = !_isChallengesSectionExpanded;
              });
            },
            child: Row(
              children: [
                Icon(
                  LucideIcons.star,
                  color: theme.primary[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  localizations.translate('challenges'),
                  style: TextStyles.h6.copyWith(
                    color: theme.grey[900],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _isChallengesSectionExpanded ? 0 : -0.5,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    LucideIcons.chevronDown,
                    color: theme.grey[600],
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            localizations.translate('challenges_subtitle'),
            style: TextStyles.caption.copyWith(
              color: theme.grey[600],
            ),
          ),

          // Expandable Challenge Cards
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isChallengesSectionExpanded
                ? Column(
                    children: [
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 140,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildChallengeHighlightCard(
                              title: '30-Day Recovery Challenge',
                              participants: 1847,
                              onTap: () =>
                                  context.push('/community/challenges'),
                            ),
                            const SizedBox(width: 12),
                            _buildChallengeHighlightCard(
                              title: '7-Day Mindfulness Journey',
                              participants: 432,
                              onTap: () =>
                                  context.push('/community/challenges'),
                            ),
                            const SizedBox(width: 12),
                            _buildChallengeHighlightCard(
                              title: 'Weekly Motivation Challenge',
                              participants: 891,
                              onTap: () =>
                                  context.push('/community/challenges'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
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

  // Groups tab moved to separate navigation tab

  // Removed _buildChallengesTab method

  Widget _buildPostsList() {
    final postsState = ref.watch(postsPaginationProvider);

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
              'Error loading posts',
              style: TextStyles.body.copyWith(
                color: AppTheme.of(context).error[500],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(postsPaginationProvider.notifier)
                    .refresh(category: _selectedFilter);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (postsState.posts.isEmpty) {
      return const Center(
        child: Text('No posts found'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(postsPaginationProvider.notifier)
            .refresh(category: _selectedFilter);
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

  Widget _buildFilterChip(String translationKey, String filterValue) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final isSelected = _selectedFilter == filterValue;

    return FilterChip(
      label: Text(
        localizations.translate(translationKey),
        style: TextStyles.caption.copyWith(
          color: isSelected ? theme.primary[700] : theme.grey[900],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = filterValue;
          });
          // Refresh posts with new filter
          ref
              .read(postsPaginationProvider.notifier)
              .refresh(category: filterValue);
        }
      },
      backgroundColor: theme.grey[50],
      selectedColor: theme.primary[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? theme.primary[300]! : theme.grey[200]!,
        ),
      ),
    );
  }
}
