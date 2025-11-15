import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/platform_date_picker.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/groups/domain/entities/challenge_task_entity.dart';
import 'package:reboot_app_3/features/groups/providers/challenge_creation_notifier.dart';
import 'package:reboot_app_3/features/groups/presentation/widgets/add_task_modal.dart';

class CreateChallengeScreen extends ConsumerStatefulWidget {
  final String groupId;

  const CreateChallengeScreen({
    super.key,
    required this.groupId,
  });

  @override
  ConsumerState<CreateChallengeScreen> createState() =>
      _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends ConsumerState<CreateChallengeScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final creationState = ref.watch(challengeCreationNotifierProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.translate('add-challenge'),
          style: TextStyles.screenHeadding.copyWith(color: theme.grey[900]),
        ),
        backgroundColor: theme.backgroundColor,
        surfaceTintColor: theme.backgroundColor,
        centerTitle: false,
      ),
      body: creationState.isLoading
          ? const Center(child: Spinner())
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
                      controller: _nameController,
                      onChanged: (value) {
                        ref.read(challengeCreationNotifierProvider.notifier).setName(value);
                      },
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
                      controller: _descriptionController,
                      onChanged: (value) {
                        ref.read(challengeCreationNotifierProvider.notifier).setDescription(value);
                      },
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

                  // Challenge Description
                  _buildSectionLabel(theme, l10n, 'description'),
                  WidgetsContainer(
                    backgroundColor: theme.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.grey[800]!, width: 1),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      controller: _descriptionController,
                      onChanged: (value) {
                        ref.read(challengeCreationNotifierProvider.notifier).setDescription(value);
                      },
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
                    value: creationState.endDate,
                    onChanged: (date) {
                      if (date != null) {
                        ref.read(challengeCreationNotifierProvider.notifier).setEndDate(date);
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
                  _buildColorPicker(theme, creationState.color),

                  verticalSpace(Spacing.points16),

                  // Tasks Section
                  _buildSectionLabel(theme, l10n, 'tasks'),
                  verticalSpace(Spacing.points8),
                  _buildTasksList(theme, l10n, creationState.tasks),

                  verticalSpace(Spacing.points12),

                  // Add Task Button
                  _buildAddTaskButton(theme, l10n),

                  verticalSpace(Spacing.points32),

                  // Submit Button
                  _buildSubmitButton(theme, l10n, creationState),
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
    final colors = {
      'yellow': theme.warn[400]!,
      'coral': theme.tint[400]!,
      'blue': theme.secondary[400]!,
      'teal': theme.primary[400]!,
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: colors.entries.map((entry) {
        final isSelected = entry.key == selectedColor;
        return GestureDetector(
          onTap: () {
            ref.read(challengeCreationNotifierProvider.notifier).setColor(entry.key);
          },
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            width: 85,
            height: 36,
            decoration: BoxDecoration(
              color: entry.value,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? theme.grey[900]! : entry.value.withValues(alpha: 0.5),
                width: isSelected ? 2 : 1,
              ),
            ),
          ),
        );
      }).toList(),
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
              // Order number
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

              // Task info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.name,
                      style: TextStyles.body.copyWith(color: theme.grey[900]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$frequencyLabel • ${task.points} ${l10n.translate('points')}',
                      style: TextStyles.caption.copyWith(color: theme.grey[600]),
                    ),
                  ],
                ),
              ),

              // Delete button
              IconButton(
                icon: Icon(LucideIcons.trash2, size: 20, color: theme.error[600]),
                onPressed: () {
                  ref.read(challengeCreationNotifierProvider.notifier).removeTask(index);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
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
          builder: (context) => AddTaskModal(
            nextOrder: ref.read(challengeCreationNotifierProvider).tasks.length,
          ),
        );

        if (task != null) {
          ref.read(challengeCreationNotifierProvider.notifier).addTask(task);
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

  Widget _buildSubmitButton(theme, AppLocalizations l10n, ChallengeCreationState state) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: state.isLoading ? null : () => _handleCreate(context, l10n),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primary[600],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          l10n.translate('add-exercise'),
          style: TextStyles.h6.copyWith(
            color: theme.primary[50],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _handleCreate(BuildContext context, AppLocalizations l10n) async {
    ref.read(challengeCreationNotifierProvider.notifier).clearError();

    final result =
        await ref.read(challengeCreationNotifierProvider.notifier).submit(widget.groupId);

    if (!mounted) return;

    if (result.success) {
      getSuccessSnackBar(context, 'challenge-created-successfully');
      context.pop();
    } else {
      getErrorSnackBar(context, 'error-creating-challenge');
    }
  }

  String _getFrequencyLabel(AppLocalizations l10n, TaskFrequency frequency) {
    switch (frequency) {
      case TaskFrequency.daily:
        return l10n.translate('daily');
      case TaskFrequency.weekly:
        return l10n.translate('weekly');
      case TaskFrequency.oneTime:
        return l10n.translate('one-time');
    }
  }
}
