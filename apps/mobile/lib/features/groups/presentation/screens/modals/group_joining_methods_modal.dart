import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

enum GroupJoiningMethod {
  any,
  groupCodeOnly,
}

class GroupJoiningMethodsModal extends ConsumerStatefulWidget {
  final GroupJoiningMethod? selectedMethod;
  final Function(GroupJoiningMethod) onMethodSelected;

  const GroupJoiningMethodsModal({
    super.key,
    required this.selectedMethod,
    required this.onMethodSelected,
  });

  @override
  ConsumerState<GroupJoiningMethodsModal> createState() =>
      _GroupJoiningMethodsModalState();
}

class _GroupJoiningMethodsModalState
    extends ConsumerState<GroupJoiningMethodsModal> {
  GroupJoiningMethod? _selectedMethod;

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.selectedMethod;
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
                l10n.translate('group-joining-methods'),
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

          // Any Method Option
          _buildMethodOption(
            method: GroupJoiningMethod.any,
            title: l10n.translate('joining-method-any'),
            description: l10n.translate('joining-method-any-description'),
            icon: LucideIcons.users,
            theme: theme,
            l10n: l10n,
          ),

          const SizedBox(height: 16),

          // Group Code Only Option
          _buildMethodOption(
            method: GroupJoiningMethod.groupCodeOnly,
            title: l10n.translate('joining-method-code-only'),
            description: l10n.translate('joining-method-code-only-description'),
            icon: LucideIcons.key,
            theme: theme,
            l10n: l10n,
          ),

          const SizedBox(height: 32),

          // Confirm Button
          GestureDetector(
            onTap: _selectedMethod != null ? _confirmSelection : null,
            child: WidgetsContainer(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              backgroundColor: _selectedMethod != null
                  ? theme.primary[600]
                  : theme.grey[300],
              borderRadius: BorderRadius.circular(10.5),
              borderSide: BorderSide.none,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.translate('confirm-selection'),
                    style: TextStyles.footnote.copyWith(
                      color: _selectedMethod != null
                          ? Colors.white
                          : theme.grey[600],
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

  Widget _buildMethodOption({
    required GroupJoiningMethod method,
    required String title,
    required String description,
    required IconData icon,
    required dynamic theme,
    required AppLocalizations l10n,
  }) {
    final isSelected = _selectedMethod == method;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = method;
        });
      },
      child: WidgetsContainer(
        backgroundColor: isSelected ? theme.primary[50] : theme.grey[50],
        borderSide: BorderSide(
          color: isSelected ? theme.primary[300]! : theme.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? theme.primary[100] : theme.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? theme.primary[600] : theme.grey[600],
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyles.body.copyWith(
                      color: isSelected ? theme.primary[700] : theme.grey[900],
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyles.caption.copyWith(
                      color: theme.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? theme.primary[600]! : theme.grey[300]!,
                  width: 2,
                ),
                color: isSelected ? theme.primary[600] : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(
                      LucideIcons.check,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSelection() {
    if (_selectedMethod != null) {
      widget.onMethodSelected(_selectedMethod!);
      Navigator.of(context).pop();
    }
  }
}
