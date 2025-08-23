import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/features/groups/application/groups_controller.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/groups/providers/group_membership_provider.dart';
import 'package:reboot_app_3/features/groups/providers/groups_status_provider.dart';

class LeaveGroupModal extends ConsumerStatefulWidget {
  const LeaveGroupModal({super.key});

  @override
  ConsumerState<LeaveGroupModal> createState() => _LeaveGroupModalState();
}

class _LeaveGroupModalState extends ConsumerState<LeaveGroupModal> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with title and close button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Close button
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: theme.grey[600],
                    ),
                  ),
                ),

                const Spacer(),

                // Title
                Text(
                  l10n.translate('leave-group'),
                  style: TextStyles.h4.copyWith(
                    color: theme.error[600],
                  ),
                ),

                const Spacer(),

                // Spacer to balance the close button
                const SizedBox(width: 28),
              ],
            ),
          ),

          // Warning items list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildWarningItem(
                  context: context,
                  theme: theme,
                  l10n: l10n,
                  icon: LucideIcons.messageCircle,
                  text: l10n.translate('leave-group-warning-messages'),
                ),

                verticalSpace(Spacing.points12),

                _buildWarningItem(
                  context: context,
                  theme: theme,
                  l10n: l10n,
                  icon: LucideIcons.trophy,
                  text: l10n.translate('leave-group-warning-challenges'),
                ),

                verticalSpace(Spacing.points12),

                _buildWarningItem(
                  context: context,
                  theme: theme,
                  l10n: l10n,
                  icon: LucideIcons.layers,
                  text: l10n.translate('leave-group-warning-updates'),
                ),

                verticalSpace(Spacing.points12),

                _buildWarningItem(
                  context: context,
                  theme: theme,
                  l10n: l10n,
                  icon: LucideIcons.shield,
                  text: l10n.translate('leave-group-warning-privacy'),
                ),

                verticalSpace(Spacing.points20),

                // 24-hour restriction warning
                WidgetsContainer(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  borderRadius: BorderRadius.circular(12),
                  backgroundColor: theme.error[50],
                  borderSide: BorderSide(
                    color: theme.error[200]!,
                    width: 1,
                  ),
                  child: Text(
                    l10n.translate('leave-group-24hour-restriction'),
                    style: TextStyles.h6.copyWith(
                      color: theme.error[700],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Leave Group button (destructive)
                GestureDetector(
                  onTap: _isLoading ? null : _leaveGroup,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: theme.error[500],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.translate('leave-group'),
                      style: TextStyles.footnote.copyWith(
                        color: theme.grey[50],
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                verticalSpace(Spacing.points8),

                // Close button (cancel)
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: theme.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      l10n.translate('close'),
                      style: TextStyles.footnote.copyWith(
                        color: theme.grey[900],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom padding for safe area
          verticalSpace(Spacing.points16),
        ],
      ),
    );
  }

  Future<void> _leaveGroup() async {
    final l10n = AppLocalizations.of(context);

    setState(() => _isLoading = true);

        try {
      // Get current community profile
      final profileAsync = ref.read(currentCommunityProfileProvider);
      final profile = await profileAsync.when(
        data: (profile) async => profile,
        loading: () async => null,
        error: (_, __) async => null,
      );
      
      if (profile == null) {
        _showError(l10n.translate('profile-required'));
        return;
      }

      final result =
          await ref.read(groupsControllerProvider.notifier).leaveGroup(
                cpId: profile.id,
              );

      if (!mounted) return;

      if (result.success) {
        // Explicitly invalidate providers to ensure UI updates
        ref.invalidate(groupMembershipNotifierProvider);
        ref.invalidate(groupsStatusProvider);
        print('LeaveGroupModal: Providers invalidated after successful leave');
        
        // Close the modal first
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('left-group-successfully')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Navigate back to groups main screen after a brief delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (context.mounted) {
            context.goNamed(RouteNames.groups.name);
            print('LeaveGroupModal: Navigated to groups main screen');
          }
        });
      } else {
        _showError(result.errorMessage ?? l10n.translate('leave-group-failed'));
      }
    } catch (error) {
      if (mounted) {
        _showError(l10n.translate('unexpected-error'));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildWarningItem({
    required BuildContext context,
    required CustomThemeData theme,
    required AppLocalizations l10n,
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon
        WidgetsContainer(
          padding: const EdgeInsets.all(8),
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.error[400]!,
            width: 1,
          ),
          backgroundColor: theme.error[100],
          child: Icon(
            icon,
            // size: 14,
            color: theme.error[600],
          ),
        ),

        horizontalSpace(Spacing.points12),

        // Text
        Expanded(
          child: Text(
            text,
            style: TextStyles.footnoteSelected
                .copyWith(color: theme.grey[900], height: 1.4),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
