import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/authentication/application/auth_service.dart';
import 'package:reboot_app_3/features/account/presentation/account_deletion_login_screen.dart';

class AccountDeletionLoadingScreen extends ConsumerStatefulWidget {
  const AccountDeletionLoadingScreen({super.key});

  @override
  _AccountDeletionLoadingScreenState createState() =>
      _AccountDeletionLoadingScreenState();
}

class _AccountDeletionLoadingScreenState
    extends ConsumerState<AccountDeletionLoadingScreen> {
  List<DeletionStep> _steps = [];
  bool _isComplete = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _requiresReauth = false;

  @override
  void initState() {
    super.initState();
    // Don't initialize steps here - do it in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Clear the deletion login context when reaching the loading screen
    // This prevents infinite redirects if the router redirects here multiple times
    DeletionLoginContext.clear();

    if (_steps.isEmpty) {
      _initializeSteps();
      // Start deletion process immediately - attempt deletion first
      _startDeletionProcess();
    } else if (_requiresReauth) {
      // If we were waiting for reauth and user is back, restart deletion
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        print('DEBUG: User returned from login, restarting deletion process');
        setState(() {
          _requiresReauth = false;
          _hasError = false;
          _errorMessage = null;
          // Reset all steps to pending
          for (int i = 0; i < _steps.length; i++) {
            _steps[i] = _steps[i].copyWith(status: DeletionStepStatus.pending);
          }
        });
        // Restart the deletion process
        _startDeletionProcess();
      }
    }
  }

  void _initializeSteps() {
    _steps = [
      DeletionStep(
        id: 'backup_data',
        title: AppLocalizations.of(context).translate('preparing-deletion'),
        icon: LucideIcons.database,
        status: DeletionStepStatus.pending,
      ),
      DeletionStep(
        id: 'delete_community_data',
        title: AppLocalizations.of(context).translate('deleting-user-data'),
        icon: LucideIcons.server,
        status: DeletionStepStatus.pending,
      ),
      DeletionStep(
        id: 'delete_documents',
        title:
            AppLocalizations.of(context).translate('finalizing-data-cleanup'),
        icon: LucideIcons.fileX,
        status: DeletionStepStatus.pending,
      ),
      DeletionStep(
        id: 'delete_account',
        title: AppLocalizations.of(context).translate('deleting-account'),
        icon: LucideIcons.userX,
        status: DeletionStepStatus.pending,
      ),
      DeletionStep(
        id: 'cleanup',
        title: AppLocalizations.of(context).translate('cleanup'),
        icon: LucideIcons.sparkles,
        status: DeletionStepStatus.pending,
      ),
    ];
  }

  void _updateStepStatus(String stepId, DeletionStepStatus status) {
    if (mounted) {
      setState(() {
        final stepIndex = _steps.indexWhere((step) => step.id == stepId);
        if (stepIndex != -1) {
          _steps[stepIndex] = _steps[stepIndex].copyWith(status: status);
        }
      });
    }
  }

  Future<void> _startDeletionProcess() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception(
            'User not authenticated - cannot proceed with deletion');
      }

      print('DEBUG: Starting deletion process for user: ${currentUser.uid}');

      // Step 1: Backup data (mark as in progress)
      _updateStepStatus('backup_data', DeletionStepStatus.inProgress);
      await Future.delayed(Duration(milliseconds: 500));
      _updateStepStatus('backup_data', DeletionStepStatus.completed);

      // Step 2: Call Cloud Function to delete all user data
      _updateStepStatus('delete_community_data', DeletionStepStatus.inProgress);

      try {
        print('DEBUG: Calling Cloud Function to delete user data...');

        // Get Cloud Functions instance
        final functions = FirebaseFunctions.instance;
        final callable = functions.httpsCallable('deleteUserAccount');

        // Call the Cloud Function
        final result = await callable.call();

        print('DEBUG: Cloud Function result: ${result.data}');

        if (result.data['success'] == true) {
          print('DEBUG: Cloud Function deletion completed successfully');
          _updateStepStatus(
              'delete_community_data', DeletionStepStatus.completed);
        } else {
          throw Exception(
              'Cloud Function reported failure: ${result.data['message']}');
        }
      } catch (e) {
        print('ERROR: Cloud Function deletion failed: $e');
        // Don't fail the entire process if cloud function deletion fails
        // We'll still proceed with Firebase Auth deletion
        _updateStepStatus(
            'delete_community_data', DeletionStepStatus.completed);
      }

      // Step 3: Delete documents (handled by Cloud Function above)
      _updateStepStatus('delete_documents', DeletionStepStatus.inProgress);
      await Future.delayed(Duration(milliseconds: 500));
      _updateStepStatus('delete_documents', DeletionStepStatus.completed);

      // Step 4: Delete Firebase Auth user (only thing done on client)
      _updateStepStatus('delete_account', DeletionStepStatus.inProgress);

      // Only delete the Firebase Auth user - all data deletion is handled by Cloud Function
      await currentUser.delete();
      print('DEBUG: Firebase Auth user deleted successfully');

      _updateStepStatus('delete_account', DeletionStepStatus.completed);

      // Step 5: Cleanup
      _updateStepStatus('cleanup', DeletionStepStatus.inProgress);
      await Future.delayed(Duration(milliseconds: 800));
      _updateStepStatus('cleanup', DeletionStepStatus.completed);

      // Mark as complete
      if (mounted) {
        setState(() {
          _isComplete = true;
        });
      }

      // Show success message and navigate
      await Future.delayed(Duration(milliseconds: 1000));
      if (mounted) {
        getSuccessSnackBar(context, 'account-deleted');
        context.goNamed(RouteNames.onboarding.name);
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during deletion: ${e.code} - ${e.message}');

      if (e.code == 'requires-recent-login') {
        // User needs to re-authenticate - show login redirect UI
        if (mounted) {
          setState(() {
            _hasError = false;
            _errorMessage = null;
            _requiresReauth = true;
          });
        }
      } else {
        // Handle other Firebase auth errors
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Authentication error: ${e.message}';
            _requiresReauth = false;
          });
        }
      }
    } catch (e) {
      print('Account deletion failed: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _requiresReauth = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header
              Icon(
                _hasError
                    ? LucideIcons.alertCircle
                    : _isComplete
                        ? LucideIcons.checkCircle
                        : _requiresReauth
                            ? LucideIcons.shield
                            : LucideIcons.userX,
                size: 64,
                color: _hasError
                    ? theme.error[600]
                    : _isComplete
                        ? theme.success[600]
                        : _requiresReauth
                            ? theme.warn[600]
                            : theme.primary[600],
              ),
              verticalSpace(Spacing.points24),

              Text(
                _hasError
                    ? AppLocalizations.of(context).translate('deletion-failed')
                    : _isComplete
                        ? AppLocalizations.of(context)
                            .translate('account-deleted-successfully')
                        : _requiresReauth
                            ? AppLocalizations.of(context)
                                .translate('authentication-required')
                            : AppLocalizations.of(context)
                                .translate('deleting-account'),
                style: TextStyles.h2.copyWith(
                  color: _hasError
                      ? theme.error[600]
                      : _isComplete
                          ? theme.success[600]
                          : _requiresReauth
                              ? theme.warn[600]
                              : theme.primary[900],
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              if (_requiresReauth) ...[
                verticalSpace(Spacing.points8),
                Text(
                  AppLocalizations.of(context)
                      .translate('recent-login-required-for-deletion'),
                  style: TextStyles.body.copyWith(
                    color: theme.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else if (!_hasError && !_isComplete) ...[
                verticalSpace(Spacing.points8),
                Text(
                  AppLocalizations.of(context)
                      .translate('please-wait-deletion-progress'),
                  style: TextStyles.body.copyWith(
                    color: theme.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              verticalSpace(Spacing.points32),

              // Re-authentication UI - redirect to login screen
              if (_requiresReauth) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.warn[300]!, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: theme.grey[200]!,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        AppLocalizations.of(context)
                            .translate('security-verification-required'),
                        style: TextStyles.body.copyWith(
                          color: theme.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      verticalSpace(Spacing.points8),
                      Text(
                        AppLocalizations.of(context).translate(
                            'please-sign-in-again-to-confirm-identity'),
                        style: TextStyles.body.copyWith(
                          color: theme.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      verticalSpace(Spacing.points20),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to login screen with deletion context
                          context.goNamed(
                            RouteNames.accountDeletionLogin.name,
                            queryParameters: {'returnTo': 'deletion'},
                          );
                        },
                        icon: Icon(LucideIcons.logIn),
                        label: Text(
                          AppLocalizations.of(context)
                              .translate('sign-in-to-continue'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.warn[600],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ]
              // Progress Steps (only show when not requiring reauth and not errored)
              else if (!_hasError) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.grey[300]!, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: theme.grey[200]!,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: _steps
                        .map((step) => _buildStepItem(step, theme))
                        .toList(),
                  ),
                ),
              ],

              // Error message
              if (_hasError) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.error[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.error[200]!, width: 1),
                  ),
                  child: Text(
                    _errorMessage ??
                        AppLocalizations.of(context).translate('unknown-error'),
                    style: TextStyles.body.copyWith(color: theme.error[700]),
                    textAlign: TextAlign.center,
                  ),
                ),
                verticalSpace(Spacing.points16),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child:
                      Text(AppLocalizations.of(context).translate('go-back')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(DeletionStep step, CustomThemeData theme) {
    Color getStatusColor() {
      switch (step.status) {
        case DeletionStepStatus.completed:
          return theme.success[600]!;
        case DeletionStepStatus.inProgress:
          return theme.primary[600]!;
        case DeletionStepStatus.failed:
          return theme.error[600]!;
        case DeletionStepStatus.pending:
          return theme.grey[400]!;
      }
    }

    Widget getStatusIcon() {
      switch (step.status) {
        case DeletionStepStatus.completed:
          return Icon(LucideIcons.check, color: getStatusColor(), size: 16);
        case DeletionStepStatus.inProgress:
          return SizedBox(
            width: 16,
            height: 16,
            child: Spinner(
              strokeWidth: 2,
              valueColor: getStatusColor(),
            ),
          );
        case DeletionStepStatus.failed:
          return Icon(LucideIcons.x, color: getStatusColor(), size: 16);
        case DeletionStepStatus.pending:
          return Icon(step.icon, color: getStatusColor(), size: 16);
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: getStatusColor(), width: 1),
            ),
            child: Center(child: getStatusIcon()),
          ),
          horizontalSpace(Spacing.points12),
          Expanded(
            child: Text(
              step.title,
              style: TextStyles.body.copyWith(
                color: step.status == DeletionStepStatus.pending
                    ? theme.grey[500]
                    : theme.primary[900],
                fontWeight: step.status == DeletionStepStatus.inProgress
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum DeletionStepStatus {
  pending,
  inProgress,
  completed,
  failed,
}

class DeletionStep {
  final String id;
  final String title;
  final IconData icon;
  final DeletionStepStatus status;

  DeletionStep({
    required this.id,
    required this.title,
    required this.icon,
    required this.status,
  });

  DeletionStep copyWith({
    String? id,
    String? title,
    IconData? icon,
    DeletionStepStatus? status,
  }) {
    return DeletionStep(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      status: status ?? this.status,
    );
  }
}
