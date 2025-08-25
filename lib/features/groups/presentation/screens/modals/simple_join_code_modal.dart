import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';

import 'package:go_router/go_router.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/features/groups/application/groups_controller.dart';
import 'package:reboot_app_3/features/groups/application/groups_providers.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/groups/domain/entities/join_result_entity.dart';

class SimpleJoinCodeModal extends ConsumerStatefulWidget {
  final String groupName;
  
  const SimpleJoinCodeModal({
    super.key,
    required this.groupName,
  });

  @override
  ConsumerState<SimpleJoinCodeModal> createState() => _SimpleJoinCodeModalState();
}

class _SimpleJoinCodeModalState extends ConsumerState<SimpleJoinCodeModal> {
  final _joinCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _joinCodeController.dispose();
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
              Expanded(
                child: Text(
                  l10n.translate('join-group-with-code'),
                  style: TextStyles.h5.copyWith(
                    color: theme.grey[900],
                  ),
                  textAlign: TextAlign.center,
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

          verticalSpace(Spacing.points16),

          // Group info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.grey[200]!, width: 0.5),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.users,
                  color: theme.primary[600],
                  size: 20,
                ),
                horizontalSpace(Spacing.points8),
                Expanded(
                  child: Text(
                    widget.groupName,
                    style: TextStyles.body.copyWith(
                      color: theme.grey[900],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          verticalSpace(Spacing.points16),

          // Join code input
          Text(
            l10n.translate('enter-join-code'),
            style: TextStyles.body.copyWith(
              color: theme.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),

          verticalSpace(Spacing.points8),

          CustomTextField(
            controller: _joinCodeController,
            hint: l10n.translate('join-code-placeholder'),
            prefixIcon: LucideIcons.key,
            inputType: TextInputType.text,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return l10n.translate('join-code-required');
              }
              return null;
            },
          ),

          verticalSpace(Spacing.points20),

          // Join Button
          GestureDetector(
            onTap: _isLoading ? null : _joinGroup,
            child: WidgetsContainer(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              backgroundColor:
                  _isLoading ? theme.grey[300] : theme.primary[600],
              borderRadius: BorderRadius.circular(12),
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
                    horizontalSpace(Spacing.points8),
                  ],
                  Text(
                    l10n.translate('join-group'),
                    style: TextStyles.footnote.copyWith(
                      color: _isLoading ? theme.grey[600] : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          verticalSpace(Spacing.points16),
        ],
      ),
    );
  }

  Future<void> _joinGroup() async {
    final l10n = AppLocalizations.of(context);
    final joinCode = _joinCodeController.text.trim();

    if (joinCode.isEmpty) {
      getErrorSnackBar(context, 'join-code-required');
      return;
    }

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
        getErrorSnackBar(context, 'profile-required');
        return;
      }

      // Find the group by join code first
      final groupsService = ref.read(groupsServiceProvider);
      final group = await groupsService.findGroupByJoinCode(joinCode);
      
      if (group == null) {
        getErrorSnackBar(context, 'invalid-join-code-error');
        return;
      }

      final result =
          await ref.read(groupsControllerProvider.notifier).joinGroupWithCode(
                groupId: group.id,
                joinCode: joinCode,
                cpId: profile.id,
              );

      if (!mounted) return;

      if (result.success) {
        Navigator.of(context).pop();
        getSuccessSnackBar(context, 'group-joined-successfully');
        // Navigate to group screen after successful join
        if (mounted) {
          context.goNamed(RouteNames.groups.name);
        }
      } else {
        getErrorSnackBar(context, _getJoinErrorMessage(result, l10n));
      }
    } catch (error) {
      if (mounted) {
        getErrorSnackBar(context, 'unexpected-error');
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
        return 'already-in-group-error';
      case JoinErrorType.cooldownActive:
        return 'cooldown-active-error';
      case JoinErrorType.capacityFull:
        return 'group-full-error';
      case JoinErrorType.invalidCode:
      case JoinErrorType.expiredCode:
        return 'invalid-join-code-error';
      case JoinErrorType.genderMismatch:
        return 'gender-mismatch-error';
      case JoinErrorType.groupNotFound:
        return 'group-not-found-error';
      case JoinErrorType.groupInactive:
      case JoinErrorType.groupPaused:
        return 'group-inactive-error';
      case JoinErrorType.userBanned:
        return 'user-banned-error';
      default:
        return 'join-group-failed';
    }
  }
}
