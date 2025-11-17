import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/features/groups/application/updates_providers.dart';
import 'package:reboot_app_3/features/groups/presentation/widgets/updates/update_card_widget.dart';
import 'package:reboot_app_3/features/groups/domain/entities/group_update_entity.dart';
import 'package:reboot_app_3/features/groups/presentation/modals/post_update_modal.dart';

/// Full updates feed screen with pagination
class AllUpdatesScreen extends ConsumerStatefulWidget {
  final String groupId;

  const AllUpdatesScreen({super.key, required this.groupId});

  @override
  ConsumerState<AllUpdatesScreen> createState() => _AllUpdatesScreenState();
}

class _AllUpdatesScreenState extends ConsumerState<AllUpdatesScreen> {
  final ScrollController _scrollController = ScrollController();
  List<GroupUpdateEntity> _allUpdates = [];
  DateTime? _lastUpdateTime;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialUpdates();

    // Listen for provider changes (e.g., after adding/deleting updates)
    Future.microtask(() {
      ref.listenManual(
        recentUpdatesProvider(widget.groupId, limit: 20),
        (previous, next) {
          next.whenData((updates) {
            if (mounted) {
              setState(() {
                _allUpdates = updates;
                if (updates.isNotEmpty) {
                  _lastUpdateTime = updates.last.createdAt;
                }
                _hasMore = updates.length == 20;
              });
            }
          });
        },
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadInitialUpdates() async {
    final updates = await ref.read(
      recentUpdatesProvider(widget.groupId, limit: 20).future,
    );
    if (mounted) {
      setState(() {
        _allUpdates = updates;
        if (updates.isNotEmpty) {
          _lastUpdateTime = updates.last.createdAt;
        }
        _hasMore = updates.length == 20;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final moreUpdates = await ref.read(
        recentUpdatesProvider(
          widget.groupId,
          limit: 20,
          before: _lastUpdateTime,
        ).future,
      );

      if (mounted) {
        setState(() {
          _allUpdates.addAll(moreUpdates);
          if (moreUpdates.isNotEmpty) {
            _lastUpdateTime = moreUpdates.last.createdAt;
          }
          _hasMore = moreUpdates.length == 20;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _onRefresh() async {
    // Invalidate all providers to force a fresh fetch
    ref.invalidate(latestUpdatesProvider(widget.groupId));
    ref.invalidate(recentUpdatesProvider(widget.groupId));
    ref.invalidate(groupUpdatesProvider(widget.groupId));

    // Reset local state
    setState(() {
      _allUpdates = [];
      _lastUpdateTime = null;
      _hasMore = true;
    });

    // Reload from provider
    await _loadInitialUpdates();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(
        context,
        ref,
        'updates',
        false,
        true,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _allUpdates.isEmpty
            ? _buildEmptyState(context, theme, l10n)
            : ListView.builder(
                controller: _scrollController,
                itemCount: _allUpdates.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _allUpdates.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final update = _allUpdates[index];
                  return UpdateCardWidget(
                    update: update,
                    groupId: widget.groupId,
                    onTap: () => _navigateToDetail(context, update.id),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPostUpdateModal(context),
        backgroundColor: theme.primary[500],
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    dynamic theme,
    AppLocalizations l10n,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "📢",
              style: TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.translate('no-updates-yet'),
              style: TextStyles.h6.copyWith(
                color: theme.grey[900],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.translate('be-first-to-share'),
              style: TextStyles.body.copyWith(
                color: theme.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showPostUpdateModal(context),
              icon: const Icon(LucideIcons.plus),
              label: Text(l10n.translate('post-update')),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary[500],
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPostUpdateModal(BuildContext context) {
    PostUpdateModal.show(context, widget.groupId);
  }

  void _navigateToDetail(BuildContext context, String updateId) {
    // Update detail can be implemented later if needed
    // For now, comments are shown inline in the card
  }
}
