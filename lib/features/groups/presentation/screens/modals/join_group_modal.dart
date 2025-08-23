import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/shared_widgets/platform_switch.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/groups/providers/group_membership_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/features/groups/application/groups_controller.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/groups/domain/entities/join_result_entity.dart';

class JoinGroupModal extends ConsumerStatefulWidget {
  const JoinGroupModal({super.key});

  @override
  ConsumerState<JoinGroupModal> createState() => _JoinGroupModalState();
}

class _JoinGroupModalState extends ConsumerState<JoinGroupModal> {
  final _groupCodeController = TextEditingController();
  bool _hideIdentity = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _groupCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 24), // Balance the close button
              Text(
                l10n.translate('join-group-title'),
                style: TextStyles.h4.copyWith(
                  color: theme.grey[900],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    LucideIcons.x,
                    size: 20,
                    color: theme.grey[600],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Hide Identity Section
          WidgetsContainer(
            backgroundColor: theme.grey[50],
            borderSide: BorderSide.none,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.heart,
                      size: 20,
                      color: theme.grey[700],
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.translate('hide-identity'),
                      style: TextStyles.body.copyWith(
                        color: theme.grey[900],
                      ),
                    ),
                    const Spacer(),
                    PlatformSwitch(
                      value: _hideIdentity,
                      onChanged: (value) {
                        setState(() {
                          _hideIdentity = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.translate('hide-identity-description'),
                  style: TextStyles.caption.copyWith(
                    color: theme.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Join Specific Group Section
          Text(
            l10n.translate('join-specific-group'),
            style: TextStyles.h5.copyWith(
              color: theme.grey[900],
            ),
          ),

          const SizedBox(height: 16),

          // Group Code Input
          CustomTextField(
            controller: _groupCodeController,
            hint: l10n.translate('enter-group-code'),
            prefixIcon: LucideIcons.hash,
            inputType: TextInputType.text,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return l10n.translate('group-code-required');
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Join Button
          GestureDetector(
            onTap: _isLoading ? null : _joinGroup,
            child: WidgetsContainer(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              backgroundColor:
                  _isLoading ? theme.grey[300] : theme.primary[600],
              borderRadius: BorderRadius.circular(10.5),
              borderSide: BorderSide.none,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoading) ...[
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.grey[600]!,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    l10n.translate('join-button'),
                    style: TextStyles.footnote.copyWith(
                      color: _isLoading ? theme.grey[600] : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Explore Groups Section
          Text(
            l10n.translate('explore-groups'),
            style: TextStyles.h5.copyWith(
              color: theme.grey[900],
            ),
          ),

          const SizedBox(height: 12),

          Text(
            l10n.translate('explore-groups-description'),
            style: TextStyles.caption.copyWith(
              color: theme.grey[600],
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          // Explore Groups Button
          GestureDetector(
            onTap: _exploreGroups,
            child: WidgetsContainer(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              backgroundColor: theme.primary[600],
              borderRadius: BorderRadius.circular(10.5),
              borderSide: BorderSide.none,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.search,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.translate('explore-groups-button'),
                    style: TextStyles.footnote.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _joinGroup() async {
    final l10n = AppLocalizations.of(context);
    final groupCode = _groupCodeController.text.trim();
    
    if (groupCode.isEmpty) {
      _showError(l10n.translate('group-code-required'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get current community profile
      final profileAsync = ref.read(currentCommunityProfileProvider);
      final profile = await profileAsync.first;
      
      if (profile == null) {
        _showError(l10n.translate('profile-required'));
        return;
      }

      // For now, assume we're joining a demo group ID
      // In a real app, you might need to find the group by code first
      const demoGroupId = 'demo_group_id';

      final result = await ref.read(groupsControllerProvider.notifier).joinGroupWithCode(
        groupId: demoGroupId,
        joinCode: groupCode,
        cpId: profile.id,
      );

      if (!mounted) return;

      if (result.success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('group-joined-successfully')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showError(_getJoinErrorMessage(result, l10n));
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

  String _getJoinErrorMessage(JoinResultEntity result, AppLocalizations l10n) {
    switch (result.errorType) {
      case JoinErrorType.alreadyInGroup:
        return l10n.translate('already-in-group-error');
      case JoinErrorType.cooldownActive:
        return l10n.translate('cooldown-active-error');
      case JoinErrorType.capacityFull:
        return l10n.translate('group-full-error');
      case JoinErrorType.invalidCode:
      case JoinErrorType.expiredCode:
        return l10n.translate('invalid-join-code-error');
      case JoinErrorType.genderMismatch:
        return l10n.translate('gender-mismatch-error');
      case JoinErrorType.groupNotFound:
        return l10n.translate('group-not-found-error');
      case JoinErrorType.groupInactive:
      case JoinErrorType.groupPaused:
        return l10n.translate('group-inactive-error');
      case JoinErrorType.userBanned:
        return l10n.translate('user-banned-error');
      default:
        return result.errorMessage ?? l10n.translate('join-group-failed');
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

  void _exploreGroups() {
    Navigator.of(context).pop();
    // Navigate to groups exploration screen using GoRouter
    context.goNamed(RouteNames.groupExploration.name);
  }
}
