import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/groups/providers/group_settings_provider.dart';

class GroupCapacitySettingsScreen extends ConsumerStatefulWidget {
  const GroupCapacitySettingsScreen({super.key});

  @override
  ConsumerState<GroupCapacitySettingsScreen> createState() =>
      _GroupCapacitySettingsScreenState();
}

class _GroupCapacitySettingsScreenState
    extends ConsumerState<GroupCapacitySettingsScreen> {
  int? _selectedCapacity;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCapacity();
    });
  }

  void _initializeCapacity() {
    final settingsAsync = ref.read(groupSettingsProvider);
    settingsAsync.whenData((state) {
      if (state.group != null && mounted) {
        setState(() {
          _selectedCapacity = state.group!.memberCapacity;
        });
      }
    });
  }

  void _onCapacityChanged(int newCapacity) {
    final settingsAsync = ref.read(groupSettingsProvider);
    settingsAsync.whenData((state) {
      setState(() {
        _selectedCapacity = newCapacity;
        _hasChanges = state.group?.memberCapacity != newCapacity;
      });
    });
  }

  Future<void> _saveCapacity() async {
    if (_selectedCapacity == null || !_hasChanges) return;

    final l10n = AppLocalizations.of(context);

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('confirm-capacity-change')),
        content: Text(l10n.translate('confirm-capacity-change')
            .replaceAll('{capacity}', _selectedCapacity.toString())),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.translate('confirm')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Update capacity
    await ref.read(groupSettingsProvider.notifier).updateCapacity(_selectedCapacity!);

    if (!mounted) return;

    // Check for errors or success
    final state = await ref.read(groupSettingsProvider.future);
    if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate(state.error!)),
          backgroundColor: Colors.red,
        ),
      );
    } else if (state.successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate(state.successMessage!)),
          backgroundColor: Colors.green,
        ),
      );
      // Clear messages and go back
      ref.read(groupSettingsProvider.notifier).clearMessages();
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final settingsAsync = ref.watch(groupSettingsProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, "group-capacity", false, true),
      body: settingsAsync.when(
        data: (state) {
          if (state.group == null) {
            return Center(
              child: Text(l10n.translate('group-not-found')),
            );
          }

          if (!state.isUserAdmin) {
            return Center(
              child: Text(l10n.translate('error-admin-permission-required')),
            );
          }

          final currentCapacity = state.group!.memberCapacity;
          final currentMemberCount = state.group!.memberCount;

          _selectedCapacity ??= currentCapacity;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Card
                WidgetsContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        l10n.translate('current-capacity'),
                        currentCapacity.toString(),
                        theme,
                      ),
                      verticalSpace(Spacing.points8),
                      _buildInfoRow(
                        l10n.translate('current-members'),
                        currentMemberCount.toString(),
                        theme,
                      ),
                      verticalSpace(Spacing.points8),
                      _buildInfoRow(
                        l10n.translate('members-remaining'),
                        (currentCapacity - currentMemberCount).toString(),
                        theme,
                      ),
                    ],
                  ),
                ),

                verticalSpace(Spacing.points24),

                // Capacity Selector
                Text(
                  l10n.translate('update-capacity'),
                  style: TextStyles.h5.copyWith(color: theme.grey[900]),
                ),
                verticalSpace(Spacing.points16),

                // Slider
                Slider(
                  value: _selectedCapacity!.toDouble(),
                  min: currentMemberCount.toDouble(),
                  max: 50.0,
                  divisions: (50 - currentMemberCount).toInt(),
                  label: _selectedCapacity.toString(),
                  onChanged: (value) => _onCapacityChanged(value.toInt()),
                ),

                // Selected value display
                Center(
                  child: Text(
                    '$_selectedCapacity ${l10n.translate('members')}',
                    style: TextStyles.h2.copyWith(color: theme.grey[900]),
                  ),
                ),

                // Warning for Plus requirement
                if (_selectedCapacity! > 6)
                    Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: WidgetsContainer(
                      padding: const EdgeInsets.all(12),
                      backgroundColor: theme.primary[50],
                      child: Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: theme.primary[600],
                            size: 20,
                          ),
                          horizontalSpace(Spacing.points8),
                          Expanded(
                            child: Text(
                              l10n.translate('upgrade-to-plus-for-capacity'),
                              style: TextStyles.body.copyWith(color: theme.primary[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const Spacer(),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _hasChanges && !state.isLoading ? _saveCapacity : null,
                    child: state.isLoading 
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.translate('save-changes')),
                  ),
                ),

                verticalSpace(Spacing.points16),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(l10n.translate('error-loading-data')),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyles.body.copyWith(color: theme.grey[700]),
        ),
        Text(
          value,
          style: TextStyles.h5.copyWith(color: theme.grey[900]),
        ),
      ],
    );
  }
}

