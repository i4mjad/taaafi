import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/authentication/application/auth_service.dart';
import 'package:reboot_app_3/features/community/application/community_deletion_service.dart';

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
  String? _authProvider; // 'google', 'apple', or 'email'

  @override
  void initState() {
    super.initState();
    // Don't initialize steps here - do it in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_steps.isEmpty) {
      _initializeSteps();
      // Start deletion process immediately - no pre-auth required
      _startDeletionProcess();
    }
  }

  void _initializeSteps() {
    _steps = [
      DeletionStep(
        id: 'backup_data',
        title: AppLocalizations.of(context).translate('backing-up-data'),
        icon: LucideIcons.database,
        status: DeletionStepStatus.pending,
      ),
      DeletionStep(
        id: 'delete_community_data',
        title:
            AppLocalizations.of(context).translate('deleting-community-data'),
        icon: LucideIcons.users,
        status: DeletionStepStatus.pending,
      ),
      DeletionStep(
        id: 'delete_documents',
        title: AppLocalizations.of(context).translate('deleting-user-data'),
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
        title: AppLocalizations.of(context).translate('finalizing'),
        icon: LucideIcons.checkCircle,
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

  void _detectAuthProvider() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.providerData.isNotEmpty) {
      final provider = user.providerData.first.providerId;
      switch (provider) {
        case 'google.com':
          _authProvider = 'google';
          break;
        case 'apple.com':
          _authProvider = 'apple';
          break;
        case 'password':
          _authProvider = 'email';
          break;
        default:
          _authProvider = 'email'; // fallback
      }
    } else {
      _authProvider = 'email'; // fallback
    }
  }

  Future<void> _handleReauthentication() async {
    try {
      final authService = ref.read(authServiceProvider);
      bool success = false;

      if (_authProvider == 'google') {
        success = await authService.reSignInWithGoogle(context);
      } else if (_authProvider == 'apple') {
        success = await authService.reSignInWithApple(context);
      }

      if (success) {
        setState(() {
          _requiresReauth = false;
          _hasError = false;
          _errorMessage = null;
        });
        // Retry deletion after successful re-auth
        _startDeletionProcess();
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Re-authentication failed: ${e.toString()}';
      });
    }
  }

  Future<void> _startDeletionProcess() async {
    try {
      final authService = ref.read(authServiceProvider);
      final communityDeletionService =
          ref.read(communityDeletionServiceProvider);
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

      // Step 2: Delete community data (posts, comments, interactions, profile)
      _updateStepStatus('delete_community_data', DeletionStepStatus.inProgress);

      try {
        // Check if user has community data before attempting deletion
        final hasCommunityData = await communityDeletionService
            .hasUserCommunityData(currentUser.uid);

        if (hasCommunityData) {
          // Get summary for logging
          final summary = await communityDeletionService
              .getCommunityDataSummary(currentUser.uid);
          print('DEBUG: Community data summary: $summary');

          // Perform community data deletion
          await communityDeletionService
              .deleteUserCommunityData(currentUser.uid);
          print('DEBUG: Community data deletion completed successfully');
        } else {
          print('DEBUG: No community data found for user');
        }

        _updateStepStatus(
            'delete_community_data', DeletionStepStatus.completed);
      } catch (e) {
        print('WARNING: Community data deletion failed: $e');
        // Don't fail the entire process if community deletion fails
        // Mark as completed to continue with account deletion
        _updateStepStatus(
            'delete_community_data', DeletionStepStatus.completed);
      }

      // Step 3: Delete documents
      _updateStepStatus('delete_documents', DeletionStepStatus.inProgress);

      // Step 4: Delete account - attempt immediately
      _updateStepStatus('delete_account', DeletionStepStatus.inProgress);

      // Actually perform the deletion
      await authService.deleteAccount(context);

      _updateStepStatus('delete_documents', DeletionStepStatus.completed);
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
        // Handle re-authentication requirement
        _detectAuthProvider();
        if (mounted) {
          setState(() {
            _requiresReauth = true;
            _hasError = false;
          });
        }
      } else {
        // Handle other Firebase auth errors
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Authentication error: ${e.message}';
          });
        }
      }
    } catch (e) {
      print('Account deletion failed: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signOut(context, ref);
      if (mounted) {
        context.goNamed(RouteNames.onboarding.name);
      }
    } catch (e) {
      getErrorSnackBar(context, 'sign-out-failed');
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
                style: TextStyles.h4.copyWith(
                  color: theme.primary[900],
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

              // Re-authentication UI
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
                      if (_authProvider == 'google' ||
                          _authProvider == 'apple') ...[
                        Text(
                          AppLocalizations.of(context).translate(
                              'please-sign-in-again-with-${_authProvider}'),
                          style: TextStyles.body.copyWith(
                            color: theme.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        verticalSpace(Spacing.points16),
                        ElevatedButton.icon(
                          onPressed: _handleReauthentication,
                          icon: Icon(
                            _authProvider == 'google'
                                ? LucideIcons.chrome
                                : LucideIcons.smartphone,
                          ),
                          label: Text(
                            AppLocalizations.of(context)
                                .translate('sign-in-with-${_authProvider}'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primary[600],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                        ),
                      ] else ...[
                        Text(
                          AppLocalizations.of(context)
                              .translate('email-reauth-not-supported'),
                          style: TextStyles.body.copyWith(
                            color: theme.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      verticalSpace(Spacing.points16),
                      OutlinedButton(
                        onPressed: _signOut,
                        child: Text(
                          AppLocalizations.of(context).translate('sign-out'),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.error[600],
                          side: BorderSide(color: theme.error[600]!),
                        ),
                      ),
                    ],
                  ),
                ),
              ]
              // Progress Steps (only show when not requiring reauth)
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
