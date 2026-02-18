import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/features/vault/application/library/library_notifier.dart';
import 'package:reboot_app_3/features/vault/presentation/library/content_item_widget.dart';
import '../../data/library/models/cursor_content.dart';

class ContentScreen extends ConsumerStatefulWidget {
  const ContentScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ContentScreenState();
}

class _ContentScreenState extends ConsumerState<ContentScreen> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final int _pageSize = 10;
  bool _isLoading = false;
  bool _hasMore = true;
  List<CursorContent> _contents = [];
  Timer? _debounce;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialContent();
    searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = searchController.text;
      if (query != _lastQuery) {
        _lastQuery = query;
        _resetAndSearch();
      }
    });
  }

  Future<void> _resetAndSearch() async {
    setState(() {
      _contents = [];
      _hasMore = true;
      _isLoading = false;
    });
    await _loadContent();
  }

  Future<void> _loadInitialContent() async {
    await _loadContent();
  }

  Future<void> _loadContent() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final query = searchController.text;
      List<CursorContent> newContents;

      if (query.isEmpty) {
        // Load regular content with pagination
        final lastDoc = _contents.isNotEmpty ? _contents.last : null;
        newContents = await ref
            .read(contentListNotifierProvider.notifier)
            .getPaginatedContent(
              limit: _pageSize,
              lastDocument: lastDoc,
            );
      } else {
        // Search with pagination
        final lastDoc = _contents.isNotEmpty ? _contents.last : null;
        final (searchResults, _) = await ref
            .read(contentListNotifierProvider.notifier)
            .searchPaginated(
              query,
              limit: _pageSize,
              lastDocument: lastDoc,
            );
        newContents = searchResults;
      }

      setState(() {
        _contents.addAll(newContents);
        _isLoading = false;
        _hasMore = newContents.length == _pageSize;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Show error using your app's error handling
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadContent();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, 'explore-content', false, true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                validator: (data) => null,
                controller: searchController,
                prefixIcon: LucideIcons.search,
                inputType: TextInputType.text,
              ),
              verticalSpace(Spacing.points16),
              Expanded(
                child: ListView.separated(
                  controller: _scrollController,
                  itemCount: _contents.length + (_hasMore ? 1 : 0),
                  separatorBuilder: (context, index) =>
                      verticalSpace(Spacing.points8),
                  itemBuilder: (context, index) {
                    if (index == _contents.length) {
                      return _hasMore
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Spinner(),
                              ),
                            )
                          : const SizedBox();
                    }

                    final content = _contents[index];
                    return ContentItem(
                      content: content,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
