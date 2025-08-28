import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/features/community/presentation/providers/forum_providers.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/community/application/attachment_group_service.dart';
import 'package:reboot_app_3/features/community/data/models/post.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/compact_poll_widget.dart';

/// Main attachment renderer that dispatches to specific renderers
class AttachmentRenderer extends ConsumerWidget {
  final Post post;
  final bool isListView;

  const AttachmentRenderer({
    super.key,
    required this.post,
    this.isListView = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!post.attachmentTypes.contains('image') &&
        !post.attachmentTypes.contains('poll') &&
        !post.attachmentTypes.contains('group_invite')) {
      print(
          '🎨 [ATTACHMENT_RENDERER] No supported attachment types found, returning empty');
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),

        // Render based on attachment type
        if (post.attachmentTypes.contains('image')) ...[
          Builder(builder: (context) {
            print('🖼️ [ATTACHMENT_RENDERER] Rendering image attachment');
            return _ImageAttachmentRenderer(
              post: post,
              isListView: isListView,
            );
          }),
        ],

        if (post.attachmentTypes.contains('poll')) ...[
          Builder(builder: (context) {
            print('🗳️ [ATTACHMENT_RENDERER] Rendering poll attachment');
            return _PollAttachmentRenderer(
              post: post,
              isListView: isListView,
            );
          }),
        ],

        if (post.attachmentTypes.contains('group_invite')) ...[
          Builder(builder: (context) {
            print('👥 [ATTACHMENT_RENDERER] Rendering group invite attachment');
            return _GroupInviteAttachmentRenderer(
              post: post,
              isListView: isListView,
            );
          }),
        ],
      ],
    );
  }
}

/// Image attachment renderer with Threads-style grid layout
class _ImageAttachmentRenderer extends StatelessWidget {
  final Post post;
  final bool isListView;

  const _ImageAttachmentRenderer({
    required this.post,
    required this.isListView,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final imageAttachments = post.attachmentsSummary
        .where((attachment) => attachment['type'] == 'image')
        .toList();

    // Using 100% original quality images everywhere

    if (imageAttachments.isEmpty) return const SizedBox.shrink();

    return _buildImageGrid(context, theme, imageAttachments);
  }

  Widget _buildImageGrid(
    BuildContext context,
    CustomThemeData theme,
    List<Map<String, dynamic>> images,
  ) {
    if (isListView) {
      return _buildListViewImages(context, theme, images);
    } else {
      return _buildDetailViewImages(context, theme, images);
    }
  }

  Widget _buildListViewImages(
    BuildContext context,
    CustomThemeData theme,
    List<Map<String, dynamic>> images,
  ) {
    if (images.length == 1) {
      return _buildSingleImagePreview(context, theme, images.first);
    } else {
      return _buildMultiImageGrid(context, theme, images);
    }
  }

  Widget _buildSingleImagePreview(
    BuildContext context,
    CustomThemeData theme,
    Map<String, dynamic> image,
  ) {
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 200,
        minHeight: 120,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9, // Default aspect ratio for single images
          child: Image.network(
            image['downloadUrl'] ??
                image['thumbnailUrl'], // Use full resolution for single images
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: theme.grey[100],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              color: theme.grey[100],
              child: Center(
                child: Icon(
                  LucideIcons.imageOff,
                  color: theme.grey[400],
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMultiImageGrid(
    BuildContext context,
    CustomThemeData theme,
    List<Map<String, dynamic>> images,
  ) {
    const double imageSize = 120.0; // Increased from 72
    const double spacing = 8.0;
    const double borderRadius = 12.0; // Increased from 8

    return SizedBox(
      height: images.length > 2 ? imageSize * 2 + spacing : imageSize,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: 1.0,
        ),
        itemCount: images.length > 4 ? 4 : images.length,
        itemBuilder: (context, index) {
          final isLastItem = index == 3 && images.length > 4;
          final remainingCount = images.length - 4;

          return GestureDetector(
            onTap: () => _openImageViewer(context, images, index),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    color: theme.grey[100],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(borderRadius),
                    child: (images[index]['downloadUrl'] ??
                                images[index]['thumbnailUrl']) !=
                            null
                        ? Image.network(
                            images[index]['downloadUrl'] ??
                                images[index][
                                    'thumbnailUrl'], // Use full resolution everywhere
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: theme.grey[100],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                Center(
                              child: Icon(
                                LucideIcons.imageOff,
                                color: theme.grey[400],
                                size: 24,
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              LucideIcons.image,
                              color: theme.grey[400],
                              size: 24,
                            ),
                          ),
                  ),
                ),
                if (isLastItem && remainingCount > 0)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(borderRadius),
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                    child: Center(
                      child: Text(
                        '+$remainingCount',
                        style: TextStyles.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailViewImages(
    BuildContext context,
    CustomThemeData theme,
    List<Map<String, dynamic>> images,
  ) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      child: _buildResponsiveImageGrid(context, theme, images),
    );
  }

  Widget _buildResponsiveImageGrid(
    BuildContext context,
    CustomThemeData theme,
    List<Map<String, dynamic>> images,
  ) {
    const double borderRadius = 12.0;
    const double spacing = 4.0;

    if (images.length == 1) {
      return _buildSingleImage(context, images.first, borderRadius);
    } else if (images.length == 2) {
      return _buildTwoImages(context, images, borderRadius, spacing);
    } else if (images.length == 3) {
      return _buildThreeImages(context, images, borderRadius, spacing);
    } else {
      return _buildFourImages(context, images, borderRadius, spacing);
    }
  }

  Widget _buildSingleImage(
    BuildContext context,
    Map<String, dynamic> image,
    double borderRadius,
  ) {
    return GestureDetector(
      onTap: () => _openImageViewer(context, [image], 0),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: AppTheme.of(context).grey[100],
            image: (image['downloadUrl'] ?? image['thumbnailUrl']) != null
                ? DecorationImage(
                    image: NetworkImage(
                        image['downloadUrl'] ?? image['thumbnailUrl']),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: (image['downloadUrl'] ?? image['thumbnailUrl']) == null
              ? Center(
                  child: Icon(
                    LucideIcons.image,
                    color: AppTheme.of(context).grey[400],
                    size: 32,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildTwoImages(
    BuildContext context,
    List<Map<String, dynamic>> images,
    double borderRadius,
    double spacing,
  ) {
    return Row(
      children: [
        Expanded(child: _buildImageTile(context, images[0], borderRadius, 0)),
        SizedBox(width: spacing),
        Expanded(child: _buildImageTile(context, images[1], borderRadius, 1)),
      ],
    );
  }

  Widget _buildThreeImages(
    BuildContext context,
    List<Map<String, dynamic>> images,
    double borderRadius,
    double spacing,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildImageTile(context, images[0], borderRadius, 0),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: Column(
            children: [
              Expanded(
                  child: _buildImageTile(context, images[1], borderRadius, 1)),
              SizedBox(height: spacing),
              Expanded(
                  child: _buildImageTile(context, images[2], borderRadius, 2)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFourImages(
    BuildContext context,
    List<Map<String, dynamic>> images,
    double borderRadius,
    double spacing,
  ) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                  child: _buildImageTile(context, images[0], borderRadius, 0)),
              SizedBox(width: spacing),
              Expanded(
                  child: _buildImageTile(context, images[1], borderRadius, 1)),
            ],
          ),
        ),
        SizedBox(height: spacing),
        Expanded(
          child: Row(
            children: [
              Expanded(
                  child: _buildImageTile(context, images[2], borderRadius, 2)),
              SizedBox(width: spacing),
              Expanded(
                  child: _buildImageTile(context, images[3], borderRadius, 3)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageTile(
    BuildContext context,
    Map<String, dynamic> image,
    double borderRadius,
    int index,
  ) {
    return GestureDetector(
      onTap: () => _openImageViewer(context, [image], index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: AppTheme.of(context).grey[100],
          image: (image['downloadUrl'] ?? image['thumbnailUrl']) != null
              ? DecorationImage(
                  image: NetworkImage(
                      image['downloadUrl'] ?? image['thumbnailUrl']),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: (image['downloadUrl'] ?? image['thumbnailUrl']) == null
            ? Center(
                child: Icon(
                  LucideIcons.image,
                  color: AppTheme.of(context).grey[400],
                  size: 24,
                ),
              )
            : null,
      ),
    );
  }

  void _openImageViewer(
    BuildContext context,
    List<Map<String, dynamic>> images,
    int initialIndex,
  ) {
    final theme = AppTheme.of(context);

    showDialog(
      context: context,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black87,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            '${initialIndex + 1} ${AppLocalizations.of(context)?.translate('of')} ${images.length}',
            style: TextStyles.body.copyWith(color: Colors.white),
          ),
        ),
        body: Center(
          child: PageView.builder(
            itemCount: images.length,
            controller: PageController(initialPage: initialIndex),
            itemBuilder: (context, index) {
              final image = images[index];
              final imageUrl = image['downloadUrl'] ?? image['thumbnailUrl'];

              // Using 100% original quality in image viewer

              return Center(
                child: imageUrl != null
                    ? InteractiveViewer(
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: Colors.white,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.imageOff,
                                  size: 48,
                                  color: theme.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Failed to load image',
                                  style: TextStyles.body.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.image,
                              size: 48,
                              color: theme.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Image not available',
                              style: TextStyles.body.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Poll attachment renderer with Threads-style design
class _PollAttachmentRenderer extends ConsumerWidget {
  final Post post;
  final bool isListView;

  const _PollAttachmentRenderer({
    required this.post,
    required this.isListView,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final pollSummary = post.attachmentsSummary.firstWhere(
        (a) => a['type'] == 'poll',
        orElse: () => <String, dynamic>{});

    if (pollSummary.isEmpty) return const SizedBox.shrink();

    if (isListView) {
      return _buildListViewPoll(
          context, theme, localizations, pollSummary, ref);
    } else {
      return _buildDetailViewPoll(
          context, theme, localizations, pollSummary, ref);
    }
  }

  Widget _buildListViewPoll(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations localizations,
    Map<String, dynamic> pollSummary,
    WidgetRef ref,
  ) {
    final pollId = pollSummary['id'] as String?;
    if (pollId == null) {
      return _buildAttachmentRemoved(theme);
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ref.read(forumRepositoryProvider).getPostAttachments(post.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primary[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.barChart3,
                    size: 16, color: theme.primary[600]),
                const SizedBox(width: 8),
                Text('Loading poll...', style: TextStyles.caption),
              ],
            ),
          );
        }

        final attachments = snapshot.data!;
        final pollDoc = attachments.firstWhere(
          (a) => a['id'] == pollId && a['type'] == 'poll',
          orElse: () => <String, dynamic>{},
        );

        if (pollDoc.isEmpty) {
          return _buildAttachmentRemoved(theme);
        }

        return CompactPollWidget(
          post: post,
          pollDoc: pollDoc,
          theme: theme,
          localizations: localizations,
        );
      },
    );
  }

  Widget _buildDetailViewPoll(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations localizations,
    Map<String, dynamic> pollSummary,
    WidgetRef ref,
  ) {
    final pollId = pollSummary['id'] as String?;
    if (pollId == null) {
      return _buildAttachmentRemoved(theme);
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ref.read(forumRepositoryProvider).getPostAttachments(post.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.primary[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.primary[100]!, width: 1),
            ),
            child: const SizedBox(height: 48),
          );
        }

        if (!snapshot.hasData) {
          return _buildAttachmentRemoved(theme);
        }

        final attachments = snapshot.data!;
        final pollDoc = attachments.firstWhere(
          (a) => a['id'] == pollId && a['type'] == 'poll',
          orElse: () => <String, dynamic>{},
        );

        if (pollDoc.isEmpty) {
          return _buildAttachmentRemoved(theme);
        }

        final pollQuestion =
            pollDoc['question'] ?? pollSummary['title'] ?? 'Poll';
        final List options = (pollDoc['options'] ?? []) as List;
        final isMultiSelect = (pollDoc['selectionMode'] ?? 'single') == 'multi';
        final isClosed = pollDoc['isClosed'] == true;
        final totalVotes = (pollDoc['totalVotes'] ?? 0) as int;
        // Handle both Map (new) and List (old) formats for optionCounts
        final dynamic rawOptionCounts = pollDoc['optionCounts'];
        final List<int> optionCounts;

        if (rawOptionCounts is Map) {
          // New format: Map<optionId, count>
          optionCounts = options.map((option) {
            final optionData = option as Map<String, dynamic>;
            final optionId = optionData['id'] as String;
            return (rawOptionCounts[optionId] ?? 0) as int;
          }).toList();
        } else if (rawOptionCounts is List) {
          // Old format: List<int>
          optionCounts = List<int>.from(rawOptionCounts);
        } else {
          // Fallback: empty counts
          optionCounts = List.filled(options.length, 0);
        }

        return _PollDetailCard(
          theme: theme,
          localizations: localizations,
          postId: post.id,
          pollId: pollId,
          question: pollQuestion,
          options: options,
          isMultiSelect: isMultiSelect,
          isClosed: isClosed,
          totalVotes: totalVotes,
          optionCounts: optionCounts,
          ref: ref, // Pass ref to check user vote
        );
      },
    );
  }

  Widget _buildAttachmentRemoved(CustomThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.grey[200]!, width: 1),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertCircle, color: theme.grey[500], size: 18),
          const SizedBox(width: 8),
          Text(
            'Attachment removed',
            style: TextStyles.caption.copyWith(color: theme.grey[700]),
          ),
        ],
      ),
    );
  }
}

class _PollDetailCard extends ConsumerStatefulWidget {
  final CustomThemeData theme;
  final AppLocalizations localizations;
  final String postId;
  final String pollId;
  final String question;
  final List options; // List<Map<String, dynamic>> with id,text
  final bool isMultiSelect;
  final bool isClosed;
  final int totalVotes;
  final List<int> optionCounts;
  final WidgetRef ref;

  const _PollDetailCard({
    required this.theme,
    required this.localizations,
    required this.postId,
    required this.pollId,
    required this.question,
    required this.options,
    required this.isMultiSelect,
    required this.isClosed,
    required this.totalVotes,
    required this.optionCounts,
    required this.ref,
  });

  @override
  ConsumerState<_PollDetailCard> createState() => _PollDetailCardState();
}

class _PollDetailCardState extends ConsumerState<_PollDetailCard> {
  Set<String> _selected = <String>{};
  bool _submitting = false;
  bool _hasVoted = false;
  bool _loadingVote = true;

  @override
  void initState() {
    super.initState();
    _loadUserVote();
  }

  Future<void> _loadUserVote() async {
    try {
      final profileAsync = widget.ref.read(currentCommunityProfileProvider);
      String? cpId;
      await profileAsync.when(
        data: (p) async => cpId = p?.id,
        loading: () async {},
        error: (_, __) async {},
      );

      if (cpId != null && cpId!.isNotEmpty) {
        final userVote = await widget.ref
            .read(forumRepositoryProvider)
            .getUserPollVote(widget.postId, widget.pollId, cpId!);

        if (userVote != null) {
          setState(() {
            _selected = Set<String>.from(userVote['selectedOptionIds'] ?? []);
            _hasVoted = _selected.isNotEmpty;
            _loadingVote = false;
          });
        } else {
          setState(() {
            _loadingVote = false;
          });
        }
      } else {
        setState(() {
          _loadingVote = false;
        });
      }
    } catch (e) {
      setState(() {
        _loadingVote = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final l10n = widget.localizations;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primary[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primary[100]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.barChart3, size: 20, color: theme.primary[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.question,
                  style: TextStyles.body.copyWith(
                    color: theme.primary[800],
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.isClosed)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    l10n.translate('poll-closed'),
                    style: TextStyles.small.copyWith(
                      color: theme.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Options and/or results
          ..._buildOptionsOrResults(theme, l10n),

          const SizedBox(height: 12),

          // Vote button
          if (!widget.isClosed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting || _loadingVote || _hasVoted
                    ? null
                    : _submitVote,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _hasVoted ? theme.success[600] : theme.primary[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : _loadingVote
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _hasVoted
                                ? l10n.translate('poll-voted')
                                : l10n.translate('poll-vote'),
                            style: TextStyles.body
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildOptionsOrResults(
      CustomThemeData theme, AppLocalizations l10n) {
    // Decide if we show results or options
    final showResultsImmediately =
        widget.totalVotes > 0; // voters see results immediately via aggregation
    final shouldShowResults = widget.isClosed || showResultsImmediately;

    if (shouldShowResults) {
      final total = widget.totalVotes == 0 ? 1 : widget.totalVotes;
      return List<Widget>.generate(widget.options.length, (index) {
        final option = widget.options[index] as Map<String, dynamic>;
        final count =
            index < widget.optionCounts.length ? widget.optionCounts[index] : 0;
        final percent = (count / total * 100).round();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      option['text'] ?? '',
                      style: TextStyles.body.copyWith(color: theme.grey[800]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$percent%',
                      style:
                          TextStyles.caption.copyWith(color: theme.grey[700])),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: theme.primary[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (count / total).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.primary[600],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      });
    }

    // Show selectable options
    return List<Widget>.generate(widget.options.length, (index) {
      final option = widget.options[index] as Map<String, dynamic>;
      final id = option['id'] as String? ?? index.toString();
      final text = option['text'] as String? ?? '';
      final selected = _selected.contains(id);
      return InkWell(
        onTap: () {
          setState(() {
            if (widget.isMultiSelect) {
              if (selected) {
                _selected.remove(id);
              } else {
                _selected.add(id);
              }
            } else {
              _selected = {id};
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: selected ? theme.primary[50] : theme.grey[50],
            border: Border.all(
                color: selected ? theme.primary[300]! : theme.grey[200]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                widget.isMultiSelect
                    ? (selected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank)
                    : (selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off),
                size: 18,
                color: selected ? theme.primary[600] : theme.grey[500],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: TextStyles.body.copyWith(color: theme.grey[800]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _submitVote() async {
    if (_selected.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final profileAsync = ref.read(currentCommunityProfileProvider);
      String? cpId;
      await profileAsync.when(
        data: (p) async {
          cpId = p?.id;
        },
        loading: () async {},
        error: (_, __) async {},
      );
      if (cpId == null || cpId!.isEmpty) {
        setState(() => _submitting = false);
        return;
      }
      await ref.read(forumRepositoryProvider).createPollVote(
            postId: widget.postId,
            pollId: widget.pollId,
            cpId: cpId!,
            selectedOptionIds: _selected.toList(),
          );
      if (mounted) {
        setState(() => _submitting = false);
      }
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

/// Group invite attachment renderer
class _GroupInviteAttachmentRenderer extends ConsumerWidget {
  final Post post;
  final bool isListView;

  const _GroupInviteAttachmentRenderer({
    required this.post,
    required this.isListView,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final inviteSummary = post.attachmentsSummary.firstWhere(
        (a) => a['type'] == 'group_invite',
        orElse: () => <String, dynamic>{});

    if (inviteSummary.isEmpty) return const SizedBox.shrink();

    if (isListView) {
      return _buildListViewInvite(context, theme, localizations, inviteSummary);
    } else {
      return _buildDetailViewInvite(
          context, theme, localizations, inviteSummary, ref);
    }
  }

  Widget _buildListViewInvite(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations localizations,
    Map<String, dynamic> inviteSummary,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.success[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.success[100]!, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.users,
            size: 16,
            color: theme.success[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              inviteSummary['groupName'] ??
                  localizations.translate('group-invite'),
              style: TextStyles.footnote.copyWith(
                color: theme.success[700],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.success[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              localizations.translate('invite'),
              style: TextStyles.tiny.copyWith(
                color: theme.success[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailViewInvite(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations localizations,
    Map<String, dynamic> inviteSummary,
    WidgetRef ref,
  ) {
    final groupName = inviteSummary['groupName'] ?? 'Group';
    final groupGender = inviteSummary['groupGender'] ?? 'Mixed';
    final memberCount = inviteSummary['groupMemberCount'] ?? 0;
    final capacity = inviteSummary['groupCapacity'] ?? 0;
    final isPlusOnly = inviteSummary['groupPlusOnly'] ?? false;
    final joinMethod = inviteSummary['joinMethod'] ?? 'code_only';
    final inviteId = inviteSummary['id'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.success[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.success[100]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group header
          Row(
            children: [
              // Group avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.success[100],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    groupName.isNotEmpty ? groupName[0].toUpperCase() : 'G',
                    style: TextStyles.h6.copyWith(
                      color: theme.success[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            groupName,
                            style: TextStyles.body.copyWith(
                              color: theme.success[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isPlusOnly)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEBA01),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Plus',
                              style: TextStyles.small.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$groupGender • $memberCount/$capacity members',
                      style: TextStyles.caption.copyWith(
                        color: theme.success[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Join button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                // Load the full invite attachment to get groupId and joinCode
                try {
                  final attachments = await ref
                      .read(forumRepositoryProvider)
                      .getPostAttachments(post.id);
                  final inviteDoc = attachments.firstWhere(
                    (a) => a['id'] == inviteId && a['type'] == 'group_invite',
                    orElse: () => <String, dynamic>{},
                  );

                  if (inviteDoc.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text(localizations.translate('attachment-removed')),
                        backgroundColor: theme.error[600],
                      ),
                    );
                    return;
                  }

                  final groupId = inviteDoc['groupId'] as String?;
                  final joinCode = inviteDoc['inviteJoinCode'] as String?;
                  if (groupId == null || joinCode == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(localizations.translate('generic_error')),
                        backgroundColor: theme.error[600],
                      ),
                    );
                    return;
                  }

                  // Get current user's CP id
                  final profileAsync =
                      ref.read(currentCommunityProfileProvider);
                  String? cpId;
                  await profileAsync.when(
                    data: (p) async => cpId = p?.id,
                    loading: () async {},
                    error: (_, __) async {},
                  );
                  if (cpId == null || cpId!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(localizations
                            .translate('error-no-group-membership')),
                        backgroundColor: theme.error[600],
                      ),
                    );
                    return;
                  }

                  // Use group invite service via provider to attempt join
                  final groupService = ref.read(attachmentGroupServiceProvider);
                  final result = await groupService.joinGroupFromInvite(
                    groupId: groupId,
                    joinCode: joinCode,
                    joinerCpId: cpId!,
                    inviteId: inviteId,
                  );

                  if (result.success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(localizations
                            .translate('group-joined-successfully')),
                        backgroundColor: theme.success[600],
                      ),
                    );
                  } else {
                    final errorKey = (result.error ?? GroupJoinError.unknown)
                        .localizationKey;
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: theme.backgroundColor,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (_) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(LucideIcons.info, color: theme.grey[700]),
                                const SizedBox(width: 8),
                                Text(localizations.translate('group-invite'),
                                    style: TextStyles.h6),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              localizations.translate(errorKey),
                              style: TextStyles.body
                                  .copyWith(color: theme.grey[800]),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    );
                  }
                } catch (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(localizations.translate('generic_error')),
                      backgroundColor: theme.error[600],
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.success[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                localizations.translate('group-invite-join'),
                style: TextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
