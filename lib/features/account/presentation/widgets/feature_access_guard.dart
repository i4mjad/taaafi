import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../providers/ban_warning_providers.dart';
import '../../providers/clean_ban_warning_providers.dart';
import '../../data/models/ban.dart';
import '../../utils/ban_display_formatter.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theming/app-themes.dart';
import '../../../../core/theming/custom_theme_data.dart';
import '../../../../core/theming/text_styles.dart';
import '../../../../core/theming/spacing.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/helpers/date_display_formater.dart';

/// Widget that guards access to specific features based on user bans
class FeatureAccessGuard extends ConsumerWidget {
  final String featureUniqueName;
  final Widget child;
  final VoidCallback? onTap;
  final String? customBanMessage;

  const FeatureAccessGuard({
    Key? key,
    required this.featureUniqueName,
    required this.child,
    this.onTap,
    this.customBanMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Always show the child widget with tap handler
    return GestureDetector(
      onTap: () => _handleTap(context, ref),
      child: child,
    );
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    // Show loading modal bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext modalContext) {
        return _FeatureAccessModal(
          featureUniqueName: featureUniqueName,
          customBanMessage: customBanMessage,
          onAccessGranted: () {
            // Close modal and execute original callback
            Navigator.of(modalContext).pop();
            onTap?.call();
          },
          ref: ref,
        );
      },
    );
  }
}

/// Modal widget that shows loading and then ban details or allows access
class _FeatureAccessModal extends ConsumerStatefulWidget {
  final String featureUniqueName;
  final String? customBanMessage;
  final VoidCallback onAccessGranted;
  final WidgetRef ref;

  const _FeatureAccessModal({
    Key? key,
    required this.featureUniqueName,
    this.customBanMessage,
    required this.onAccessGranted,
    required this.ref,
  }) : super(key: key);

  @override
  ConsumerState<_FeatureAccessModal> createState() =>
      _FeatureAccessModalState();
}

class _FeatureAccessModalState extends ConsumerState<_FeatureAccessModal> {
  bool _isLoading = true;
  Ban? _ban;

  @override
  void initState() {
    super.initState();
    _checkFeatureAccess();
  }

  Future<void> _checkFeatureAccess() async {
    try {
      final canAccess = await checkFeatureAccess(ref, widget.featureUniqueName);

      if (canAccess) {
        // User has access, close modal and execute callback
        widget.onAccessGranted();
      } else {
        // User is banned, get ban details
        final ban = await ref.read(
          currentUserFeatureBanProvider(widget.featureUniqueName).future,
        );

        if (mounted) {
          setState(() {
            _ban = ban;

            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    return DraggableScrollableSheet(
      initialChildSize: _isLoading ? 0.25 : 0.5,
      minChildSize: _isLoading ? 0.2 : 0.3,
      maxChildSize: _isLoading ? 0.3 : 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _isLoading
                  ? _buildLoadingContent(context, theme, localizations)
                  : _buildBanContent(context, theme, localizations),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingContent(BuildContext context, CustomThemeData theme,
      AppLocalizations localizations) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle bar
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: theme.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 40),

        // Simple loading indicator
        CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(theme.primary[600]!),
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildBanContent(BuildContext context, CustomThemeData theme,
      AppLocalizations localizations) {
    final ban = _ban;
    final locale = ref.watch(localeNotifierProvider);

    return Column(
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
        const SizedBox(height: 24),

        // Ban icon
        Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: theme.error[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.shieldOff,
              size: 28,
              color: theme.error[600],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Title
        Center(
          child: Text(
            localizations.translate('feature-access-restricted'),
            style: TextStyles.h3.copyWith(
              color: theme.error[800],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Message
        Center(
          child: Text(
            widget.customBanMessage ??
                localizations.translate('feature-restricted-message'),
            style: TextStyles.body.copyWith(
              color: theme.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ),

        if (ban != null) ...[
          const SizedBox(height: 24),

          // Ban details
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.error[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.error[200]!, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Duration
                Row(
                  children: [
                    Icon(
                      LucideIcons.clock,
                      size: 16,
                      color: theme.error[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      localizations.translate('duration'),
                      style: TextStyles.small.copyWith(
                        color: theme.error[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      BanDisplayFormatter.formatBanDuration(ban, context),
                      style: TextStyles.small.copyWith(
                        color: theme.error[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Reason
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.alertTriangle,
                      size: 16,
                      color: theme.error[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.translate('reason'),
                            style: TextStyles.small.copyWith(
                              color: theme.error[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ban.reason,
                            style: TextStyles.small.copyWith(
                              color: theme.error[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (ban.expiresAt != null) ...[
                  const SizedBox(height: 12),

                  // Expires at
                  Row(
                    children: [
                      Icon(
                        LucideIcons.calendarX,
                        size: 16,
                        color: theme.error[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        localizations.translate('expires-on'),
                        style: TextStyles.small.copyWith(
                          color: theme.error[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        getDisplayDate(
                            ban.expiresAt!, locale?.languageCode ?? 'en'),
                        style: TextStyles.small.copyWith(
                          color: theme.error[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Action buttons
        Row(
          children: [
            // Close button
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: theme.grey[400]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  localizations.translate('close'),
                  style: TextStyles.body.copyWith(
                    color: theme.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // View details button
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.pushNamed(RouteNames.userProfile.name);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary[600],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  localizations.translate('view-details'),
                  style: TextStyles.body.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Simplified guard that just prevents action without showing a message
class SilentFeatureGuard extends ConsumerWidget {
  final String featureUniqueName;
  final VoidCallback? onAccessDenied;
  final VoidCallback onAccessGranted;

  const SilentFeatureGuard({
    Key? key,
    required this.featureUniqueName,
    required this.onAccessGranted,
    this.onAccessDenied,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featureAccessAsync = ref.watch(featureAccessProvider);
    return featureAccessAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (accessMap) {
        final canAccess = accessMap[featureUniqueName] ?? true;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (canAccess) {
            onAccessGranted();
          } else if (onAccessDenied != null) {
            onAccessDenied!();
          }
        });

        return const SizedBox.shrink();
      },
    );
  }
}

/// Helper function to check feature access programmatically
Future<bool> checkFeatureAccess(WidgetRef ref, String featureUniqueName) async {
  final accessMap = await ref.read(featureAccessProvider.future);

  final canAccess =
      (accessMap != null ? accessMap[featureUniqueName] : true) ?? true;
  return canAccess;
}

/// Helper function to show ban message dialog
Future<void> showFeatureBanDialog(
  BuildContext context,
  String featureUniqueName, {
  String? customMessage,
}) async {
  final theme = AppTheme.of(context);
  final l10n = AppLocalizations.of(context);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: theme.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            LucideIcons.shieldOff,
            color: theme.error[600],
            size: 24,
          ),
          horizontalSpace(Spacing.points8),
          Text(
            l10n.translate('access-restricted'),
            style: TextStyles.h6.copyWith(
              color: theme.error[800],
            ),
          ),
        ],
      ),
      content: Text(
        customMessage ?? l10n.translate('feature-ban-default-message'),
        style: TextStyles.body.copyWith(
          color: theme.grey[700],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n.translate('understood'),
            style: TextStyles.body.copyWith(
              color: theme.primary[600],
            ),
          ),
        ),
      ],
    ),
  );
}

/// Enhanced helper function to show feature ban snackbar with navigation to user profile
void showFeatureBanSnackbar(
  BuildContext context,
  String featureUniqueName, {
  String? customMessage,
  bool isPermanent = false,
}) {
  final theme = AppTheme.of(context);
  final l10n = AppLocalizations.of(context);

  // Determine message based on ban type
  final banTypeText = isPermanent
      ? l10n.translate('permanently-banned')
      : l10n.translate('temporarily-banned');

  final message = customMessage ??
      '${l10n.translate('feature-access-denied')} - $banTypeText';

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            LucideIcons.shieldOff,
            color: Colors.white,
            size: 20,
          ),
          horizontalSpace(Spacing.points8),
          Expanded(
            child: Text(
              message,
              style: TextStyles.body.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: theme.error[600],
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: l10n.translate('view-details'),
        textColor: Colors.white,
        onPressed: () {
          // Navigate to user profile screen to show ban details
          context.pushNamed(RouteNames.userProfile.name);
        },
      ),
    ),
  );
}

/// Helper function to check feature access and show snackbar if banned
Future<bool> checkFeatureAccessAndShowSnackbar(
  BuildContext context,
  WidgetRef ref,
  String featureUniqueName, {
  String? customMessage,
}) async {
  final canAccess = await checkFeatureAccess(ref, featureUniqueName);

  if (!canAccess) {
    // Get ban details to determine if it's permanent or temporary
    final ban = await ref.read(
      currentUserFeatureBanProvider(featureUniqueName).future,
    );

    final isPermanent = ban?.severity == BanSeverity.permanent;

    showFeatureBanSnackbar(
      context,
      featureUniqueName,
      customMessage: customMessage,
      isPermanent: isPermanent,
    );
  }

  return canAccess;
}
