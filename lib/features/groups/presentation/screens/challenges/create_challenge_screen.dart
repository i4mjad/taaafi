import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/platform_date_picker.dart';
import 'package:reboot_app_3/core/shared_widgets/platform_dropdown.dart';
import 'package:reboot_app_3/core/shared_widgets/platform_switch.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/groups/domain/entities/challenge_entity.dart';
import 'package:reboot_app_3/features/groups/providers/challenge_creation_notifier.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _goalTargetController = TextEditingController();
  final _maxParticipantsController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _goalTargetController.dispose();
    _maxParticipantsController.dispose();
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
          l10n.translate('create-challenge'),
          style: TextStyles.screenHeadding.copyWith(
            color: theme.grey[900],
          ),
        ),
        backgroundColor: theme.backgroundColor,
        surfaceTintColor: theme.backgroundColor,
        centerTitle: false,
      ),
      body: creationState.isLoading
          ? const Center(child: Spinner())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Challenge Type Display
                    _buildSectionHeader(theme, l10n, l10n.translate('challenge-type')),
                    _buildTypeDisplay(theme, l10n, creationState.type),

                    verticalSpace(Spacing.points24),

                    // Basic Information
                    _buildSectionHeader(theme, l10n, l10n.translate('basic-information')),
                    _buildBasicInfoSection(theme, l10n, creationState),

                    verticalSpace(Spacing.points24),

                    // Duration & Dates
                    _buildSectionHeader(theme, l10n, l10n.translate('duration-and-dates')),
                    _buildDurationSection(theme, l10n, creationState),

                    verticalSpace(Spacing.points24),

                    // Goal Settings (for goal-based challenges)
                    if (creationState.type == ChallengeType.goal ||
                        creationState.type == ChallengeType.team) ...[
                      _buildSectionHeader(theme, l10n, l10n.translate('goal-settings')),
                      _buildGoalSection(theme, l10n, creationState),
                      verticalSpace(Spacing.points24),
                    ],

                    // Challenge Settings
                    _buildSectionHeader(theme, l10n, l10n.translate('challenge-settings')),
                    _buildSettingsSection(theme, l10n, creationState),

                    verticalSpace(Spacing.points32),

                    // Create Button
                    _buildCreateButton(theme, l10n, creationState),

                    verticalSpace(Spacing.points16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(theme, AppLocalizations l10n, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyles.h5.copyWith(
          color: theme.grey[900],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTypeDisplay(theme, AppLocalizations l10n, ChallengeType type) {
    String labelKey;
    IconData icon;
    Color color;

    switch (type) {
      case ChallengeType.duration:
        labelKey = 'duration-challenge';
        icon = LucideIcons.clock;
        color = theme.primary[600]!;
        break;
      case ChallengeType.goal:
        labelKey = 'goal-challenge';
        icon = LucideIcons.target;
        color = theme.success[600]!;
        break;
      case ChallengeType.team:
        labelKey = 'team-challenge';
        icon = LucideIcons.users;
        color = theme.secondary[600]!;
        break;
      case ChallengeType.recurring:
        labelKey = 'recurring-challenge';
        icon = LucideIcons.repeat;
        color = theme.warn[600]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.translate(labelKey),
                  style: TextStyles.h6.copyWith(
                    color: theme.grey[900],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  l10n.translate('$labelKey-desc'),
                  style: TextStyles.caption.copyWith(
                    color: theme.grey[700],
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              l10n.translate('change'),
              style: TextStyles.small.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(
      theme, AppLocalizations l10n, ChallengeCreationState state) {
    _titleController.addListener(() {
      ref.read(challengeCreationNotifierProvider.notifier).setTitle(_titleController.text);
    });
    _descriptionController.addListener(() {
      ref.read(challengeCreationNotifierProvider.notifier).setDescription(_descriptionController.text);
    });

    return Column(
      children: [
        // Title
        WidgetsContainer(
          backgroundColor: theme.backgroundColor,
          borderRadius: BorderRadius.circular(10.5),
          borderSide: BorderSide(color: theme.grey[600]!, width: 0.75),
          cornerSmoothing: 0.8,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: _titleController,
            maxLength: 60,
            decoration: InputDecoration(
              labelText: l10n.translate('challenge-title'),
              hintText: l10n.translate('enter-challenge-title'),
              border: InputBorder.none,
              counterText: '${_titleController.text.length}/60',
            ),
            style: TextStyles.footnote,
          ),
        ),

        verticalSpace(Spacing.points16),

        // Description
        WidgetsContainer(
          backgroundColor: theme.backgroundColor,
          borderRadius: BorderRadius.circular(10.5),
          borderSide: BorderSide(color: theme.grey[600]!, width: 0.75),
          cornerSmoothing: 0.8,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _descriptionController,
            maxLength: 500,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: l10n.translate('description'),
              hintText: l10n.translate('describe-your-challenge'),
              border: InputBorder.none,
              counterText: '${_descriptionController.text.length}/500',
            ),
            style: TextStyles.footnote,
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSection(
      theme, AppLocalizations l10n, ChallengeCreationState state) {
    return Column(
      children: [
        // Start Date
        PlatformDatePicker(
          label: l10n.translate('start-date'),
          value: state.startDate,
          onChanged: (date) {
            if (date != null) {
              ref.read(challengeCreationNotifierProvider.notifier).setStartDate(date);
            }
          },
          dateFormatter: (date) =>
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        ),

        verticalSpace(Spacing.points16),

        // Duration Selector
        Row(
          children: [
            Expanded(
              child: PlatformDropdown<int>(
                label: l10n.translate('duration'),
                value: state.durationDays,
                items: [7, 14, 21, 30, 60, 90].map((days) {
                  return PlatformDropdownItem<int>(
                    value: days,
                    label: '$days ${l10n.translate('days')}',
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(challengeCreationNotifierProvider.notifier)
                        .setDuration(value);
                  }
                },
              ),
            ),
          ],
        ),

        verticalSpace(Spacing.points16),

        // End Date Display
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.calendar, size: 20, color: theme.grey[600]),
              const SizedBox(width: 8),
              Text(
                '${l10n.translate('ends-on')}: ${_formatDate(state.endDate)}',
                style: TextStyles.small.copyWith(color: theme.grey[700]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoalSection(
      theme, AppLocalizations l10n, ChallengeCreationState state) {
    _goalTargetController.addListener(() {
      final target = int.tryParse(_goalTargetController.text);
      ref
          .read(challengeCreationNotifierProvider.notifier)
          .setGoalTarget(target);
    });

    return Column(
      children: [
        // Goal Type
        PlatformDropdown<GoalType>(
          label: l10n.translate('goal-type'),
          value: state.goalType,
          items: [
            PlatformDropdownItem<GoalType>(
              value: GoalType.messages,
              label: l10n.translate('challenge-type-message-count'),
            ),
            PlatformDropdownItem<GoalType>(
              value: GoalType.daysActive,
              label: l10n.translate('challenge-type-active-days'),
            ),
            PlatformDropdownItem<GoalType>(
              value: GoalType.custom,
              label: l10n.translate('challenge-type-custom'),
            ),
          ],
          onChanged: (value) {
            ref.read(challengeCreationNotifierProvider.notifier).setGoalType(value);
          },
        ),

        verticalSpace(Spacing.points16),

        // Goal Target
        WidgetsContainer(
          backgroundColor: theme.backgroundColor,
          borderRadius: BorderRadius.circular(10.5),
          borderSide: BorderSide(color: theme.grey[600]!, width: 0.75),
          cornerSmoothing: 0.8,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: _goalTargetController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.translate('target-value'),
              hintText: l10n.translate('enter-goal-target'),
              border: InputBorder.none,
            ),
            style: TextStyles.footnote,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(
      theme, AppLocalizations l10n, ChallengeCreationState state) {
    _maxParticipantsController.addListener(() {
      final max = _maxParticipantsController.text.isEmpty
          ? null
          : int.tryParse(_maxParticipantsController.text);
      ref
          .read(challengeCreationNotifierProvider.notifier)
          .setMaxParticipants(max);
    });

    return Column(
      children: [
        // Max Participants
        WidgetsContainer(
          backgroundColor: theme.backgroundColor,
          borderRadius: BorderRadius.circular(10.5),
          borderSide: BorderSide(color: theme.grey[600]!, width: 0.75),
          cornerSmoothing: 0.8,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: _maxParticipantsController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.translate('max-participants'),
              hintText: l10n.translate('leave-empty-for-unlimited'),
              border: InputBorder.none,
            ),
            style: TextStyles.footnote,
          ),
        ),

        verticalSpace(Spacing.points16),

        // Allow Late Join
        PlatformSwitch(
          value: state.allowLateJoin,
          onChanged: (_) {
            ref
                .read(challengeCreationNotifierProvider.notifier)
                .toggleAllowLateJoin();
          },
          label: l10n.translate('allow-late-join'),
          subtitle: l10n.translate('allow-late-join-description'),
        ),

        verticalSpace(Spacing.points16),

        // Notify on Milestone
        PlatformSwitch(
          value: state.notifyOnMilestone,
          onChanged: (_) {
            ref
                .read(challengeCreationNotifierProvider.notifier)
                .toggleNotifyOnMilestone();
          },
          label: l10n.translate('milestone-notifications'),
          subtitle: l10n.translate('milestone-notifications-description'),
        ),
      ],
    );
  }

  Widget _buildCreateButton(
      theme, AppLocalizations l10n, ChallengeCreationState state) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: state.isLoading ? null : () => _handleCreate(context, l10n),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primary[600],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: state.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                l10n.translate('create-challenge-button'),
                style: TextStyles.h6.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _handleCreate(BuildContext context, AppLocalizations l10n) async {
    // Clear previous errors
    ref.read(challengeCreationNotifierProvider.notifier).clearError();

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Submit challenge
    final result = await ref
        .read(challengeCreationNotifierProvider.notifier)
        .submit(widget.groupId);

    if (!mounted) return;

    if (result.success) {
      // Show success message
      getSuccessSnackBar(
        context,
        'challenge-created-successfully',
      );

      // Navigate back to challenges list
      context.pop();
      context.pop(); // Also pop the type selection screen
    } else {
      // Show error message
      getErrorSnackBar(
        context,
        'error-creating-challenge',
      );
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

