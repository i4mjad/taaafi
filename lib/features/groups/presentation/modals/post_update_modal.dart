import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/features/groups/domain/entities/group_update_entity.dart';
import 'package:reboot_app_3/features/groups/domain/services/update_preset_templates.dart';
import 'package:reboot_app_3/features/groups/application/updates_providers.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';

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
      useSafeArea: true,
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

  @override
  void initState() {
    super.initState();
    _loadAnonymousSetting();
  }

  Future<void> _loadAnonymousSetting() async {
    final currentProfile = await ref.read(currentCommunityProfileProvider.future);
    if (currentProfile != null && mounted) {
      setState(() {
        _isAnonymous = currentProfile.isAnonymous;
      });
    }
  }

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
    final locale = ref.watch(localeNotifierProvider);
    final isLoading = ref.watch(postUpdateControllerProvider);

    return Container(
      color: theme.backgroundColor,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fixed Header
          Container(
            decoration: BoxDecoration(
              color: theme.backgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                bottom: BorderSide(
                  color: theme.grey[300]!,
                  width: 0.5,
                ),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.translate('post-update'),
                  style: TextStyles.h6.copyWith(
                    color: theme.grey[900],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(LucideIcons.x, color: theme.grey[600], size: 24),
                ),
              ],
            ),
          ),

          // Scrollable Content
          Flexible(
            fit: FlexFit.loose,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preset selector button
                  GestureDetector(
                    onTap: () async {
                      await _showPresetsSheet(context);
                    },
                    child: WidgetsContainer(
                      padding: const EdgeInsets.all(12),
                      backgroundColor: theme.primary[50],
                      borderSide: BorderSide(
                        color: theme.primary[200]!,
                        width: 0.75,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _selectedPreset == null
                                ? Row(
                                    children: [
                                      Icon(
                                        LucideIcons.sparkles,
                                        size: 16,
                                        color: theme.primary[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        l10n.translate('use-preset'),
                                        style: TextStyles.caption,
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: theme.backgroundColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: theme.primary[400]!,
                                            width: 1,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            _selectedPreset!.icon,
                                            style: const TextStyle(fontSize: 16),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          l10n.translate(_selectedPreset!.titleKey),
                                          style: TextStyles.small.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            locale?.languageCode == 'ar'
                                ? LucideIcons.chevronLeft
                                : LucideIcons.chevronRight,
                            color: theme.grey[600],
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

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
                    style: TextStyles.body.copyWith(color: theme.grey[900]),
                    decoration: InputDecoration(
                      labelText: l10n.translate('update-title'),
                      labelStyle: TextStyles.footnote.copyWith(color: theme.grey[700]),
                      hintText: l10n.translate('optional'),
                      hintStyle: TextStyles.footnote.copyWith(color: theme.grey[500]),
                      counterStyle: TextStyles.caption.copyWith(color: theme.grey[600]),
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
                    style: TextStyles.body.copyWith(color: theme.grey[900]),
                    decoration: InputDecoration(
                      labelText: l10n.translate('update-content'),
                      labelStyle: TextStyles.footnote.copyWith(color: theme.grey[700]),
                      hintText: l10n.translate('whats-your-update'),
                      hintStyle: TextStyles.footnote.copyWith(color: theme.grey[500]),
                      counterStyle: TextStyles.caption.copyWith(color: theme.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Fixed Footer with Post Button
          Container(
            decoration: BoxDecoration(
              color: theme.backgroundColor,
              border: Border(
                top: BorderSide(
                  color: theme.grey[300]!,
                  width: 0.5,
                ),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: isLoading ? null : _postUpdate,
              child: WidgetsContainer(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: isLoading ? theme.grey[400] : theme.primary[500],
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
                cornerSmoothing: 0.6,
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          l10n.translate('post-update-button'),
                          style: TextStyles.h6.copyWith(color: Colors.white),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show presets selection sheet
  Future<void> _showPresetsSheet(BuildContext context) async {
    final result = await showModalBottomSheet<UpdatePresetTemplate?>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => PresetsSelectionSheet(
        selectedPreset: _selectedPreset,
        onPresetSelect: (preset) {
          setState(() {
            _selectPreset(preset);
          });
        },
      ),
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
          child: WidgetsContainer(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            backgroundColor: isSelected ? theme.primary[100] : theme.grey[100],
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: isSelected ? theme.primary[500]! : theme.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            cornerSmoothing: 0.8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(type.icon, style: const TextStyle(fontSize: 16)),
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

  void _selectPreset(UpdatePresetTemplate preset) async {
    final l10n = AppLocalizations.of(context);
    
    // Get gender for gender-aware presets
    String contentKey = preset.contentKey;
    if (preset.isGenderAware) {
      final currentProfile = await ref.read(currentCommunityProfileProvider.future);
      if (currentProfile != null) {
        final gender = currentProfile.gender.toLowerCase();
        if (gender == 'male' || gender == 'female') {
          contentKey = '${preset.contentKey}-$gender';
        } else {
          // Invalid gender - show error
          if (mounted) {
            getErrorSnackBar(context, 'invalid-gender-error');
            return;
          }
        }
      }
    }
    
    setState(() {
      _selectedPreset = preset;
      _selectedType = preset.type;
      _titleController.text = l10n.translate(preset.titleKey);
      _contentController.text = l10n.translate(contentKey);
    });
  }

  Future<void> _postUpdate() async {
    if (_contentController.text.trim().isEmpty) {
      getErrorSnackBar(context, 'please-add-content');
      return;
    }

    try {
      // Always use postUpdate with the content from text controllers
      // This ensures translated and gender-aware content is used
      final result = await ref.read(postUpdateControllerProvider.notifier).postUpdate(
            groupId: widget.groupId,
            type: _selectedType,
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            isAnonymous: _isAnonymous,
          );

      if (result.success) {
        if (mounted) {
          // Refresh all update providers
          ref.invalidate(latestUpdatesProvider(widget.groupId));
          ref.invalidate(recentUpdatesProvider(widget.groupId));
          ref.invalidate(groupUpdatesProvider(widget.groupId));
          
          Navigator.pop(context);
          getSuccessSnackBar(context, 'update-posted-successfully');
        }
      } else {
        if (mounted) {
          getErrorSnackBar(context, result.errorMessage ?? 'failed-to-post-update');
        }
      }
    } catch (e) {
      if (mounted) {
        getErrorSnackBar(context, 'error-posting-update');
      }
    }
  }
}

/// Stateful widget for presets selection sheet
class PresetsSelectionSheet extends StatefulWidget {
  final UpdatePresetTemplate? selectedPreset;
  final Function(UpdatePresetTemplate) onPresetSelect;

  const PresetsSelectionSheet({
    super.key,
    required this.selectedPreset,
    required this.onPresetSelect,
  });

  @override
  State<PresetsSelectionSheet> createState() => _PresetsSelectionSheetState();
}

class _PresetsSelectionSheetState extends State<PresetsSelectionSheet> {
  UpdatePresetTemplate? _localSelectedPreset;

  @override
  void initState() {
    super.initState();
    _localSelectedPreset = widget.selectedPreset;
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final presets = UpdatePresetTemplates.getAllPresets();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.grey[300]!,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.translate('choose-preset'),
                  style: TextStyles.h6,
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(LucideIcons.x, size: 24),
                ),
              ],
            ),
          ),

          // Content - Presets Grid
          Flexible(
            fit: FlexFit.loose,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: presets.map((preset) {
                  final isSelected = _localSelectedPreset?.id == preset.id;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _localSelectedPreset = preset;
                      });
                      widget.onPresetSelect(preset);
                    },
                    child: WidgetsContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      backgroundColor: isSelected ? theme.primary[100] : theme.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: isSelected ? theme.primary[500]! : theme.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      cornerSmoothing: 0.8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(preset.icon, style: const TextStyle(fontSize: 16)),
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
              ),
            ),
          ),

          // Footer - Done Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.grey[300]!,
                  width: 0.5,
                ),
              ),
            ),
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: WidgetsContainer(
                padding: const EdgeInsets.all(12),
                borderRadius: BorderRadius.circular(10),
                backgroundColor: theme.primary[600],
                borderSide: BorderSide.none,
                cornerSmoothing: 0.6,
                child: Center(
                  child: Text(
                    l10n.translate('done'),
                    style: TextStyles.caption.copyWith(color: theme.grey[50]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

