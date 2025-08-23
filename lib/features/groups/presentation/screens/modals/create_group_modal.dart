import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textarea.dart';
import 'package:reboot_app_3/core/shared_widgets/platform_dropdown.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/groups/presentation/screens/modals/group_joining_methods_modal.dart';
import 'package:reboot_app_3/features/groups/application/groups_controller.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/groups/domain/entities/join_result_entity.dart';

enum GroupType { public, private }

class CreateGroupModal extends ConsumerStatefulWidget {
  const CreateGroupModal({super.key});

  @override
  ConsumerState<CreateGroupModal> createState() => _CreateGroupModalState();
}

class _CreateGroupModalState extends ConsumerState<CreateGroupModal> {
  final _groupNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _memberCountController = TextEditingController();
  GroupType _groupType = GroupType.public;
  GroupJoiningMethod? _joiningMethod;
  bool _isLoading = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    _descriptionController.dispose();
    _memberCountController.dispose();
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
      child: SingleChildScrollView(
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
                  l10n.translate('create-group-title'),
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

            // Group Name
            Text(
              l10n.translate('group-name'),
              style: TextStyles.body.copyWith(
                color: theme.grey[900],
              ),
            ),

            const SizedBox(height: 8),

            CustomTextField(
              controller: _groupNameController,
              hint: l10n.translate('enter-group-name'),
              prefixIcon: LucideIcons.users,
              inputType: TextInputType.text,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return l10n.translate('group-name-required');
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Group Description
            Text(
              l10n.translate('group-description'),
              style: TextStyles.body.copyWith(
                color: theme.grey[900],
              ),
            ),

            const SizedBox(height: 8),

            CustomTextArea(
              controller: _descriptionController,
              hint: l10n.translate('enter-group-description'),
              prefixIcon: LucideIcons.fileText,
              maxLines: 3,
              validator: (value) => null,
            ),

            const SizedBox(height: 24),

            // Member Count
            Text(
              l10n.translate('member-count'),
              style: TextStyles.body.copyWith(
                color: theme.grey[900],
              ),
            ),

            const SizedBox(height: 8),

            CustomTextField(
              controller: _memberCountController,
              hint: l10n.translate('enter-member-count'),
              prefixIcon: LucideIcons.hash,
              inputType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return l10n.translate('member-count-required');
                }
                final count = int.tryParse(value!);
                if (count == null || count < 2 || count > 50) {
                  return l10n.translate('member-count-invalid');
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Group Type
            Text(
              l10n.translate('group-type'),
              style: TextStyles.body.copyWith(
                color: theme.grey[900],
              ),
            ),

            const SizedBox(height: 8),

            PlatformDropdown<GroupType>(
              value: _groupType,
              items: [
                PlatformDropdownItem(
                  value: GroupType.public,
                  label: l10n.translate('group-type-public'),
                ),
                PlatformDropdownItem(
                  value: GroupType.private,
                  label: l10n.translate('group-type-private'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _groupType = value;
                  });
                }
              },
              backgroundColor: theme.grey[50],
            ),

            const SizedBox(height: 12),

            Text(
              _groupType == GroupType.public
                  ? l10n.translate('group-type-public-description')
                  : l10n.translate('group-type-private-description'),
              style: TextStyles.caption.copyWith(
                color: theme.grey[600],
                height: 1.4,
              ),
            ),

            const SizedBox(height: 24),

            // Group Joining Methods
            Text(
              l10n.translate('group-joining-methods'),
              style: TextStyles.body.copyWith(
                color: theme.grey[900],
              ),
            ),

            const SizedBox(height: 8),

            GestureDetector(
              onTap: () => _showJoiningMethodsModal(context),
              child: WidgetsContainer(
                backgroundColor: theme.grey[50],
                borderSide: BorderSide(
                  color: theme.grey[200]!,
                  width: 1,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _joiningMethod != null
                            ? _getJoiningMethodLabel(_joiningMethod!, l10n)
                            : l10n.translate('select-joining-method'),
                        style: TextStyles.body.copyWith(
                          color: _joiningMethod != null
                              ? theme.grey[900]
                              : theme.grey[500],
                        ),
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronDown,
                      size: 20,
                      color: theme.grey[600],
                    ),
                  ],
                ),
              ),
            ),

            if (_joiningMethod != null) ...[
              const SizedBox(height: 12),
              Text(
                _getJoiningMethodDescription(_joiningMethod!, l10n),
                style: TextStyles.caption.copyWith(
                  color: theme.grey[600],
                  height: 1.4,
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Create Button
            GestureDetector(
              onTap: _isLoading ? null : _createGroup,
              child: WidgetsContainer(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
                      l10n.translate('create-group-button'),
                      style: TextStyles.footnote.copyWith(
                        color: _isLoading ? theme.grey[600] : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _createGroup() async {
    final l10n = AppLocalizations.of(context);
    final groupName = _groupNameController.text.trim();
    final description = _descriptionController.text.trim();
    final memberCountText = _memberCountController.text.trim();

    // Validation
    if (groupName.isEmpty) {
      _showError(l10n.translate('group-name-required'));
      return;
    }

    if (memberCountText.isEmpty) {
      _showError(l10n.translate('member-count-required'));
      return;
    }

    final memberCount = int.tryParse(memberCountText);
    if (memberCount == null || memberCount < 2 || memberCount > 50) {
      _showError(l10n.translate('member-count-invalid'));
      return;
    }

    if (_joiningMethod == null) {
      _showError(l10n.translate('joining-method-required'));
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
        _showError(l10n.translate('profile-required'));
        return;
      }

      // Check if user is Plus (for capacity > 6)
      final isPlus = profile.isPlusUser ?? false;

      // Map joining method to domain value
      String joinMethod;
      switch (_joiningMethod!) {
        case GroupJoiningMethod.any:
          joinMethod = 'any';
          break;
        case GroupJoiningMethod.adminInviteOnly:
          joinMethod = 'admin_only';
          break;
        case GroupJoiningMethod.groupCodeOnly:
          joinMethod = 'code_only';
          break;
      }

      // Create group
      final result = await ref
          .read(groupsControllerProvider.notifier)
          .createGroup(
            name: groupName,
            description: description,
            memberCapacity: memberCount,
            visibility: _groupType == GroupType.public ? 'public' : 'private',
            joinMethod: joinMethod,
            creatorCpId: profile.id,
            isCreatorPlusUser: isPlus,
          );

      if (!mounted) return;

      if (result.success) {
        Navigator.of(context).pop();
        getSuccessSnackBar(context, 'group-created-successfully');
      } else {
        _showError(_getCreateErrorMessage(result, l10n));
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

  String _getCreateErrorMessage(CreateGroupResultEntity result, AppLocalizations l10n) {
    switch (result.errorType) {
      case CreateGroupErrorType.cooldownActive:
        return l10n.translate('cooldown-active-create-error');
      case CreateGroupErrorType.alreadyInGroup:
        return l10n.translate('already-in-group-error');
      case CreateGroupErrorType.invalidName:
        return l10n.translate('group-name-invalid');
      case CreateGroupErrorType.invalidCapacity:
        return l10n.translate('member-count-invalid');
      case CreateGroupErrorType.capacityRequiresPlusUser:
        return l10n.translate('member-count-requires-plus');
      case CreateGroupErrorType.invalidGender:
        return l10n.translate('gender-requirements-not-met');
      default:
        return result.errorMessage ?? l10n.translate('group-creation-failed');
    }
  }

  void _showError(String message) {
    getSystemSnackBar(context, message);
  }

  void _showJoiningMethodsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GroupJoiningMethodsModal(
        selectedMethod: _joiningMethod,
        onMethodSelected: (method) {
          setState(() {
            _joiningMethod = method;
          });
        },
      ),
    );
  }

  String _getJoiningMethodLabel(
      GroupJoiningMethod method, AppLocalizations l10n) {
    switch (method) {
      case GroupJoiningMethod.any:
        return l10n.translate('joining-method-any');
      case GroupJoiningMethod.adminInviteOnly:
        return l10n.translate('joining-method-admin-only');
      case GroupJoiningMethod.groupCodeOnly:
        return l10n.translate('joining-method-code-only');
    }
  }

  String _getJoiningMethodDescription(
      GroupJoiningMethod method, AppLocalizations l10n) {
    switch (method) {
      case GroupJoiningMethod.any:
        return l10n.translate('joining-method-any-description');
      case GroupJoiningMethod.adminInviteOnly:
        return l10n.translate('joining-method-admin-only-description');
      case GroupJoiningMethod.groupCodeOnly:
        return l10n.translate('joining-method-code-only-description');
    }
  }
}
