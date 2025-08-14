import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/presentation/providers/forum_providers.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/community/presentation/forum/anonymity_toggle_modal.dart';
import 'package:reboot_app_3/features/community/data/models/comment.dart';
import 'package:reboot_app_3/features/account/presentation/widgets/feature_access_guard.dart';
import 'package:reboot_app_3/features/account/data/app_features_config.dart';

class ReplyInputWidget extends ConsumerStatefulWidget {
  final String postId;
  final String? replyingToUsername;
  final String? parentFor;
  final String? parentId;
  final Comment? replyToComment;
  final VoidCallback? onReplySubmitted;
  final VoidCallback? onCancelReply;
  final bool hideReplyContext; // New parameter to hide reply context

  const ReplyInputWidget({
    super.key,
    required this.postId,
    this.replyingToUsername,
    this.parentFor,
    this.parentId,
    this.replyToComment,
    this.onReplySubmitted,
    this.onCancelReply,
    this.hideReplyContext = false,
  });

  @override
  ConsumerState<ReplyInputWidget> createState() => _ReplyInputWidgetState();
}

class _ReplyInputWidgetState extends ConsumerState<ReplyInputWidget> {
  final TextEditingController _replyController = TextEditingController();
  bool _isSubmitting = false;

  /// Helper function to localize special display name constants
  String _getLocalizedDisplayName(
      String displayName, AppLocalizations localizations) {
    switch (displayName) {
      case 'DELETED_USER':
        return localizations.translate('community-deleted-user');
      case 'ANONYMOUS_USER':
        return localizations.translate('community-anonymous');
      default:
        return displayName;
    }
  }

  @override
  void initState() {
    super.initState();
    _replyController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final currentProfileAsync = ref.watch(currentCommunityProfileProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Reply context section

        // Main input widget
        WidgetsContainer(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          backgroundColor: theme.postInputBackgound,
          borderSide: BorderSide(color: theme.grey[300]!, width: 0.5),
          borderRadius: BorderRadius.circular(12.5),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                if (widget.replyToComment != null &&
                    !widget.hideReplyContext) ...[
                  _buildReplyContext(
                      theme, localizations, widget.replyToComment!),
                  verticalSpace(Spacing.points8)
                ],
                Row(
                  children: [
                    // User avatar with profile state handling
                    currentProfileAsync.when(
                      data: (profile) {
                        final isAnonymous = profile?.isAnonymous ?? false;
                        return profile != null
                            ? _buildUserAvatar(
                                context, theme, profile, isAnonymous)
                            : _buildFallbackAvatar(context, theme, isAnonymous);
                      },
                      loading: () => Consumer(
                        builder: (context, ref, child) {
                          final profileAsync =
                              ref.watch(currentCommunityProfileProvider);
                          final isAnonymous = profileAsync.maybeWhen(
                            data: (profile) => profile?.isAnonymous ?? false,
                            orElse: () => false,
                          );
                          return _buildFallbackAvatar(
                              context, theme, isAnonymous);
                        },
                      ),
                      error: (_, __) => Consumer(
                        builder: (context, ref, child) {
                          final profileAsync =
                              ref.watch(currentCommunityProfileProvider);
                          final isAnonymous = profileAsync.maybeWhen(
                            data: (profile) => profile?.isAnonymous ?? false,
                            orElse: () => false,
                          );
                          return _buildFallbackAvatar(
                              context, theme, isAnonymous);
                        },
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Reply input
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        enabled: !_isSubmitting,
                        maxLines: null,
                        minLines: 1,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: _getHintText(localizations),
                          hintStyle: TextStyles.caption.copyWith(
                            color: theme.grey[700],
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        style: TextStyles.body.copyWith(
                          color: theme.grey[900],
                          fontSize: 14,
                        ),
                        onSubmitted: _handleSubmit,
                      ),
                    ),

                    // Send button
                    if (_replyController.text.isNotEmpty || _isSubmitting) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _isSubmitting
                            ? null
                            : () => _handleSubmit(_replyController.text),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isSubmitting
                                ? theme.grey[400]
                                : theme.primary[600],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: _isSubmitting
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: Spinner(
                                        strokeWidth: 2,
                                        valueColor: theme.grey[100]!,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      localizations.translate('send'),
                                      style: TextStyles.caption.copyWith(
                                        color: theme.grey[100],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.send,
                                      size: 14,
                                      color: theme.grey[100],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      localizations.translate('send'),
                                      style: TextStyles.caption.copyWith(
                                        color: theme.grey[100],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReplyContext(
    dynamic theme,
    AppLocalizations localizations,
    Comment comment,
  ) {
    return WidgetsContainer(
      padding: const EdgeInsets.all(16),
      backgroundColor: theme.grey[50],
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(15),
        topRight: Radius.circular(15),
      ),
      child: Row(
        children: [
          // Reply icon
          Icon(
            Icons.reply,
            size: 20,
            color: theme.grey[600],
          ),

          const SizedBox(width: 12),

          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author name
                Consumer(
                  builder: (context, ref, child) {
                    final currentProfileAsync =
                        ref.watch(currentCommunityProfileProvider);
                    final isAnonymous = currentProfileAsync.maybeWhen(
                      data: (profile) => profile?.isAnonymous ?? false,
                      orElse: () => false,
                    );

                    // Get the comment author's profile to display their name
                    final authorProfileAsync = ref.watch(
                        communityProfileByIdProvider(comment.authorCPId));

                    return authorProfileAsync.when(
                      data: (authorProfile) {
                        final displayName = _getLocalizedDisplayName(
                          authorProfile.getDisplayNameWithPipeline(),
                          localizations,
                        );

                        return Text(
                          displayName,
                          style: TextStyles.footnoteSelected.copyWith(
                            color: theme.grey[700],
                            fontSize: 12,
                          ),
                        );
                      },
                      loading: () => Text(
                        'Loading...',
                        style: TextStyles.footnoteSelected.copyWith(
                          color: theme.grey[700],
                          fontSize: 12,
                        ),
                      ),
                      error: (error, stackTrace) => Text(
                        'Unknown User',
                        style: TextStyles.footnoteSelected.copyWith(
                          color: theme.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 4),

                // Comment body (truncated)
                Text(
                  comment.body.length > 100
                      ? '${comment.body.substring(0, 100)}...'
                      : comment.body,
                  style: TextStyles.caption.copyWith(
                    color: theme.grey[600],
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Cancel reply button
          GestureDetector(
            onTap: widget.onCancelReply,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.close,
                size: 16,
                color: theme.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(
    BuildContext context,
    dynamic theme,
    dynamic profile,
    bool isAnonymous,
  ) {
    final user = FirebaseAuth.instance.currentUser;
    final userImageUrl = user?.photoURL;

    return GestureDetector(
      onTap: () => _showAnonymityToggleModal(context, profile, isAnonymous),
      child: CircleAvatar(
        radius: 14,
        backgroundColor: theme.primary[100],
        backgroundImage: isAnonymous || userImageUrl == null
            ? null
            : NetworkImage(userImageUrl),
        child: isAnonymous || userImageUrl == null
            ? Icon(
                isAnonymous ? Icons.person_outline : Icons.person,
                size: 18,
                color: theme.primary[700],
              )
            : null,
      ),
    );
  }

  Widget _buildFallbackAvatar(
    BuildContext context,
    dynamic theme,
    bool isAnonymous,
  ) {
    return GestureDetector(
      onTap: () {
        // Simple toggle for fallback - no modal since no profile
        ref.read(anonymousPostProvider.notifier).state = !isAnonymous;
      },
      child: CircleAvatar(
        radius: 14,
        backgroundColor: theme.primary[100],
        child: Text(
          'T',
          style: TextStyles.caption.copyWith(
            color: theme.primary[700],
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  String _getHintText(AppLocalizations localizations) {
    if (widget.replyingToUsername != null) {
      return localizations
          .translate('reply_to_user')
          .replaceAll('{user}', widget.replyingToUsername!);
    }
    return localizations.translate('add_comment');
  }

  Future<void> _handleSubmit(String text) async {
    if (text.trim().isEmpty || _isSubmitting) return;

    // Show loader immediately so the user gets instant feedback
    setState(() {
      _isSubmitting = true;
    });

    // Give the UI a chance to rebuild before heavy async work starts
    await Future.delayed(Duration.zero);

    // Double-check feature access before submitting
    final canAccess =
        await checkFeatureAccess(ref, AppFeaturesConfig.commentCreation);
    if (!canAccess) {
      // Reset loader when access is denied
      setState(() {
        _isSubmitting = false;
      });
      getErrorSnackBar(
        context,
        'comment-creation-restricted',
      );
      return;
    }

    try {
      // Get current user's community profile to determine anonymity
      final currentProfileAsync = ref.read(currentCommunityProfileProvider);
      final isAnonymous = currentProfileAsync.maybeWhen(
        data: (profile) => profile?.isAnonymous ?? false,
        orElse: () => false,
      );

      await ref.read(addCommentProvider(widget.postId).notifier).addComment(
            body: text.trim(),
            parentFor: widget.parentFor,
            parentId: widget.parentId,
            isAnonymous: isAnonymous,
          );

      // Clear the input
      _replyController.clear();

      // Call the callback if provided
      widget.onReplySubmitted?.call();

      // Show success message
      if (mounted) {
        getSuccessSnackBar(context, "comment_added");
      }
    } catch (error) {
      // Show error message
      if (mounted) {
        getErrorSnackBar(context, "error_adding_comment");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showAnonymityToggleModal(
    BuildContext context,
    dynamic profile,
    bool currentAnonymousState,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AnonymityToggleModal(
        profile: profile,
        currentAnonymousState: currentAnonymousState,
        onToggleComplete: (newAnonymityState) {
          // Update the anonymousPostProvider with the new state
          ref.read(anonymousPostProvider.notifier).state = newAnonymityState;
          // Also refresh the community profile to get the updated setting
          ref.refresh(currentCommunityProfileProvider);
        },
      ),
    );
  }
}
