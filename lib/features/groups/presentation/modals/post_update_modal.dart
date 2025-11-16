import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/groups/domain/entities/group_update_entity.dart';
import 'package:reboot_app_3/features/groups/domain/services/update_preset_templates.dart';
import 'package:reboot_app_3/features/groups/application/updates_providers.dart';

/// Modal for posting a new update
class PostUpdateModal extends ConsumerStatefulWidget {
  final String groupId;

  const PostUpdateModal({super.key, required this.groupId});

  @override
  ConsumerState<PostUpdateModal> createState() => _PostUpdateModalState();

  static Future<void> show(BuildContext context, String groupId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PostUpdateModal(groupId: groupId),
    );
  }
}

class _PostUpdateModalState extends ConsumerState<PostUpdateModal> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  UpdateType _selectedType = UpdateType.general;
  UpdatePresetTemplate? _selectedPreset;
  bool _isAnonymous = false;
  bool _showPresets = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final isLoading = ref.watch(postUpdateControllerProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.translate('post-update'),
                    style: TextStyles.h5.copyWith(color: theme.grey[900]),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.x, color: theme.grey[600]),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Preset selector toggle
              if (!_showPresets)
                TextButton.icon(
                  onPressed: () => setState(() => _showPresets = true),
                  icon: Icon(LucideIcons.sparkles, size: 16),
                  label: Text(l10n.translate('use-preset')),
                ),

              // Presets grid
              if (_showPresets) ...[
                Text(
                  l10n.translate('choose-preset'),
                  style: TextStyles.footnoteSelected.copyWith(
                    color: theme.grey[900],
                  ),
                ),
                const SizedBox(height: 12),
                _buildPresetsGrid(theme, l10n),
                const SizedBox(height: 16),
              ],

              // Type selector
              Text(
                l10n.translate('update-type'),
                style: TextStyles.footnoteSelected.copyWith(
                  color: theme.grey[900],
                ),
              ),
              const SizedBox(height: 8),
              _buildTypeSelector(theme, l10n),
              const SizedBox(height: 16),

              // Title input
              TextField(
                controller: _titleController,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: l10n.translate('update-title'),
                  hintText: l10n.translate('optional'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Content input
              TextField(
                controller: _contentController,
                maxLength: 1000,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: l10n.translate('update-content'),
                  hintText: l10n.translate('whats-your-update'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Anonymous toggle
              Row(
                children: [
                  Switch(
                    value: _isAnonymous,
                    onChanged: (value) => setState(() => _isAnonymous = value),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.translate('post-anonymously'),
                    style: TextStyles.body.copyWith(color: theme.grey[800]),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Post button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _postUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary[500],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(l10n.translate('post-update-button')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetsGrid(dynamic theme, AppLocalizations l10n) {
    final presets = UpdatePresetTemplates.getAllPresets();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: presets.map((preset) {
        final isSelected = _selectedPreset?.id == preset.id;
        return GestureDetector(
          onTap: () => _selectPreset(preset),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? theme.primary[100] : theme.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? theme.primary[500]! : theme.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(preset.icon, style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  l10n.translate(preset.titleKey),
                  style: TextStyles.caption.copyWith(
                    color: isSelected ? theme.primary[700] : theme.grey[800],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTypeSelector(dynamic theme, AppLocalizations l10n) {
    final types = [
      UpdateType.general,
      UpdateType.progress,
      UpdateType.struggle,
      UpdateType.celebration,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((type) {
        final isSelected = _selectedType == type;
        return GestureDetector(
          onTap: () => setState(() => _selectedType = type),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? theme.primary[100] : theme.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? theme.primary[500]! : theme.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(type.icon, style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  l10n.translate('update-type-${type.toFirestore()}'),
                  style: TextStyles.caption.copyWith(
                    color: isSelected ? theme.primary[700] : theme.grey[800],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _selectPreset(UpdatePresetTemplate preset) {
    setState(() {
      _selectedPreset = preset;
      _selectedType = preset.type;
      _contentController.text = '';
      _showPresets = false;
    });
  }

  Future<void> _postUpdate() async {
    if (_contentController.text.trim().isEmpty && _selectedPreset == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add content or select a preset')),
      );
      return;
    }

    try {
      final result = _selectedPreset != null
          ? await ref.read(postUpdateControllerProvider.notifier).postFromPreset(
                groupId: widget.groupId,
                presetId: _selectedPreset!.id,
                additionalContent: _contentController.text.trim().isEmpty
                    ? null
                    : _contentController.text.trim(),
                isAnonymous: _isAnonymous,
              )
          : await ref.read(postUpdateControllerProvider.notifier).postUpdate(
                groupId: widget.groupId,
                type: _selectedType,
                title: _titleController.text.trim(),
                content: _contentController.text.trim(),
                isAnonymous: _isAnonymous,
              );

      if (result.success) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Update posted successfully!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.errorMessage ?? 'Failed to post update')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}

