import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/account/data/user_profile_notifier.dart';
import 'package:reboot_app_3/features/home/data/streak_notifier.dart';
import 'package:reboot_app_3/features/home/data/statistics_notifier.dart';
import 'package:reboot_app_3/features/home/data/calendar_notifier.dart';
import 'package:reboot_app_3/features/home/data/streak_duration_notifier.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/statistics_widget.dart';
import 'package:reboot_app_3/features/home/presentation/home/streak_display_notifier.dart';
import 'package:reboot_app_3/features/home/presentation/home/statistics_visibility_notifier.dart';

class SimplifiedResetModal extends ConsumerStatefulWidget {
  const SimplifiedResetModal({Key? key}) : super(key: key);

  @override
  _SimplifiedResetModalState createState() => _SimplifiedResetModalState();
}

class _SimplifiedResetModalState extends ConsumerState<SimplifiedResetModal> {
  bool isLoading = false;
  bool resetToToday = true;
  final startingDateController = TextEditingController();
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    // Default to today's date
    final today = DateTime.now();
    setState(() {
      selectedDate = today;
      startingDateController.text = getDisplayDate(
        today,
        ref.read(localeNotifierProvider)?.languageCode ?? 'en',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProfileNotifier = ref.read(userProfileNotifierProvider.notifier);
    final theme = AppTheme.of(context);
    final locale = ref.watch(localeNotifierProvider);
    final localization = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
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
                  localization.translate('reset-data'),
                  style: TextStyles.h6.copyWith(color: theme.grey[900]),
                ),
                GestureDetector(
                  onTap: isLoading ? null : () => Navigator.of(context).pop(),
                  child: Icon(
                    LucideIcons.x,
                    color: isLoading ? theme.grey[400] : theme.grey[600],
                    size: 20,
                  ),
                ),
              ],
            ),
            verticalSpace(Spacing.points16),

            // Current starting date info
            WidgetsContainer(
              backgroundColor: theme.grey[50],
              borderSide: BorderSide(color: theme.grey[200]!, width: 1),
              borderRadius: BorderRadius.circular(8),
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.info,
                    color: theme.grey[600],
                    size: 16,
                  ),
                  horizontalSpace(Spacing.points8),
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final streaksState = ref.watch(streakNotifierProvider);
                        final firstDate = streaksState.value?.userFirstDate;
                        return Text(
                          localization.translate("starting-date") +
                              ": " +
                              (firstDate != null
                                  ? getDisplayDateTime(
                                      firstDate, locale?.languageCode ?? 'en')
                                  : localization.translate("not-set")),
                          style: TextStyles.caption.copyWith(
                            color: theme.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            verticalSpace(Spacing.points12),

            // Warning message
            WidgetsContainer(
              backgroundColor: theme.warn[50],
              borderSide: BorderSide(color: theme.warn[200]!, width: 1),
              borderRadius: BorderRadius.circular(8),
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.alertTriangle,
                    color: theme.warn[600],
                    size: 16,
                  ),
                  horizontalSpace(Spacing.points8),
                  Expanded(
                    child: Text(
                      localization.translate('reset-confirmation'),
                      style: TextStyles.footnote.copyWith(
                        color: theme.warn[800],
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            verticalSpace(Spacing.points20),

            // Reset to today toggle
            WidgetsContainer(
              backgroundColor: theme.backgroundColor,
              borderSide: BorderSide(color: theme.grey[300]!, width: 1),
              borderRadius: BorderRadius.circular(8),
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.calendar,
                    color: theme.grey[600],
                    size: 16,
                  ),
                  horizontalSpace(Spacing.points12),
                  Expanded(
                    child: Text(
                      localization.translate('reset-today'),
                      style: TextStyles.body.copyWith(color: theme.grey[900]),
                    ),
                  ),
                  Switch(
                    value: resetToToday,
                    activeColor: theme.primary[600],
                    onChanged: isLoading
                        ? null
                        : (bool value) {
                            setState(() {
                              resetToToday = value;
                              if (resetToToday) {
                                final today = DateTime.now();
                                selectedDate = today;
                                startingDateController.text = getDisplayDate(
                                  today,
                                  locale?.languageCode ?? 'en',
                                );
                              }
                            });
                          },
                  ),
                ],
              ),
            ),

            // Custom date picker (only shown when resetToToday is false)
            if (!resetToToday) ...[
              verticalSpace(Spacing.points12),
              GestureDetector(
                onTap: isLoading
                    ? null
                    : () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                            startingDateController.text = getDisplayDate(
                              picked,
                              locale?.languageCode ?? 'en',
                            );
                          });
                        }
                      },
                child: AbsorbPointer(
                  child: CustomTextField(
                    validator: (value) => null,
                    controller: startingDateController,
                    hint: localization.translate('new-starting-date'),
                    prefixIcon: LucideIcons.calendar,
                    inputType: TextInputType.datetime,
                  ),
                ),
              ),
            ],

            verticalSpace(Spacing.points24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: isLoading ? null : () => Navigator.of(context).pop(),
                    child: WidgetsContainer(
                      backgroundColor: theme.backgroundColor,
                      borderSide:
                          BorderSide(color: theme.grey[300]!, width: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          localization.translate('cancel'),
                          style: TextStyles.footnote.copyWith(
                            color: theme.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                horizontalSpace(Spacing.points12),
                Expanded(
                  child: GestureDetector(
                    onTap: isLoading
                        ? null
                        : () => _showConfirmationDialog(
                            context, ref, userProfileNotifier),
                    child: WidgetsContainer(
                      borderSide: BorderSide.none,
                      backgroundColor:
                          isLoading ? theme.grey[100] : theme.warn[600],
                      borderRadius: BorderRadius.circular(8),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: isLoading
                            ? SizedBox(
                                height: 18,
                                width: 18,
                                child: Spinner(
                                  strokeWidth: 2,
                                  valueColor: theme.backgroundColor,
                                ),
                              )
                            : Text(
                                localization.translate('reset-data'),
                                style: TextStyles.footnote.copyWith(
                                  color: theme.backgroundColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog(
      BuildContext context, WidgetRef ref, userProfileNotifier) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: theme.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            localization.translate('confirm-reset'),
            style: TextStyles.h6.copyWith(
              color: theme.warn[800],
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            localization.translate('final-warning'),
            style: TextStyles.body.copyWith(
              color: theme.grey[700],
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                localization.translate('cancel'),
                style: TextStyles.body.copyWith(
                  color: theme.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: 8),
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  await _performReset(userProfileNotifier, ref);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.warn[600],
                  foregroundColor: theme.backgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(
                  localization.translate('yes-delete-all'),
                  style: TextStyles.footnote.copyWith(
                    color: theme.backgroundColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performReset(userProfileNotifier, WidgetRef ref) async {
    setState(() {
      isLoading = true;
    });

    try {
      // Delete all data including emotions and follow-ups
      await userProfileNotifier.deleteDailyFollowUps();
      await userProfileNotifier.deleteEmotions();

      // Update the starting date
      if (selectedDate != null) {
        await userProfileNotifier.updateUserFirstDate(selectedDate!);
      }

      // Refresh all relevant providers after data deletion
      ref.invalidate(streakNotifierProvider);
      ref.invalidate(statisticsNotifierProvider);
      ref.invalidate(calendarStreamProvider);
      ref.invalidate(calendarNotifierProvider);
      ref.invalidate(followUpsProvider);
      ref.invalidate(detailedStreakProvider);
      ref.invalidate(userProfileNotifierProvider);

      // Also invalidate any streak duration related providers
      ref.invalidate(streakDisplayProvider);
      ref.invalidate(statisticsVisibilityProvider);

      getSuccessSnackBar(context, 'data-updated-successfully');
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    startingDateController.dispose();
    super.dispose();
  }
}
