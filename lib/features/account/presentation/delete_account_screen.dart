import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';

import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/account/data/models/deletion_reason.dart';
import 'package:reboot_app_3/features/account/data/user_profile_notifier.dart';
import 'package:reboot_app_3/features/authentication/application/auth_service.dart';
import 'package:reboot_app_3/features/authentication/providers/account_status_provider.dart';
import 'package:reboot_app_3/features/plus/data/notifiers/subscription_notifier.dart';
import 'package:reboot_app_3/core/routing/app_startup.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  String? selectedReasonId;
  final TextEditingController _detailsController = TextEditingController();
  bool showDetails = false;
  bool isSubmitting = false;

  // Retention offer state
  bool _hasSkippedRetentionOffer = false;
  bool _hasClaimedRetentionReward = false;
  bool _isCheckingRetention = true;
  bool _isClaimingReward = false;

  @override
  void initState() {
    super.initState();
    _checkRetentionRewardStatus();
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _checkRetentionRewardStatus() async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('checkRetentionRewardStatus');
      final result = await callable.call();

      if (mounted) {
        setState(() {
          _hasClaimedRetentionReward = result.data['alreadyClaimed'] == true;
          _isCheckingRetention = false;
        });
      }
    } catch (e) {
      print('Error checking retention reward status: $e');
      if (mounted) {
        setState(() {
          _isCheckingRetention = false;
        });
      }
    }
  }

  Future<void> _claimRetentionReward() async {
    setState(() {
      _isClaimingReward = true;
    });

    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('claimRetentionReward');
      final result = await callable.call();

      if (mounted) {
        if (result.data['success'] == true) {
          getSuccessSnackBar(context, 'retention-reward-claimed');
          // Navigate back after successful claim
          Navigator.of(context).pop();
        } else if (result.data['alreadyClaimed'] == true) {
          setState(() {
            _hasClaimedRetentionReward = true;
          });
          getErrorSnackBar(context, 'retention-reward-already-claimed');
        }
      }
    } catch (e) {
      print('Error claiming retention reward: $e');
      if (mounted) {
        getErrorSnackBar(context, 'retention-reward-failed');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isClaimingReward = false;
        });
      }
    }
  }

  void _skipRetentionOffer() {
    setState(() {
      _hasSkippedRetentionOffer = true;
    });
  }

  bool _shouldShowRetentionOffer(bool hasActiveSubscription) {
    // Don't show if user has active subscription (they already have premium)
    if (hasActiveSubscription) return false;
    // Don't show if still checking
    if (_isCheckingRetention) return false;
    // Don't show if already claimed
    if (_hasClaimedRetentionReward) return false;
    // Don't show if user skipped
    if (_hasSkippedRetentionOffer) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final accountStatus = ref.watch(accountStatusProvider);
    final userProfileAsync = ref.watch(userProfileNotifierProvider);
    // Use hasActiveRenewingSubscription to allow users with cancelled subscriptions to proceed
    final hasActiveSubscription = ref.watch(hasActiveRenewingSubscriptionProvider);

    // Screen accessible regardless of account status; banners shown at top

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, 'delete-account', true, true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).translate('delete-account-info'),
                style: TextStyles.body,
              ),
              verticalSpace(Spacing.points8),
              WidgetsContainer(
                backgroundColor: theme.backgroundColor,
                borderSide: BorderSide(color: theme.primary[600]!, width: 0.25),
                boxShadow: Shadows.mainShadows,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OnboardingSection(
                      icon: LucideIcons.userX,
                      title: AppLocalizations.of(context)
                          .translate('delete-account-data'),
                      description: AppLocalizations.of(context)
                          .translate('delete-account-data-desc'),
                    ),
                    verticalSpace(Spacing.points16),
                    OnboardingSection(
                      icon: LucideIcons.fileStack,
                      title: AppLocalizations.of(context)
                          .translate('delete-account-followups'),
                      description: AppLocalizations.of(context)
                          .translate('delete-account-followups-desc'),
                    ),
                    verticalSpace(Spacing.points16),
                    OnboardingSection(
                      icon: LucideIcons.heart,
                      title: AppLocalizations.of(context)
                          .translate('delete-account-emotions'),
                      description: AppLocalizations.of(context)
                          .translate('delete-account-emotions-desc'),
                    ),
                    verticalSpace(Spacing.points16),
                    OnboardingSection(
                      icon: LucideIcons.activity,
                      title: AppLocalizations.of(context)
                          .translate('delete-account-activities'),
                      description: AppLocalizations.of(context)
                          .translate('delete-account-activities-desc'),
                    ),
                  ],
                ),
              ),
              verticalSpace(Spacing.points24),

              // Reason Selection Section
              Text(
                AppLocalizations.of(context).translate('deletion-reason-title'),
                style: TextStyles.h6.copyWith(color: theme.grey[900]),
              ),
              verticalSpace(Spacing.points8),
              Text(
                AppLocalizations.of(context)
                    .translate('deletion-reason-subtitle'),
                style: TextStyles.small.copyWith(color: theme.grey[600]),
              ),

              verticalSpace(Spacing.points16),

              // Show retention offer OR deletion flow
              if (_shouldShowRetentionOffer(hasActiveSubscription)) ...[
                // Retention Offer Section
                _buildRetentionOfferSection(theme),
              ] else ...[
                // Normal deletion flow

                // Reason Options
                ...DeletionReasons.reasons
                    .map((reason) => _buildReasonOption(reason, theme))
                    .toList(),

                // Details Text Field (conditional)
                if (showDetails) ...[
                  verticalSpace(Spacing.points16),
                  Text(
                    AppLocalizations.of(context)
                        .translate('deletion-reason-details'),
                    style: TextStyles.footnoteSelected
                        .copyWith(color: theme.grey[900]),
                  ),
                  verticalSpace(Spacing.points8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _detailsController,
                      maxLines: 3,
                      maxLength: 300,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)
                            .translate('deletion-reason-details-hint'),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                        hintStyle:
                            TextStyles.body.copyWith(color: theme.grey[500]),
                      ),
                      style: TextStyles.body.copyWith(color: theme.grey[900]),
                    ),
                  ),
                ],

                verticalSpace(Spacing.points16),

                // Subscription warning (if user has active subscription)
                if (hasActiveSubscription) ...[
                  WidgetsContainer(
                    backgroundColor: theme.warn[50],
                    borderSide: BorderSide(color: theme.warn[300]!, width: 1),
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.star,
                              color: theme.warn[600],
                              size: 24,
                            ),
                            horizontalSpace(Spacing.points12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)
                                        .translate('subscription-active-warning'),
                                    style: TextStyles.footnote.copyWith(
                                      color: theme.warn[800],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  verticalSpace(Spacing.points4),
                                  Text(
                                    AppLocalizations.of(context).translate(
                                        'subscription-active-warning-desc'),
                                    style: TextStyles.small.copyWith(
                                      color: theme.warn[700],
                                      height: 1.4,
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
                  verticalSpace(Spacing.points16),
                ],

                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)
                          .translate('delete-account-warning'),
                      style: TextStyles.body.copyWith(
                          color: theme.error[600], fontWeight: FontWeight.bold),
                    ),
                    verticalSpace(Spacing.points8),
                    Text(
                      AppLocalizations.of(context)
                          .translate('delete-account-final-warning'),
                      style: TextStyles.small.copyWith(
                        height: 1.75,
                        color: theme.error[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                verticalSpace(Spacing.points16),

                // Show "reconsider" link if user skipped the retention offer
                if (_hasSkippedRetentionOffer &&
                    !_hasClaimedRetentionReward &&
                    !hasActiveSubscription) ...[
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _hasSkippedRetentionOffer = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.primary[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.primary[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.gift,
                            color: theme.primary[600],
                            size: 18,
                          ),
                          horizontalSpace(Spacing.points8),
                          Flexible(
                            child: Text(
                              AppLocalizations.of(context)
                                  .translate('retention-offer-reconsider'),
                              style: TextStyles.small.copyWith(
                                color: theme.primary[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  verticalSpace(Spacing.points16),
                ],

                // Delete Button (enabled only if reason selected and no active subscription)
                Consumer(
                  builder: (context, ref, child) {
                    final hasActiveSubscription =
                        ref.watch(hasActiveRenewingSubscriptionProvider);
                    final reasonSelected = selectedReasonId != null &&
                        (!showDetails ||
                            _detailsController.text.trim().isNotEmpty);
                    final canDelete =
                        reasonSelected && !isSubmitting && !hasActiveSubscription;

                    return GestureDetector(
                      onTap: () {
                        if (hasActiveSubscription) {
                          _showSubscriptionBlockDialog(context);
                        } else if (reasonSelected && !isSubmitting) {
                          _showDeleteConfirmationDialog(context);
                        }
                      },
                      child: WidgetsContainer(
                        backgroundColor:
                            canDelete ? theme.error[600] : theme.grey[300],
                        width: MediaQuery.of(context).size.width - 32,
                        padding: EdgeInsets.all(16),
                        borderSide: BorderSide(
                            width: 0,
                            color:
                                canDelete ? theme.error[900]! : theme.grey[400]!),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isSubmitting) ...[
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    canDelete ? Colors.white : theme.grey[500]!,
                                  ),
                                ),
                              ),
                              horizontalSpace(Spacing.points8),
                            ] else ...[
                              Icon(
                                LucideIcons.userX,
                                color: canDelete ? Colors.white : theme.grey[500],
                                size: 20,
                              ),
                              horizontalSpace(Spacing.points8),
                            ],
                            Text(
                              AppLocalizations.of(context)
                                  .translate('delete-account'),
                              style: TextStyles.footnoteSelected.copyWith(
                                color: canDelete ? Colors.white : theme.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReasonOption(DeletionReason reason, dynamic theme) {
    final isSelected = selectedReasonId == reason.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedReasonId = reason.id;
          showDetails = reason.requiresDetails;
          if (!reason.requiresDetails) {
            _detailsController.clear();
          }
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        child: WidgetsContainer(
          backgroundColor:
              isSelected ? theme.primary[50] : theme.backgroundColor,
          borderSide: BorderSide(
            color: isSelected ? theme.primary[600]! : theme.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                color: isSelected ? theme.primary[600] : theme.grey[400],
                size: 20,
              ),
              horizontalSpace(Spacing.points12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).translate(reason.translationKey),
                  style: TextStyles.body.copyWith(
                    color: isSelected ? theme.primary[900] : theme.grey[900],
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRetentionOfferSection(dynamic theme) {
    return Column(
      children: [
        // Promotional offer card
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primary[600]!,
                theme.primary[700]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.primary[600]!.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gift icon and badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.gift,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  horizontalSpace(Spacing.points12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      AppLocalizations.of(context)
                          .translate('retention-offer-badge'),
                      style: TextStyles.small.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              verticalSpace(Spacing.points16),

              // Title
              Text(
                AppLocalizations.of(context)
                    .translate('retention-offer-title'),
                style: TextStyles.h5.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              verticalSpace(Spacing.points8),

              // Description
              Text(
                AppLocalizations.of(context)
                    .translate('retention-offer-description'),
                style: TextStyles.body.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  height: 1.5,
                ),
              ),
              verticalSpace(Spacing.points20),

              // Claim button
              GestureDetector(
                onTap: _isClaimingReward ? null : _claimRetentionReward,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isClaimingReward) ...[
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.primary[600]!,
                            ),
                          ),
                        ),
                        horizontalSpace(Spacing.points8),
                      ] else ...[
                        Icon(
                          LucideIcons.sparkles,
                          color: theme.primary[600],
                          size: 20,
                        ),
                        horizontalSpace(Spacing.points8),
                      ],
                      Text(
                        AppLocalizations.of(context)
                            .translate('retention-offer-claim-button'),
                        style: TextStyles.footnoteSelected.copyWith(
                          color: theme.primary[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        verticalSpace(Spacing.points24),

        // Skip link
        GestureDetector(
          onTap: _skipRetentionOffer,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              AppLocalizations.of(context)
                  .translate('retention-offer-skip'),
              style: TextStyles.small.copyWith(
                color: theme.grey[500],
                decoration: TextDecoration.underline,
                decorationColor: theme.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final theme = AppTheme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.backgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.all(24),
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
              verticalSpace(Spacing.points24),

              // Icon and title
              Row(
                children: [
                  Icon(
                    LucideIcons.alertTriangle,
                    color: theme.error[600],
                    size: 24,
                  ),
                  horizontalSpace(Spacing.points12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)
                          .translate('delete-account-confirmation-title'),
                      style: TextStyles.h5.copyWith(
                        color: theme.primary[900],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              verticalSpace(Spacing.points16),

              // Message
              Text(
                AppLocalizations.of(context)
                    .translate('delete-account-confirmation-message'),
                style: TextStyles.body.copyWith(
                  color: theme.grey[700],
                  height: 1.5,
                ),
              ),
              verticalSpace(Spacing.points32),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: WidgetsContainer(
                        backgroundColor: theme.backgroundColor,
                        borderSide:
                            BorderSide(color: theme.grey[400]!, width: 1),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context).translate('cancel'),
                            style: TextStyles.footnoteSelected.copyWith(
                              color: theme.grey[700],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  horizontalSpace(Spacing.points12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.of(context).pop();
                        await _createDeletionRequest(context, ref);
                      },
                      child: WidgetsContainer(
                        backgroundColor: theme.error[600],
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context)
                                .translate('delete-account'),
                            style: TextStyles.footnoteSelected.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Bottom padding for safe area
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createDeletionRequest(
      BuildContext context, WidgetRef ref) async {
    print('DEBUG: _createDeletionRequest called');
    if (selectedReasonId == null) {
      print('DEBUG: No reason selected, returning');
      return;
    }

    print('DEBUG: Setting isSubmitting to true');
    setState(() {
      isSubmitting = true;
    });

    try {
      print('DEBUG: Starting deletion request creation');
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final selectedReason = DeletionReasons.findById(selectedReasonId!);
      if (selectedReason == null) {
        throw Exception('Invalid deletion reason selected');
      }

      // Create request in accountDeleteRequests collection
      await FirebaseFirestore.instance.collection('accountDeleteRequests').add({
        'userId': user.uid,
        'userEmail': user.email ?? 'Unknown',
        'userName': user.displayName ?? 'Unknown',
        'requestedAt': FieldValue.serverTimestamp(),
        'reasonId': selectedReasonId,
        'reasonDetails': showDetails ? _detailsController.text.trim() : null,
        'reasonCategory': selectedReason.category,
        'isCanceled': false,
        'isProcessed': false,
      });

      // Update user document flag
      print('DEBUG: Updating user document flag isRequestedToBeDeleted = true');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'isRequestedToBeDeleted': true});
      print('DEBUG: User document updated successfully');

      print('DEBUG: Checking if context is mounted...');
      print('DEBUG: context.mounted = ${context.mounted}');

      if (context.mounted) {
        print(
            'DEBUG: Context is mounted, showing success message and signing out automatically');
        // Show success message about the deletion request
        getSuccessSnackBar(context, 'deletion-request-submitted');

        // Automatically sign out the user immediately
        try {
          print('DEBUG: Starting automatic sign out process');
          final authService = ref.read(authServiceProvider);
          print('DEBUG: Got authService: $authService');

          print('DEBUG: Calling authService.signOut()');
          await authService.signOut(context, ref);
          print('DEBUG: authService.signOut() completed');

          // Invalidate app startup to trigger redirect
          print('DEBUG: Invalidating appStartupProvider');
          ref.invalidate(appStartupProvider);
          print('DEBUG: appStartupProvider invalidated');

          // Show message about 30-day access and automatic sign out
          if (context.mounted) {
            print('DEBUG: Showing sign-out completion message');
            getSuccessSnackBar(context, 'signed-out-after-deletion');
          }

          print('DEBUG: Automatic sign out process completed successfully');
        } catch (e) {
          print('DEBUG: Error during automatic sign out: $e');
          print('DEBUG: Error type: ${e.runtimeType}');
          if (context.mounted) {
            getErrorSnackBar(context, 'sign-out-failed');
          }
        }
      } else {
        print(
            'DEBUG: Context is NOT mounted, but proceeding with sign-out anyway');

        // Even if context is not mounted, we should still sign out the user
        try {
          print('DEBUG: Starting sign out process without context check');
          final authService = ref.read(authServiceProvider);
          print('DEBUG: Got authService: $authService');

          print('DEBUG: Calling authService.signOut()');
          await authService.signOut(context, ref);
          print('DEBUG: authService.signOut() completed');

          // Invalidate app startup to trigger redirect
          print('DEBUG: Invalidating appStartupProvider');
          ref.invalidate(appStartupProvider);
          print('DEBUG: appStartupProvider invalidated');

          print('DEBUG: Sign out process completed successfully (no context)');
        } catch (e) {
          print('DEBUG: Error during sign out (no context): $e');
          print('DEBUG: Error type: ${e.runtimeType}');
        }
      }
    } catch (e) {
      if (context.mounted) {
        getErrorSnackBar(context, 'deletion-request-failed');
      }
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  void _showSubscriptionBlockDialog(BuildContext context) {
    final theme = AppTheme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: theme.backgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.star,
                      color: theme.warn[600],
                      size: 24,
                    ),
                    horizontalSpace(Spacing.points12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)
                            .translate('subscription-active-title'),
                        style: TextStyles.h6.copyWith(
                          color: theme.grey[900],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                verticalSpace(Spacing.points16),
                Text(
                  AppLocalizations.of(context)
                      .translate('subscription-active-message'),
                  style: TextStyles.body.copyWith(
                    color: theme.grey[700],
                    height: 1.5,
                  ),
                ),
                verticalSpace(Spacing.points24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      AppLocalizations.of(context).translate('understood'),
                      style: TextStyles.footnote.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class OnboardingSection extends ConsumerWidget {
  const OnboardingSection(
      {super.key,
      required this.icon,
      required this.title,
      required this.description});

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    return Container(
      padding: EdgeInsets.only(right: 16, left: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: theme.error[600],
            weight: 100,
          ),
          horizontalSpace(Spacing.points16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyles.h6.copyWith(
                    color: theme.error[600],
                  ),
                ),
                verticalSpace(Spacing.points8),
                Text(
                  description,
                  style: TextStyles.small.copyWith(
                    color: theme.grey[900],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
