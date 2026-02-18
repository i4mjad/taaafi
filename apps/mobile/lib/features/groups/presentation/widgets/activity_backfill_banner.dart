import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/features/groups/application/member_activity_backfill_service.dart';
import 'package:reboot_app_3/features/groups/domain/entities/group_membership_entity.dart';
import 'package:reboot_app_3/features/groups/providers/group_achievements_provider.dart';

/// Banner prompting user to backfill their activity data
/// 
/// Shows when user has no tracked activity (messageCount = 0, lastActiveAt = null)
/// but may have historical messages
/// 
/// Once clicked and backfilled, this banner automatically disappears
class ActivityBackfillBanner extends ConsumerStatefulWidget {
  final String groupId;
  final GroupMembershipEntity membership;
  final VoidCallback? onBackfillComplete;

  const ActivityBackfillBanner({
    super.key,
    required this.groupId,
    required this.membership,
    this.onBackfillComplete,
  });

  @override
  ConsumerState<ActivityBackfillBanner> createState() => _ActivityBackfillBannerState();
}

class _ActivityBackfillBannerState extends ConsumerState<ActivityBackfillBanner> {
  bool _isProcessing = false;
  String? _errorMessage;

  /// Check if backfill is needed
  /// 
  /// Always show if messageCount = 0, because:
  /// - New members who never sent messages: button will just confirm 0 messages
  /// - Old members who rejoined: will count their historical messages
  /// - Members with untracked messages: will backfill properly
  bool get _needsBackfill {
    // Show whenever messageCount is 0
    // The Cloud Function will handle checking if there are actual historical messages
    return widget.membership.messageCount == 0;
  }

  Future<void> _handleBackfill() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(memberActivityBackfillServiceProvider);
      final result = await service.backfillMyActivity(widget.groupId);

      if (mounted) {
        // Show success message with proper localization
        getSuccessSnackBar(context, 'activity-backfill-success');

        // Invalidate achievements provider to reload fresh data
        ref.invalidate(memberAchievementsProvider((
          groupId: widget.groupId,
          cpId: widget.membership.cpId,
        )));

        // Notify parent to refresh data
        widget.onBackfillComplete?.call();
      }

    } on BackfillException catch (e) {
      if (mounted) {
        // Map error code to localization key
        String errorKey = _getErrorLocalizationKey(e.code);
        
        setState(() {
          _errorMessage = AppLocalizations.of(context).translate(errorKey);
        });

        // Show error snackbar with proper localization
        getErrorSnackBar(context, errorKey);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// Map error codes to localization keys
  String _getErrorLocalizationKey(String code) {
    switch (code) {
      case 'unauthenticated':
        return 'error-unauthenticated';
      case 'not-found':
        return 'error-not-group-member';
      case 'permission-denied':
        return 'error-permission-denied';
      case 'invalid-argument':
        return 'error-invalid-request';
      case 'internal':
        return 'error-backfill-internal';
      default:
        return 'error-something-went-wrong';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show if backfill not needed
    if (!_needsBackfill) {
      return const SizedBox.shrink();
    }

    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.tint[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.tint[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(
                LucideIcons.sparkles,
                size: 20,
                color: theme.tint[600],
              ),
              horizontalSpace(Spacing.points8),
              Expanded(
                child: Text(
                  l10n.translate('new-activity-tracking'),
                  style: TextStyles.h6.copyWith(
                    color: theme.grey[900],
                  ),
                ),
              ),
            ],
          ),

          verticalSpace(Spacing.points8),

          // Description
          Text(
            l10n.translate('activity-tracking-description'),
            style: TextStyles.body.copyWith(
              color: theme.grey[700],
              height: 1.4,
            ),
          ),

          // Error message if any
          if (_errorMessage != null) ...[
            verticalSpace(Spacing.points8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.error[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.alertCircle,
                    size: 14,
                    color: theme.error[600],
                  ),
                  horizontalSpace(Spacing.points8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyles.caption.copyWith(
                        color: theme.error[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          verticalSpace(Spacing.points12),

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _handleBackfill,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.tint[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isProcessing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        horizontalSpace(Spacing.points8),
                        Text(
                          l10n.translate('processing'),
                          style: TextStyles.body.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.refreshCw,
                          size: 16,
                          color: Colors.white,
                        ),
                        horizontalSpace(Spacing.points8),
                        Text(
                          l10n.translate('load-my-activity'),
                          style: TextStyles.body.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

