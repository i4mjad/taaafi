import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';

class PendingDeletionBanner extends ConsumerStatefulWidget {
  const PendingDeletionBanner({super.key, this.isFullScreen = false});

  final bool isFullScreen;

  @override
  ConsumerState<PendingDeletionBanner> createState() =>
      _PendingDeletionBannerState();
}

class _PendingDeletionBannerState extends ConsumerState<PendingDeletionBanner> {
  bool isProcessing = false;
  DateTime? deletionDate;

  @override
  void initState() {
    super.initState();
    _loadDeletionDate();
  }

  Future<void> _loadDeletionDate() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final requestQuery = await FirebaseFirestore.instance
            .collection('accountDeleteRequests')
            .where('userId', isEqualTo: user.uid)
            .where('isCanceled', isEqualTo: false)
            .orderBy('requestedAt', descending: true)
            .limit(1)
            .get();

        if (requestQuery.docs.isNotEmpty) {
          final requestData = requestQuery.docs.first.data();
          final requestedAt = requestData['requestedAt'] as Timestamp?;
          if (requestedAt != null) {
            setState(() {
              deletionDate = requestedAt.toDate().add(const Duration(days: 30));
            });
          }
        }
      }
    } catch (e) {
      print('Error loading deletion date: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final locale = ref.watch(localeNotifierProvider);

    return WidgetsContainer(
      backgroundColor: theme.backgroundColor,
      borderSide: widget.isFullScreen
          ? BorderSide.none
          : BorderSide(color: theme.error[200]!, width: 1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning icon and message
            Row(
              children: [
                Icon(
                  LucideIcons.userX,
                  color: theme.error[600],
                  size: 24,
                ),
                horizontalSpace(Spacing.points12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)
                            .translate('account-deletion-pending'),
                        style: TextStyles.footnote.copyWith(
                          color: theme.error[800],
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      verticalSpace(Spacing.points4),
                      Text(
                        AppLocalizations.of(context)
                            .translate('account-deletion-pending-subtitle'),
                        style: TextStyles.small.copyWith(
                          color: theme.grey[600],
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            verticalSpace(Spacing.points16),

            // Information box
            WidgetsContainer(
              backgroundColor: theme.warn[50],
              borderSide: BorderSide(color: theme.warn[200]!, width: 1),
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.info,
                    color: theme.warn[600],
                    size: 16,
                  ),
                  horizontalSpace(Spacing.points8),
                  Expanded(
                    child: Text(
                      deletionDate != null
                          ? "${AppLocalizations.of(context).translate('account-deletion-scheduled')} ${getDisplayDate(deletionDate!, locale!.languageCode)}. ${AppLocalizations.of(context).translate('account-deletion-continue-using')}"
                          : AppLocalizations.of(context)
                              .translate('account-deletion-process-info'),
                      style: TextStyles.small.copyWith(
                        color: theme.warn[800],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            verticalSpace(Spacing.points16),

            // Cancel deletion button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    isProcessing ? null : () => _cancelDeletionRequest(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.success[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isProcessing) ...[
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      horizontalSpace(Spacing.points8),
                    ] else ...[
                      Icon(
                        LucideIcons.x,
                        size: 16,
                        color: Colors.white,
                      ),
                      horizontalSpace(Spacing.points8),
                    ],
                    Text(
                      AppLocalizations.of(context).translate(
                          isProcessing ? 'processing' : 'cancel-deletion'),
                      style: TextStyles.footnote.copyWith(
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
      ),
    );
  }

  Future<void> _cancelDeletionRequest(BuildContext context) async {
    // Show confirmation dialog first
    final shouldCancel = await _showCancelConfirmationDialog(context);
    if (!shouldCancel) return;

    setState(() {
      isProcessing = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Update user document flag
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'isRequestedToBeDeleted': false});

      // Mark request as canceled (find active requests for this user)
      final requestQuery = await FirebaseFirestore.instance
          .collection('accountDeleteRequests')
          .where('userId', isEqualTo: user.uid)
          .where('isCanceled', isEqualTo: false)
          .get();

      if (requestQuery.docs.isNotEmpty) {
        // Cancel the most recent request (or all active requests)
        final batch = FirebaseFirestore.instance.batch();

        for (final doc in requestQuery.docs) {
          batch.update(doc.reference, {
            'isCanceled': true,
            'canceledAt': FieldValue.serverTimestamp(),
          });
        }

        await batch.commit();
      }

      // Refresh the user document to update account status
      ref.invalidate(userDocumentsNotifierProvider);

      if (context.mounted) {
        getSuccessSnackBar(context, 'deletion-canceled-successfully');
      }
    } catch (e) {
      print('Error canceling deletion request: $e');
      if (context.mounted) {
        getErrorSnackBar(context, 'deletion-cancel-failed');
      }
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Future<bool> _showCancelConfirmationDialog(BuildContext context) async {
    final theme = AppTheme.of(context);
    final locale = ref.watch(localeNotifierProvider);

    return await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) {
            return Container(
              decoration: BoxDecoration(
                color: theme.backgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  verticalSpace(Spacing.points20),

                  // Title with icon
                  Row(
                    children: [
                      Icon(
                        LucideIcons.checkCircle,
                        color: theme.success[600],
                        size: 24,
                      ),
                      horizontalSpace(Spacing.points8),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)
                              .translate('cancel-deletion-confirmation-title'),
                          style: TextStyles.h6.copyWith(
                            color: theme.grey[900],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  verticalSpace(Spacing.points16),

                  // Message content
                  Text(
                    deletionDate != null
                        ? "${AppLocalizations.of(context).translate('cancel-deletion-confirmation-message')} ${AppLocalizations.of(context).translate('account-accessible-until')} ${getDisplayDate(deletionDate!, locale!.languageCode)}."
                        : AppLocalizations.of(context)
                            .translate('cancel-deletion-confirmation-message'),
                    style: TextStyles.body.copyWith(
                      color: theme.grey[700],
                      height: 1.5,
                    ),
                  ),
                  verticalSpace(Spacing.points24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: theme.success[600]!),
                            foregroundColor: theme.success[600],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            AppLocalizations.of(context)
                                .translate('no-keep-request'),
                            style: TextStyles.footnote.copyWith(
                              color: theme.success[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      horizontalSpace(Spacing.points12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.success[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            AppLocalizations.of(context)
                                .translate('yes-cancel-deletion'),
                            style: TextStyles.footnote.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ) ??
        false;
  }
}
