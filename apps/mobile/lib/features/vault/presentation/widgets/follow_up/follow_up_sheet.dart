import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/data/calendar/calendar_notifier.dart';
import 'package:reboot_app_3/features/vault/data/models/emotion.dart';
import 'package:reboot_app_3/features/vault/data/models/emotion_model.dart';
import 'package:reboot_app_3/features/vault/data/models/follow_up_option.dart';
import 'package:reboot_app_3/features/vault/data/statistics/statistics_notifier.dart';
import 'package:reboot_app_3/features/vault/data/streaks/streak_notifier.dart';
import 'package:reboot_app_3/features/vault/data/streaks/streak_duration_notifier.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';
import 'package:time_picker_spinner_pop_up/time_picker_spinner_pop_up.dart';
import 'package:reboot_app_3/features/vault/data/follow_up/follow_up_notifier.dart';
import 'package:reboot_app_3/features/vault/data/emotions/emotion_notifier.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/statistics/statistics_widget.dart';
import 'package:reboot_app_3/features/plus/data/notifiers/subscription_notifier.dart';
import 'package:reboot_app_3/features/plus/presentation/taaafi_plus_features_list_screen.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/groups/providers/group_membership_provider.dart';
import 'package:reboot_app_3/features/groups/application/updates_providers.dart';
import 'package:reboot_app_3/features/groups/domain/entities/group_update_entity.dart';
import 'package:reboot_app_3/core/shared_widgets/platform_checkbox.dart';

// Common triggers for relapse incidents
const List<String> availableTriggers = [
  'stress',
  'boredom',
  'loneliness',
  'late-night',
  'social-media',
  'urges',
  'anxiety',
  'anger',
  'sadness',
  'peer-pressure',
];

class FollowUpSheet extends ConsumerStatefulWidget {
  FollowUpSheet(this.date, {super.key});

  DateTime date;
  @override
  _FollowUpSheetState createState() => _FollowUpSheetState();
}

class _FollowUpSheetState extends ConsumerState<FollowUpSheet> {
  Set<FollowUpOption> selectedFollowUps = {};
  Set<Emotion> selectedEmotions = {};
  Set<String> selectedTriggers = {}; // New state for selected triggers
  bool addAllFollowUps = false; // New state for checkbox
  bool _isProcessing = false;
  bool _showTriggers = false; // New state for showing triggers section

  // Group sharing state
  bool _shareToGroup = false;
  String? _selectedGroupId;

  final List<FollowUpOption> followUpOptions = [
    FollowUpOption(icon: LucideIcons.trophy, translationKey: 'free-day'),
    FollowUpOption(icon: LucideIcons.planeLanding, translationKey: 'slipUp'),
    FollowUpOption(icon: LucideIcons.heartCrack, translationKey: 'relapse'),
    FollowUpOption(icon: LucideIcons.play, translationKey: 'pornOnly'),
    FollowUpOption(icon: LucideIcons.hand, translationKey: 'mastOnly'),
  ];

  void toggleFollowUp(FollowUpOption followUpOption) {
    setState(() {
      if (followUpOption.translationKey == 'free-day') {
        if (selectedFollowUps.contains(followUpOption)) {
          selectedFollowUps.remove(followUpOption);
        } else {
          selectedFollowUps.clear();
          selectedFollowUps.add(followUpOption);
          addAllFollowUps = false;
        }
      } else {
        selectedFollowUps
            .removeWhere((option) => option.translationKey == 'free-day');

        if (selectedFollowUps.contains(followUpOption)) {
          selectedFollowUps.remove(followUpOption);
          if (followUpOption.translationKey == 'relapse') {
            addAllFollowUps = false;
          }
        } else {
          selectedFollowUps.add(followUpOption);
          if (followUpOption.translationKey == 'relapse') {
            addAllFollowUps = true;
          }
        }
      }
    });
    HapticFeedback.selectionClick();
  }

  void toggleEmotion(Emotion emotion) {
    setState(() {
      if (selectedEmotions.contains(emotion)) {
        selectedEmotions.remove(emotion);
      } else {
        selectedEmotions.add(emotion);
      }
    });
    HapticFeedback.selectionClick(); // Haptic feedback on selection
  }

  void toggleTrigger(String trigger) {
    setState(() {
      if (selectedTriggers.contains(trigger)) {
        selectedTriggers.remove(trigger);
      } else {
        selectedTriggers.add(trigger);
      }
    });
    HapticFeedback.selectionClick(); // Haptic feedback on selection
  }

  Future<void> _saveFollowUpsAndEmotions() async {
    final followUpNotifier = ref.read(followUpNotifierProvider.notifier);
    final emotionNotifier = ref.read(emotionNotifierProvider.notifier);

    if (selectedFollowUps
        .any((option) => option.translationKey == 'free-day')) {
      await followUpNotifier.deleteFollowUpsByDate(widget.date);
      return;
    }

    // Build a deduplicated set of follow-up keys to create
    final Set<String> followUpKeysToCreate = {};
    final bool relapseSelected =
        selectedFollowUps.any((o) => o.translationKey == 'relapse');

    if (relapseSelected && addAllFollowUps) {
      // Include all available follow-ups except "free-day" (none)
      followUpKeysToCreate.addAll(
        followUpOptions
            .where((o) => o.translationKey != 'free-day')
            .map((o) => o.translationKey),
      );
    } else {
      // Include only those the user selected
      followUpKeysToCreate
          .addAll(selectedFollowUps.map((o) => o.translationKey));
    }

    final followUps = followUpKeysToCreate.map((key) {
      return FollowUpModel(
        id: '', // ID will be generated by Firestore
        type: _mapTranslationKeyToType(key),
        time: widget.date,
        triggers: _shouldIncludeTriggers(key) ? selectedTriggers.toList() : [],
      );
    }).toList();

    final emotions = selectedEmotions.map((emotion) {
      return EmotionModel(
        id: '', // ID will be generated by Firestore
        emotionEmoji: emotion.emotionEmoji,
        emotionName: emotion.emotionNameTranslationKey,
        date: widget.date,
      );
    }).toList();

    await followUpNotifier.createMultipleFollowUps(followUps);
    await emotionNotifier.createMultipleEmotions(emotions);

    // Share to group if enabled
    if (_shareToGroup && _selectedGroupId != null && followUps.isNotEmpty) {
      await _shareFollowupToGroup(followUps.first);
    }
  }

  /// Show emotions selection sheet
  Future<void> _showEmotionsSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => EmotionsSelectionSheet(
        selectedEmotions: selectedEmotions,
        badEmotions: badEmotions,
        goodEmotions: goodEmotions,
        onEmotionToggle: (emotion) {
          setState(() {
            toggleEmotion(emotion);
          });
        },
      ),
    );
  }

  /// Share followup to selected group
  Future<void> _shareFollowupToGroup(FollowUpModel followup) async {
    try {
      // Get current community profile
      final currentProfile =
          await ref.read(currentCommunityProfileProvider.future);
      if (currentProfile == null) return;

      // Validate gender - user MUST have a valid gender
      final gender = currentProfile.gender.toLowerCase();
      if (gender != 'male' && gender != 'female') {
        print('Cannot share update: invalid gender "$gender"');
        return;
      }

      // Get localized content based on followup type and gender
      final l10n = AppLocalizations.of(context);
      String content;

      switch (followup.type) {
        case FollowUpType.relapse:
          // Gender-specific message for relapse - NO DEFAULT
          content = gender == 'female'
              ? l10n.translate('relapse-update-content-female')
              : l10n.translate('relapse-update-content-male');
          break;
        case FollowUpType.pornOnly:
          content = l10n.translate('porn-only-update-content');
          break;
        case FollowUpType.mastOnly:
          content = l10n.translate('mast-only-update-content');
          break;
        case FollowUpType.slipUp:
          content = l10n.translate('slip-up-update-content');
          break;
        case FollowUpType.none:
          return; // Don't share 'none' type
      }

      // Post update with translated content
      // Use the profile's isAnonymous setting
      final controller = ref.read(postUpdateControllerProvider.notifier);
      await controller.postUpdate(
        groupId: _selectedGroupId!,
        type: UpdateType.struggle,
        title: '',
        content: content,
        linkedFollowupId: followup.id,
        isAnonymous: currentProfile.isAnonymous,
      );
    } catch (e) {
      // Silently fail - followup is already saved, sharing is optional
      print('Failed to share followup to group: $e');
    }
  }

  /// Maps translation keys to FollowUpType enum values
  FollowUpType _mapTranslationKeyToType(String translationKey) {
    switch (translationKey) {
      case 'free-day':
        return FollowUpType.none;
      case 'slipUp':
        return FollowUpType.slipUp;
      case 'relapse':
        return FollowUpType.relapse;
      case 'pornOnly':
        return FollowUpType.pornOnly;
      case 'mastOnly':
        return FollowUpType.mastOnly;
      default:
        return FollowUpType.relapse; // fallback
    }
  }

  /// Determines if triggers should be included for a specific follow-up type
  bool _shouldIncludeTriggers(String translationKey) {
    // Only include triggers for relapse-related follow-ups (not for "free-day")
    return translationKey != 'free-day';
  }

  /// Determines if the triggers section should be shown
  bool _shouldShowTriggers() {
    // Only show triggers for relapse-related follow-ups (not for "free-day")
    return selectedFollowUps
        .any((option) => option.translationKey != 'free-day');
  }

  /// Builds the trigger selection section with premium blur strategy
  Widget _buildTriggerSection(BuildContext context, CustomThemeData theme) {
    final hasSubscription = ref.watch(hasActiveSubscriptionProvider);

    final triggerContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('common-triggers'),
          style: TextStyles.footnoteSelected.copyWith(
            color: theme.grey[700],
          ),
        ),
        verticalSpace(Spacing.points8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableTriggers.map((trigger) {
            return TriggerButton(
              trigger: trigger,
              isSelected: selectedTriggers.contains(trigger),
              onTap: hasSubscription ? () => toggleTrigger(trigger) : null,
            );
          }).toList(),
        ),
      ],
    );

    if (hasSubscription) {
      return triggerContent;
    } else {
      return _buildBlurredTriggerContent(context, theme, triggerContent);
    }
  }

  /// Check if group sharing section should be shown
  bool _shouldShowGroupSharing() {
    // Only show for shareable types (not free-day)
    return selectedFollowUps.isNotEmpty &&
        !selectedFollowUps.any((option) => option.translationKey == 'free-day');
  }

  /// Build group sharing section with edge case handling
  Widget _buildGroupSharingSection(
      BuildContext context, CustomThemeData theme) {
    final currentProfileAsync = ref.watch(currentCommunityProfileProvider);
    final groupMembershipAsync = ref.watch(groupMembershipNotifierProvider);

    return currentProfileAsync.when(
      data: (profile) {
        // Edge case 1: No community profile
        if (profile == null) {
          return _buildNoCommunityProfileWarning(context, theme);
        }

        return groupMembershipAsync.when(
          data: (membership) {
            // Edge case 2: Not part of any group
            if (membership == null) {
              return _buildNoGroupsWarning(context, theme);
            }

            // Set the group ID automatically
            if (_shareToGroup && _selectedGroupId == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  _selectedGroupId = membership.group.id;
                });
              });
            }

            // Normal flow: Show group sharing options
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox to enable sharing
                PlatformCheckboxListTile(
                  value: _shareToGroup,
                  onChanged: (value) {
                    setState(() {
                      _shareToGroup = value!;
                      if (_shareToGroup && _selectedGroupId == null) {
                        _selectedGroupId = membership.group.id;
                      }
                    });
                  },
                  title: Text(
                    AppLocalizations.of(context).translate('share-to-group'),
                    style: TextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: _shareToGroup
                      ? Text(
                          AppLocalizations.of(context)
                              .translate('update-preview-will-appear-below'),
                          style: TextStyles.small.copyWith(
                            color: theme.grey[600],
                          ),
                        )
                      : null,
                  contentPadding: EdgeInsets.zero,
                ),

                // Group info and preview (only if enabled)
                if (_shareToGroup) ...[
                  verticalSpace(Spacing.points8),
                  WidgetsContainer(
                    padding: const EdgeInsets.all(12),
                    backgroundColor: theme.primary[50],
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: theme.primary[200]!,
                      width: 1,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Group display
                        Row(
                          children: [
                            Icon(
                              LucideIcons.users,
                              color: theme.primary[600],
                              size: 16,
                            ),
                            horizontalSpace(Spacing.points8),
                            Expanded(
                              child: Text(
                                '${AppLocalizations.of(context).translate('sharing-to')}: ${membership.group.name}',
                                style: TextStyles.small.copyWith(
                                  color: theme.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        verticalSpace(Spacing.points12),

                        // Update Preview (using profile's isAnonymous setting)
                        _buildUpdatePreview(context, theme,
                            membership.group.name, profile.isAnonymous),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => _buildNoCommunityProfileWarning(context, theme),
    );
  }

  /// Warning when user has no community profile
  Widget _buildNoCommunityProfileWarning(
      BuildContext context, CustomThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.warn[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.warn[300]!,
          width: 0.75,
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.info,
            color: theme.warn[700],
            size: 20,
          ),
          horizontalSpace(Spacing.points8),
          Expanded(
            child: Text(
              AppLocalizations.of(context)
                  .translate('create-community-profile-to-share'),
              style: TextStyles.small.copyWith(color: theme.warn[700]),
            ),
          ),
        ],
      ),
    );
  }

  /// Build update preview
  Widget _buildUpdatePreview(BuildContext context, CustomThemeData theme,
      String groupName, bool isAnonymous) {
    final l10n = AppLocalizations.of(context);

    // Get gender from current profile for gender-aware content
    final currentProfileAsync = ref.watch(currentCommunityProfileProvider);
    String? gender; // No default - must be set
    currentProfileAsync.whenData((profile) {
      if (profile != null) {
        final g = profile.gender.toLowerCase();
        if (g == 'male' || g == 'female') {
          gender = g;
        }
      }
    });

    // Get preview content based on selected followup
    String previewContent = '';
    if (selectedFollowUps.isNotEmpty) {
      // Check if we have a valid gender for gender-specific content
      if (gender == null) {
        previewContent = l10n.translate('invalid-gender-error');
      } else {
        final followupType = selectedFollowUps.first.translationKey;
        switch (followupType) {
          case 'relapse':
            // Gender-specific message for relapse - NO DEFAULT
            previewContent = gender == 'female'
                ? l10n.translate('relapse-update-content-female')
                : l10n.translate('relapse-update-content-male');
            break;
          case 'pornOnly':
            previewContent = l10n.translate('porn-only-update-content');
            break;
          case 'mastOnly':
            previewContent = l10n.translate('mast-only-update-content');
            break;
          case 'slipUp':
            previewContent = l10n.translate('slip-up-update-content');
            break;
          default:
            previewContent = l10n.translate('general-update-content');
        }
      }
    }

    return WidgetsContainer(
      padding: const EdgeInsets.all(10),
      backgroundColor: theme.backgroundColor,
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: theme.grey[200]!,
        width: 1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: theme.primary[100],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    LucideIcons.helpCircle,
                    size: 14,
                    color: theme.primary[600],
                  ),
                ),
              ),
              horizontalSpace(Spacing.points8),
              Expanded(
                child: Text(
                  isAnonymous
                      ? l10n.translate('anonymous-member')
                      : l10n.translate('you'),
                  style: TextStyles.small.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                l10n.translate('just-now-time'),
                style: TextStyles.small.copyWith(
                  color: theme.grey[500],
                ),
              ),
            ],
          ),
          verticalSpace(Spacing.points8),
          Text(
            previewContent,
            style: TextStyles.small.copyWith(
              color: theme.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  /// Warning when user is not part of any group
  Widget _buildNoGroupsWarning(BuildContext context, CustomThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.tint[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.tint[300]!,
          width: 0.75,
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.users,
            color: theme.tint[700],
            size: 20,
          ),
          horizontalSpace(Spacing.points8),
          Expanded(
            child: Text(
              AppLocalizations.of(context).translate('join-group-to-share'),
              style: TextStyles.small.copyWith(color: theme.tint[700]),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds blurred trigger content for non-premium users
  Widget _buildBlurredTriggerContent(
    BuildContext context,
    CustomThemeData theme,
    Widget content,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          useSafeArea: true,
          builder: (context) => const TaaafiPlusSubscriptionScreen(),
        );
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 80,
          maxHeight: 150,
        ),
        child: Stack(
          children: [
            // Original content (visible through blur)
            SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: content,
            ),

            // Blur overlay matching vault screen strategy
            Positioned.fill(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.3),
                          Colors.white.withValues(alpha: 0.6),
                          Colors.white.withValues(alpha: 0.8),
                          Colors.white.withValues(alpha: 0.6),
                        ],
                        stops: const [0.0, 0.3, 0.7, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),

            // Lock icon and upgrade text
            Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.lock,
                      color: theme.primary[600],
                      size: 24,
                    ),
                    verticalSpace(Spacing.points4),
                    Text(
                      AppLocalizations.of(context)
                          .translate('upgrade-to-unlock'),
                      style: TextStyles.small.copyWith(
                        color: theme.primary[600],
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeNotifierProvider);
    final theme = AppTheme.of(context);

    // Get free day option and other options separately
    final freeDayOption = followUpOptions
        .firstWhere((option) => option.translationKey == 'free-day');
    final otherOptions = followUpOptions
        .where((option) => option.translationKey != 'free-day')
        .toList();

    return Container(
      color: theme.backgroundColor,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fixed top row with date picker
          Container(
            decoration: BoxDecoration(
              color: theme.backgroundColor,
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
                TimePickerSpinnerPopUp(
                  maxTime: DateTime.now(),
                  mode: CupertinoDatePickerMode.dateAndTime,
                  barrierColor: theme.primary[50]!,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  locale: locale,
                  cancelTextStyle: TextStyles.caption.copyWith(
                    color: theme.primary[600],
                  ),
                  confirmTextStyle: TextStyles.caption.copyWith(
                    color: theme.primary[600],
                  ),
                  textStyle: TextStyles.caption.copyWith(
                    color: theme.primary[600],
                  ),
                  timeFormat: "d - MMMM - yyyy hh:mm a",
                  timeWidgetBuilder: (dateTime) {
                    return WidgetsContainer(
                      padding: EdgeInsets.all(8),
                      backgroundColor: theme.backgroundColor,
                      borderSide:
                          BorderSide(color: theme.grey[600]!, width: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(60, 64, 67, 0.3),
                          blurRadius: 2,
                          spreadRadius: 0,
                          offset: Offset(
                            0,
                            1,
                          ),
                        ),
                        BoxShadow(
                          color: Color.fromRGBO(60, 64, 67, 0.15),
                          blurRadius: 6,
                          spreadRadius: 2,
                          offset: Offset(
                            0,
                            2,
                          ),
                        ),
                      ],
                      child: Text(
                        getDisplayDateTime(dateTime, locale!.languageCode),
                        style: TextStyles.body,
                      ),
                    );
                  },
                  initTime: widget.date,
                  cancelText: AppLocalizations.of(context).translate("cancel"),
                  confirmText:
                      AppLocalizations.of(context).translate("confirm"),
                  onChange: (date) {
                    setState(() {
                      widget.date = date;
                    });
                  },
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Icon(
                    LucideIcons.xCircle,
                  ),
                )
              ],
            ),
          ),

          // Scrollable middle content
          Flexible(
            fit: FlexFit.loose,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)
                        .translate('what-you-want-to-add'),
                    style: TextStyles.h6,
                  ),
                  verticalSpace(Spacing.points8),
                  // Free day option at the top
                  FollowUpButton(
                    followUpOption: freeDayOption,
                    isSelected: selectedFollowUps.contains(freeDayOption),
                    onTap: () => toggleFollowUp(freeDayOption),
                  ),
                  verticalSpace(Spacing.points8),
                  // Other options in grid
                  Column(
                    children: [
                      for (int i = 0; i < otherOptions.length; i += 2)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: FollowUpButton(
                                  followUpOption: otherOptions[i],
                                  isSelected: selectedFollowUps
                                      .contains(otherOptions[i]),
                                  onTap: () => toggleFollowUp(otherOptions[i]),
                                ),
                              ),
                              if (i + 1 < otherOptions.length) ...[
                                horizontalSpace(Spacing.points8),
                                Expanded(
                                  child: FollowUpButton(
                                    followUpOption: otherOptions[i + 1],
                                    isSelected: selectedFollowUps
                                        .contains(otherOptions[i + 1]),
                                    onTap: () =>
                                        toggleFollowUp(otherOptions[i + 1]),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                  verticalSpace(Spacing.points8),

                  // Warning message moved here, after the options
                  if (selectedFollowUps
                      .any((option) => option.translationKey == 'free-day'))
                    WidgetsContainer(
                      padding: const EdgeInsets.all(12),
                      backgroundColor: theme.success[50],
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: theme.success[300]!,
                        width: 0.75,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.star,
                            color: theme.success[700],
                          ),
                          horizontalSpace(Spacing.points8),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)
                                  .translate('free-day-warning-message'),
                              style: TextStyles.small.copyWith(
                                  color: theme.success[700], height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (selectedFollowUps
                      .any((option) => option.translationKey == 'relapse'))
                    Column(
                      children: [
                        verticalSpace(Spacing.points8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: addAllFollowUps,
                              onChanged: (value) {
                                setState(() {
                                  addAllFollowUps = value!;
                                });
                              },
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)
                                        .translate('add-all-follow-ups'),
                                    style: TextStyles.smallBold,
                                  ),
                                  verticalSpace(Spacing.points4),
                                  Text(
                                    AppLocalizations.of(context)
                                        .translate('add-all-follow-ups-desc'),
                                    style: TextStyles.small.copyWith(
                                      color: theme.grey[500],
                                    ),
                                    softWrap: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                  // Group Sharing Section - Only show for shareable followup types
                  if (_shouldShowGroupSharing()) ...[
                    verticalSpace(Spacing.points16),
                    _buildGroupSharingSection(context, theme),
                  ],

                  verticalSpace(Spacing.points16),
                  GestureDetector(
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      await _showEmotionsSheet(context);
                    },
                    child: WidgetsContainer(
                      padding: EdgeInsets.all(12),
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
                            child: selectedEmotions.isEmpty
                                ? Text(
                                    AppLocalizations.of(context)
                                        .translate('how-do-you-feel'),
                                    style: TextStyles.caption,
                                  )
                                : Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: selectedEmotions.map((emotion) {
                                      return Container(
                                        width: 40,
                                        height: 40,
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
                                            emotion.emotionEmoji,
                                            style: TextStyles.body,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ),
                          horizontalSpace(Spacing.points8),
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

                  // Trigger Selection Section - Only show for relapse-related follow-ups
                  if (_shouldShowTriggers()) ...[
                    verticalSpace(Spacing.points16),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showTriggers = !_showTriggers;
                        });
                        HapticFeedback.selectionClick();
                      },
                      child: WidgetsContainer(
                        padding: EdgeInsets.all(12),
                        backgroundColor: theme.primary[50],
                        borderSide: BorderSide(
                          color: theme.primary[200]!,
                          width: 0.75,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.zap,
                                  color: theme.primary[600],
                                  size: 16,
                                ),
                                horizontalSpace(Spacing.points8),
                                Text(
                                  AppLocalizations.of(context)
                                      .translate('what-triggered-you'),
                                  style: TextStyles.caption,
                                ),
                              ],
                            ),
                            Icon(
                              _showTriggers
                                  ? LucideIcons.chevronUp
                                  : (locale?.languageCode == 'ar'
                                      ? LucideIcons.chevronLeft
                                      : LucideIcons.chevronRight),
                              color: theme.grey[600],
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_showTriggers) ...[
                      verticalSpace(Spacing.points8),
                      _buildTriggerSection(context, theme),
                    ],
                  ],
                ],
              ),
            ),
          ),

          // Fixed bottom row with save/cancel buttons
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
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _isProcessing
                        ? null
                        : () async {
                            setState(() => _isProcessing = true);

                            try {
                              await _saveFollowUpsAndEmotions();
                              if (mounted) {
                                await Future.wait([
                                  ref.refresh(
                                      statisticsNotifierProvider.future),
                                  ref.refresh(streakNotifierProvider.future),
                                  ref.refresh(followUpNotifierProvider.future),
                                  ref.refresh(calendarNotifierProvider.future),
                                ]);

                                // Refresh the followUpsProvider
                                await ref
                                    .read(followUpsProvider.notifier)
                                    .refreshFollowUps();

                                // Refresh the detailed streak provider
                                await ref
                                    .read(detailedStreakProvider.notifier)
                                    .refreshDurations();

                                Navigator.pop(context);
                              }
                            } catch (e) {
                              if (mounted) {
                                setState(() => _isProcessing = false);
                              }
                            }
                          },
                    child: WidgetsContainer(
                      borderRadius: BorderRadius.circular(10),
                      backgroundColor:
                          _isProcessing ? theme.grey[400] : theme.primary[600],
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isProcessing) ...[
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: Spinner(
                                  strokeWidth: 2,
                                  valueColor: theme.grey[50]!,
                                ),
                              ),
                              horizontalSpace(Spacing.points8),
                              Text(
                                AppLocalizations.of(context)
                                    .translate('saving'),
                                style: TextStyles.caption
                                    .copyWith(color: theme.grey[50]),
                              ),
                            ] else
                              Text(
                                AppLocalizations.of(context).translate('save'),
                                style: TextStyles.caption
                                    .copyWith(color: theme.grey[50]),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                horizontalSpace(Spacing.points8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    child: WidgetsContainer(
                      borderRadius: BorderRadius.circular(10),
                      backgroundColor: theme.backgroundColor,
                      borderSide:
                          BorderSide(color: theme.grey[600]!, width: 0.25),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context).translate('cancel'),
                          style: TextStyles.caption
                              .copyWith(color: theme.grey[900]),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FollowUpButton extends StatelessWidget {
  const FollowUpButton({
    required this.followUpOption,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final FollowUpOption followUpOption;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: WidgetsContainer(
        padding: EdgeInsets.all(12),
        backgroundColor: theme.backgroundColor,
        borderSide: BorderSide(
          color: isSelected ? theme.success[600]! : theme.grey[600]!,
          width: isSelected ? 1 : 0.5,
        ),
        child: Row(
          children: [
            Icon(
              followUpOption.icon,
              color: theme.primary[600],
              size: 20,
            ),
            horizontalSpace(Spacing.points8),
            Text(
              AppLocalizations.of(context)
                  .translate(followUpOption.translationKey),
              style: TextStyles.small,
            ),
          ],
        ),
      ),
    );
  }
}

class EmotionButton extends StatelessWidget {
  const EmotionButton({
    required this.emotion,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final Emotion emotion;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return IntrinsicWidth(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: WidgetsContainer(
          padding: EdgeInsets.all(4),
          backgroundColor: theme.backgroundColor,
          borderSide: BorderSide(
            color: isSelected ? theme.success[600]! : theme.grey[600]!,
            width: isSelected ? 0.75 : 0.25,
          ),
          borderRadius: BorderRadius.circular(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                emotion.emotionEmoji,
                style: TextStyles.bodyLarge.copyWith(height: 1.2),
              ),
              horizontalSpace(Spacing.points4),
              Text(
                AppLocalizations.of(context)
                    .translate(emotion.emotionNameTranslationKey),
                style: TextStyles.small,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TriggerButton extends StatelessWidget {
  const TriggerButton({
    required this.trigger,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final String trigger;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return IntrinsicWidth(
      child: GestureDetector(
        onTap: onTap != null
            ? () {
                HapticFeedback.selectionClick();
                onTap!();
              }
            : null,
        child: WidgetsContainer(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          backgroundColor:
              isSelected ? theme.primary[50] : theme.backgroundColor,
          borderSide: BorderSide(
            color: isSelected ? theme.primary[600]! : theme.grey[400]!,
            width: isSelected ? 1.5 : 0.5,
          ),
          borderRadius: BorderRadius.circular(16),
          child: Text(
            AppLocalizations.of(context).translate(trigger),
            style: TextStyles.small.copyWith(
              color: isSelected ? theme.primary[700] : theme.grey[700],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

// Stateful widget for emotions selection sheet
class EmotionsSelectionSheet extends StatefulWidget {
  final Set<Emotion> selectedEmotions;
  final List<Emotion> badEmotions;
  final List<Emotion> goodEmotions;
  final Function(Emotion) onEmotionToggle;

  const EmotionsSelectionSheet({
    super.key,
    required this.selectedEmotions,
    required this.badEmotions,
    required this.goodEmotions,
    required this.onEmotionToggle,
  });

  @override
  State<EmotionsSelectionSheet> createState() => _EmotionsSelectionSheetState();
}

class _EmotionsSelectionSheetState extends State<EmotionsSelectionSheet> {
  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
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
                  AppLocalizations.of(context).translate('how-do-you-feel'),
                  style: TextStyles.h6,
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(LucideIcons.x, size: 24),
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            fit: FlexFit.loose,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).translate('negative-feelings'),
                    style: TextStyles.footnoteSelected.copyWith(
                      color: theme.grey[700],
                    ),
                  ),
                  verticalSpace(Spacing.points8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.badEmotions.map((emotion) {
                      return EmotionButton(
                        emotion: emotion,
                        isSelected: widget.selectedEmotions.contains(emotion),
                        onTap: () {
                          widget.onEmotionToggle(emotion);
                          setState(() {}); // Update UI in real-time
                        },
                      );
                    }).toList(),
                  ),
                  verticalSpace(Spacing.points16),
                  Text(
                    AppLocalizations.of(context).translate('positive-feelings'),
                    style: TextStyles.footnoteSelected.copyWith(
                      color: theme.grey[700],
                    ),
                  ),
                  verticalSpace(Spacing.points8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.goodEmotions.map((emotion) {
                      return EmotionButton(
                        emotion: emotion,
                        isSelected: widget.selectedEmotions.contains(emotion),
                        onTap: () {
                          widget.onEmotionToggle(emotion);
                          setState(() {}); // Update UI in real-time
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Footer
          Container(
            padding: EdgeInsets.all(16),
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
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: WidgetsContainer(
                padding: EdgeInsets.all(12),
                borderRadius: BorderRadius.circular(10),
                backgroundColor: theme.primary[600],
                child: Center(
                  child: Text(
                    AppLocalizations.of(context).translate('done'),
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
