import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/platform_date_picker.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/groups/domain/entities/challenge_task_entity.dart';
import 'package:reboot_app_3/features/groups/application/challenges_providers.dart';
import 'package:reboot_app_3/features/groups/presentation/widgets/add_task_modal.dart';

class EditChallengeScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String challengeId;

  const EditChallengeScreen({
    super.key,
    required this.groupId,
    required this.challengeId,
  });

  @override
  ConsumerState<EditChallengeScreen> createState() => _EditChallengeScreenState();
}

class _EditChallengeScreenState extends ConsumerState<EditChallengeScreen> {
  TextEditingController? _nameController;
  TextEditingController? _descriptionController;
  DateTime? _endDate;
  String _color = 'blue';
  List<ChallengeTaskEntity> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChallenge();
  }

  Future<void> _loadChallenge() async {
    final challenge = await ref.read(challengeByIdProvider(widget.challengeId).future);
    if (challenge != null && mounted) {
      setState(() {
        _nameController = TextEditingController(text: challenge.name);
        _descriptionController = TextEditingController(text: challenge.description);
        _endDate = challenge.endDate;
        _color = challenge.color;
        _tasks = List.from(challenge.tasks);
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController?.dispose();
    _descriptionController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.translate('edit-challenge'),
          style: TextStyles.screenHeadding.copyWith(color: theme.grey[900]),
        ),
        backgroundColor: theme.backgroundColor,
        surfaceTintColor: theme.backgroundColor,
        centerTitle: false,
      ),
      body: _isLoading || _nameController == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Challenge Name
                  _buildSectionLabel(theme, l10n, 'challenge-name'),
                  WidgetsContainer(
                    backgroundColor: theme.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.grey[800]!, width: 1),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextField(
                      controller: _nameController!,
                      decoration: InputDecoration(
                        hintText: l10n.translate('challenge-name-hint'),
                        hintStyle: TextStyles.caption.copyWith(color: theme.grey[600]),
                        border: InputBorder.none,
                      ),
                      style: TextStyles.caption,
                    ),
                  ),

                  verticalSpace(Spacing.points16),

                  // Challenge Description
                  _buildSectionLabel(theme, l10n, 'description'),
                  WidgetsContainer(
                    backgroundColor: theme.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.grey[800]!, width: 1),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      controller: _descriptionController!,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: l10n.translate('challenge-description-hint'),
                        hintStyle: TextStyles.caption.copyWith(color: theme.grey[600]),
                        border: InputBorder.none,
                      ),
                      style: TextStyles.caption,
                    ),
                  ),

                  verticalSpace(Spacing.points16),

                  // End Date
                  _buildSectionLabel(theme, l10n, 'challenge-end-date'),
                  PlatformDatePicker(
                    value: _endDate,
                    onChanged: (date) {
                      if (date != null) {
                        setState(() => _endDate = date);
                      }
                    },
                    dateFormatter: (date) =>
                        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  ),

                  verticalSpace(Spacing.points16),

                  // Color Picker
                  _buildSectionLabel(theme, l10n, 'color'),
                  _buildColorPicker(theme, _color),

                  verticalSpace(Spacing.points16),

                  // Tasks Section
                  _buildSectionLabel(theme, l10n, 'tasks'),
                  verticalSpace(Spacing.points8),
                  _buildTasksList(theme, l10n, _tasks),

                  verticalSpace(Spacing.points12),

                  // Add Task Button
                  _buildAddTaskButton(theme, l10n),

                  verticalSpace(Spacing.points32),

                  // Save Button
                  _buildSaveButton(theme, l10n),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionLabel(theme, AppLocalizations l10n, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        l10n.translate(key),
        style: TextStyles.h6.copyWith(
          color: theme.grey[900],
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _buildColorPicker(theme, String selectedColor) {
    // Convert color string (hex or named) to Color
    Color currentColor;
    if (selectedColor.startsWith('#')) {
      currentColor = Color(int.parse(selectedColor.substring(1), radix: 16) + 0xFF000000);
    } else {
      // Fallback for legacy named colors
      final colors = {
        'yellow': theme.warn[400]!,
        'coral': theme.tint[400]!,
        'blue': theme.secondary[400]!,
        'teal': theme.primary[400]!,
      };
      currentColor = colors[selectedColor] ?? theme.primary[400]!;
    }

    return GestureDetector(
      onTap: () async {
        await _showColorPickerDialog(context, theme, currentColor);
      },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: currentColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.palette,
              color: _getContrastColor(currentColor),
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context).translate('tap-to-change-color'),
              style: TextStyles.small.copyWith(
                color: _getContrastColor(currentColor),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get contrasting text color for background
  Color _getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  Future<void> _showColorPickerDialog(BuildContext context, theme, Color currentColor) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).translate('pick-color')),
          content: SingleChildScrollView(
            child: ColorPicker(
              color: currentColor,
              onColorChanged: (Color color) {
                // Convert Color to hex string
                final hexColor = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
                setState(() => _color = hexColor);
              },
              pickersEnabled: const {
                ColorPickerType.both: false,
                ColorPickerType.primary: true,
                ColorPickerType.accent: false,
                ColorPickerType.bw: false,
                ColorPickerType.custom: false,
                ColorPickerType.wheel: true,
              },
              enableShadesSelection: true,
              heading: Text(
                AppLocalizations.of(context).translate('select-color'),
                style: TextStyles.body,
              ),
              subheading: Text(
                AppLocalizations.of(context).translate('select-shade'),
                style: TextStyles.caption,
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context).translate('cancel')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(AppLocalizations.of(context).translate('done')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTasksList(theme, AppLocalizations l10n, List<ChallengeTaskEntity> tasks) {
    if (tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: tasks.asMap().entries.map((entry) {
        final index = entry.key;
        final task = entry.value;
        final frequencyLabel = _getFrequencyLabel(l10n, task.frequency);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: theme.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyles.caption.copyWith(
                      color: theme.grey[900],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.name,
                      style: TextStyles.body.copyWith(color: theme.grey[900]),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '$frequencyLabel • ${task.points} ${l10n.translate('points')}',
                          style: TextStyles.caption.copyWith(color: theme.grey[600]),
                        ),
                        if (task.allowRetroactiveCompletion) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.success[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              l10n.translate('flexible'),
                              style: TextStyles.caption.copyWith(
                                color: theme.success[700],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete, size: 20, color: theme.error[600]),
                onPressed: () {
                  setState(() {
                    _tasks = List.from(_tasks)..removeAt(index);
                  });
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAddTaskButton(theme, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () async {
        final task = await showModalBottomSheet<ChallengeTaskEntity>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AddTaskModal(nextOrder: _tasks.length),
        );

        if (task != null) {
          setState(() {
            _tasks = [..._tasks, task];
          });
        }
      },
      child: WidgetsContainer(
        backgroundColor: theme.primary[50],
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.primary[200]!, width: 1),
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Text(
            l10n.translate('add-task'),
            style: TextStyles.caption.copyWith(
              color: theme.grey[900],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(theme, AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primary[600],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          l10n.translate('save-changes'),
          style: TextStyles.h6.copyWith(
            color: theme.primary[50],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_nameController == null || _endDate == null) return;
    
    final name = _nameController!.text.trim();
    if (name.isEmpty || _tasks.isEmpty) {
      getErrorSnackBar(context, 'error-creating-challenge');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(challengesRepositoryProvider);
      final challenge = await repository.getChallengeById(widget.challengeId);

      if (challenge != null) {
        final updatedChallenge = challenge.copyWith(
          name: name,
          description: _descriptionController!.text.trim(),
          endDate: _endDate!,
          color: _color,
          tasks: _tasks,
          updatedAt: DateTime.now(),
        );

        await repository.updateChallenge(updatedChallenge);

        if (mounted) {
          getSuccessSnackBar(context, 'challenge-updated-successfully');
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        getErrorSnackBar(context, 'error-updating-challenge');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getFrequencyLabel(AppLocalizations l10n, TaskFrequency frequency) {
    switch (frequency) {
      case TaskFrequency.daily:
        return l10n.translate('daily');
      case TaskFrequency.weekly:
        return l10n.translate('weekly');
    }
  }
}

