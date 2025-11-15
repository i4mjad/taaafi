import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/platform_dropdown.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/groups/domain/entities/challenge_task_entity.dart';

class AddTaskModal extends StatefulWidget {
  final ChallengeTaskEntity? existingTask;
  final int nextOrder;

  const AddTaskModal({
    super.key,
    this.existingTask,
    this.nextOrder = 0,
  });

  @override
  State<AddTaskModal> createState() => _AddTaskModalState();
}

class _AddTaskModalState extends State<AddTaskModal> {
  late TextEditingController _nameController;
  late TextEditingController _pointsController;
  late TaskFrequency _selectedFrequency;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingTask?.name ?? '');
    _pointsController = TextEditingController(
        text: widget.existingTask?.points.toString() ?? '');
    _selectedFrequency = widget.existingTask?.frequency ?? TaskFrequency.daily;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.translate('add-task'),
                style: TextStyles.h4.copyWith(
                  color: theme.grey[900],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task Name
                    WidgetsContainer(
                      backgroundColor: theme.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.grey[800]!, width: 1),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: l10n.translate('task-name-hint'),
                          border: InputBorder.none,
                        ),
                        style: TextStyles.caption,
                      ),
                    ),

                    verticalSpace(Spacing.points16),

                    // Points and Frequency Row
                    Row(
                      children: [
                        // Points
                        Expanded(
                          child: WidgetsContainer(
                            backgroundColor: theme.backgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: theme.grey[800]!, width: 1),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: TextField(
                              controller: _pointsController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              decoration: InputDecoration(
                                hintText: l10n.translate('points-count'),
                                border: InputBorder.none,
                              ),
                              style: TextStyles.caption,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Frequency
                        Expanded(
                          child: PlatformDropdown<TaskFrequency>(
                            value: _selectedFrequency,
                            items: [
                              PlatformDropdownItem(
                                value: TaskFrequency.daily,
                                label: l10n.translate('daily'),
                              ),
                              PlatformDropdownItem(
                                value: TaskFrequency.weekly,
                                label: l10n.translate('weekly'),
                              ),
                              PlatformDropdownItem(
                                value: TaskFrequency.oneTime,
                                label: l10n.translate('one-time'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedFrequency = value);
                              }
                            },
                            backgroundColor: theme.backgroundColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        l10n.translate('close'),
                        style: TextStyles.body.copyWith(
                          color: theme.grey[900],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Add Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleAdd,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.success[600],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        l10n.translate('add'),
                        style: TextStyles.body.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAdd() {
    final name = _nameController.text.trim();
    final pointsText = _pointsController.text.trim();

    if (name.isEmpty || pointsText.isEmpty) {
      return;
    }

    final points = int.tryParse(pointsText);
    if (points == null || points <= 0) {
      return;
    }

    final task = ChallengeTaskEntity(
      id: widget.existingTask?.id ?? 'task_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      points: points,
      frequency: _selectedFrequency,
      order: widget.existingTask?.order ?? widget.nextOrder,
    );

    Navigator.pop(context, task);
  }
}

