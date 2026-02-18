import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/features/community/data/models/post.dart';
import 'package:reboot_app_3/features/community/presentation/providers/forum_providers.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';

/// Ultra-compact poll widget for feed display with inline voting
class CompactPollWidget extends ConsumerStatefulWidget {
  final Post post;
  final Map<String, dynamic> pollDoc;
  final CustomThemeData theme;
  final AppLocalizations localizations;

  const CompactPollWidget({
    super.key,
    required this.post,
    required this.pollDoc,
    required this.theme,
    required this.localizations,
  });

  @override
  ConsumerState<CompactPollWidget> createState() => _CompactPollWidgetState();
}

class _CompactPollWidgetState extends ConsumerState<CompactPollWidget> {
  Set<String> _selected = <String>{};
  bool _hasVoted = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadUserVote();
  }

  Future<void> _loadUserVote() async {
    try {
      final profileAsync = ref.read(currentCommunityProfileProvider);
      String? cpId;
      await profileAsync.when(
        data: (p) async => cpId = p?.id,
        loading: () async {},
        error: (_, __) async {},
      );

      if (cpId != null && cpId!.isNotEmpty) {
        final userVote = await ref
            .read(forumRepositoryProvider)
            .getUserPollVote(widget.post.id, widget.pollDoc['id'], cpId!);

        if (userVote != null) {
          setState(() {
            _selected = Set<String>.from(userVote['selectedOptionIds'] ?? []);
            _hasVoted = _selected.isNotEmpty;
          });
        }
      }
    } catch (e) {
      // Silent fail for feed
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.pollDoc['question'] ?? 'Poll';
    final List options = (widget.pollDoc['options'] ?? []) as List;
    final isMultiSelect =
        (widget.pollDoc['selectionMode'] ?? 'single') == 'multiple';
    final isClosed = widget.pollDoc['isClosed'] == true;
    final totalVotes = (widget.pollDoc['totalVotes'] ?? 0) as int;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.theme.primary[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.theme.primary[100]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poll question - ultra compact
          Row(
            children: [
              Icon(LucideIcons.barChart3,
                  size: 16, color: widget.theme.primary[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  question,
                  style: TextStyles.caption.copyWith(
                    color: widget.theme.primary[700],
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (totalVotes > 0)
                Text(
                  '$totalVotes',
                  style: TextStyles.tiny.copyWith(
                    color: widget.theme.primary[600],
                    fontSize: 10,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 4),

          // Compact options (max 3 shown)
          ...options.take(3).map((option) {
            final optionData = option as Map<String, dynamic>;
            final optionId = optionData['id'] as String;
            final optionText = optionData['text'] as String;
            final isSelected = _selected.contains(optionId);

            return GestureDetector(
              onTap: isClosed || _hasVoted
                  ? null
                  : () => _handleOptionTap(optionId, isMultiSelect),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? widget.theme.primary[100]
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      size: 14,
                      color: isSelected
                          ? widget.theme.primary[600]
                          : widget.theme.grey[400],
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        optionText,
                        style: TextStyles.tiny.copyWith(
                          color: widget.theme.grey[800],
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),

          // Vote/Voted status - ultra compact
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: _hasVoted
                ? Row(
                    children: [
                      Icon(Icons.check_circle,
                          size: 9, color: widget.theme.success[600]),
                      const SizedBox(width: 2),
                      Text(
                        widget.localizations.translate('poll-voted'),
                        style: TextStyles.tiny.copyWith(
                          color: widget.theme.success[600],
                          fontWeight: FontWeight.w500,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  )
                : _selected.isNotEmpty
                    ? SizedBox(
                        width: double.infinity,
                        height: 32,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submitVote,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.theme.primary[600],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3)),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 8,
                                  height: 8,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 1, color: Colors.white),
                                )
                              : Text(
                                  widget.localizations.translate('poll-vote'),
                                  style: TextStyles.tiny.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 9,
                                  ),
                                ),
                        ),
                      )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _handleOptionTap(String optionId, bool isMultiSelect) {
    if (_hasVoted) return;

    setState(() {
      if (isMultiSelect) {
        if (_selected.contains(optionId)) {
          _selected.remove(optionId);
        } else {
          _selected.add(optionId);
        }
      } else {
        _selected = {optionId};
      }
    });
  }

  Future<void> _submitVote() async {
    if (_selected.isEmpty || _submitting || _hasVoted) return;

    setState(() => _submitting = true);

    try {
      final profileAsync = ref.read(currentCommunityProfileProvider);
      String? cpId;
      await profileAsync.when(
        data: (p) async => cpId = p?.id,
        loading: () async {},
        error: (_, __) async {},
      );

      if (cpId != null && cpId!.isNotEmpty) {
        await ref.read(forumRepositoryProvider).createPollVote(
              postId: widget.post.id,
              pollId: widget.pollDoc['id'],
              cpId: cpId!,
              selectedOptionIds: _selected.toList(),
            );

        setState(() {
          _hasVoted = true;
          _submitting = false;
        });
      }
    } catch (e) {
      setState(() => _submitting = false);
    }
  }
}
