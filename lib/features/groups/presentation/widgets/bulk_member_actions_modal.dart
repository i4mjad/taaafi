import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/groups/application/groups_providers.dart';
import 'package:reboot_app_3/features/groups/domain/entities/bulk_operation_result.dart';

/// Modal for performing bulk operations on selected group members
/// Sprint 2 - Feature 2.2: Bulk Member Management
class BulkMemberActionsModal extends ConsumerStatefulWidget {
  final String groupId;
  final List<String> selectedCpIds;
  final String currentUserCpId;
  final String groupCreatorCpId;
  final VoidCallback onComplete;

  const BulkMemberActionsModal({
    super.key,
    required this.groupId,
    required this.selectedCpIds,
    required this.currentUserCpId,
    required this.groupCreatorCpId,
    required this.onComplete,
  });

  @override
  ConsumerState<BulkMemberActionsModal> createState() => _BulkMemberActionsModalState();
}

class _BulkMemberActionsModalState extends ConsumerState<BulkMemberActionsModal> {
  bool _isProcessing = false;
  BulkOperationResult? _result;
  String? _errorMessage;

  Future<void> _performBulkPromotion() async {
    final l10n = AppLocalizations.of(context);
    
    // Confirm action
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('confirm')),
        content: Text(
          l10n
              .translate('confirm-bulk-promote')
              .replaceAll('{count}', '${widget.selectedCpIds.length}'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.translate('confirm')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(groupsRepositoryProvider);
      final result = await repository.bulkPromoteMembersToAdmin(
        groupId: widget.groupId,
        adminCpId: widget.currentUserCpId,
        memberCpIds: widget.selectedCpIds,
      );

      setState(() {
        _result = result;
        _isProcessing = false;
      });

      // Auto-close and refresh after showing result briefly
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        widget.onComplete();
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isProcessing = false;
      });
    }
  }

  Future<void> _performBulkRemoval() async {
    final l10n = AppLocalizations.of(context);
    
    // Confirm action
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('confirm')),
        content: Text(
          l10n
              .translate('confirm-bulk-remove')
              .replaceAll('{count}', '${widget.selectedCpIds.length}'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.translate('remove')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(groupsRepositoryProvider);
      final result = await repository.bulkRemoveMembers(
        groupId: widget.groupId,
        adminCpId: widget.currentUserCpId,
        memberCpIds: widget.selectedCpIds,
      );

      setState(() {
        _result = result;
        _isProcessing = false;
      });

      // Auto-close and refresh after showing result briefly
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        widget.onComplete();
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(LucideIcons.zap, size: 24, color: theme.primary[600]),
              horizontalSpace(Spacing.points8),
              Text(
                l10n.translate('bulk-actions'),
                style: TextStyles.h5.copyWith(color: theme.grey[900]),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(LucideIcons.x, size: 20, color: theme.grey[600]),
              ),
            ],
          ),

          verticalSpace(Spacing.points16),

          // Show processing state
          if (_isProcessing) ...[
            WidgetsContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spinner(),
                  verticalSpace(Spacing.points16),
                  Text(
                    l10n.translate('processing'),
                    style: TextStyles.body.copyWith(color: theme.grey[700]),
                  ),
                ],
              ),
            ),
          ]
          // Show result
          else if (_result != null) ...[
            WidgetsContainer(
              padding: const EdgeInsets.all(20),
              backgroundColor: _result!.allSucceeded ? theme.success[50] : theme.warning[50],
              borderSide: BorderSide(
                color: _result!.allSucceeded ? theme.success[300]! : theme.warning[300]!,
                width: 1,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _result!.allSucceeded ? LucideIcons.checkCircle2 : LucideIcons.alertTriangle,
                        size: 24,
                        color: _result!.allSucceeded ? theme.success[600] : theme.warning[600],
                      ),
                      horizontalSpace(Spacing.points12),
                      Expanded(
                        child: Text(
                          l10n.translate('bulk-operation-complete'),
                          style: TextStyles.h6.copyWith(
                            color: _result!.allSucceeded ? theme.success[800] : theme.warning[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  verticalSpace(Spacing.points12),
                  Text(
                    l10n
                        .translate('bulk-success-summary')
                        .replaceAll('{successCount}', '${_result!.successCount}')
                        .replaceAll('{failureCount}', '${_result!.failureCount}'),
                    style: TextStyles.body.copyWith(
                      color: _result!.allSucceeded ? theme.success[700] : theme.warning[700],
                    ),
                  ),
                  // Show failures if any
                  if (_result!.hasFailures) ...[
                    verticalSpace(Spacing.points12),
                    Text(
                      l10n.translate('bulk-failures-title'),
                      style: TextStyles.footnote.copyWith(
                        color: theme.error[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    verticalSpace(Spacing.points4),
                    for (int i = 0; i < _result!.failedCpIds.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '• ${_result!.failedCpIds[i]}: ${_result!.failureReasons[i]}',
                          style: TextStyles.small.copyWith(
                            color: theme.error[600],
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ]
          // Show error
          else if (_errorMessage != null) ...[
            WidgetsContainer(
              padding: const EdgeInsets.all(20),
              backgroundColor: theme.error[50],
              borderSide: BorderSide(color: theme.error[300]!, width: 1),
              child: Row(
                children: [
                  Icon(LucideIcons.alertCircle, size: 24, color: theme.error[600]),
                  horizontalSpace(Spacing.points12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyles.body.copyWith(color: theme.error[700]),
                    ),
                  ),
                ],
              ),
            ),
          ]
          // Show action buttons
          else ...[
            // Selected count info
            WidgetsContainer(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(LucideIcons.users, size: 20, color: theme.grey[600]),
                  horizontalSpace(Spacing.points8),
                  Text(
                    l10n
                        .translate('selected-count')
                        .replaceAll('{count}', '${widget.selectedCpIds.length}'),
                    style: TextStyles.body.copyWith(
                      color: theme.grey[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            verticalSpace(Spacing.points16),

            // Action: Promote to Admin
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _performBulkPromotion,
                icon: Icon(LucideIcons.crown, size: 18),
                label: Text(l10n.translate('bulk-promote')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary[500],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            verticalSpace(Spacing.points12),

            // Action: Remove from Group
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _performBulkRemoval,
                icon: Icon(LucideIcons.userX, size: 18),
                label: Text(l10n.translate('bulk-remove')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.error[50],
                  foregroundColor: theme.error[600],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: theme.error[300]!, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            verticalSpace(Spacing.points12),

            // Cancel button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.grey[700],
                  side: BorderSide(color: theme.grey[300]!, width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(l10n.translate('cancel')),
              ),
            ),
          ],

          verticalSpace(Spacing.points8),
        ],
      ),
    );
  }
}

