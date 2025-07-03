import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/ban_warning_providers.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theming/app-themes.dart';
import '../../../../core/theming/text_styles.dart';
import '../../../../core/theming/spacing.dart';
import '../../../../core/shared_widgets/container.dart';

/// Widget that guards access to specific features based on user bans
class FeatureAccessGuard extends ConsumerWidget {
  final String featureUniqueName;
  final Widget child;
  final Widget? customBanMessage;
  final bool showBanMessage;

  const FeatureAccessGuard({
    Key? key,
    required this.featureUniqueName,
    required this.child,
    this.customBanMessage,
    this.showBanMessage = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featureAccessAsync = ref.watch(featureAccessProvider);
    return featureAccessAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (accessMap) {
        final canAccess = accessMap[featureUniqueName] ?? true;
        if (canAccess) {
          return child;
        } else {
          return showBanMessage
              ? (customBanMessage ?? _buildDefaultBanMessage(context))
              : const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildDefaultBanMessage(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      child: WidgetsContainer(
        padding: const EdgeInsets.all(16),
        backgroundColor: theme.error[50],
        borderSide: BorderSide(color: theme.error[300]!, width: 1),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.shieldOff,
                  color: theme.error[600],
                  size: 24,
                ),
                horizontalSpace(Spacing.points12),
                Expanded(
                  child: Text(
                    l10n.translate('feature-access-restricted'),
                    style: TextStyles.h6.copyWith(
                      color: theme.error[800],
                    ),
                  ),
                ),
              ],
            ),
            verticalSpace(Spacing.points12),
            Text(
              l10n.translate('contact-admin-for-appeal'),
              style: TextStyles.footnote.copyWith(
                color: theme.error[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
  return (accessMap != null ? accessMap[featureUniqueName] : true) ?? true;
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
