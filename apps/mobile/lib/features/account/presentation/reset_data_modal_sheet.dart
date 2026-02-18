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
import 'package:reboot_app_3/features/vault/data/streaks/streak_notifier.dart';
import 'package:reboot_app_3/features/vault/data/statistics/statistics_notifier.dart';
import 'package:reboot_app_3/features/vault/data/calendar/calendar_notifier.dart';
import 'package:reboot_app_3/features/vault/data/streaks/streak_duration_notifier.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/statistics/statistics_widget.dart';

class ResetDataModalSheet extends ConsumerStatefulWidget {
  const ResetDataModalSheet({Key? key}) : super(key: key);

  @override
  _ResetDataModalSheetState createState() => _ResetDataModalSheetState();
}

class _ResetDataModalSheetState extends ConsumerState<ResetDataModalSheet> {
  bool deleteFollowUps = false;
  bool deleteEmotions = false;
  bool userWantNowAsNewFirstDate = false;
  bool isLoading = false;
  final startingDateController = TextEditingController();
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    // Initialize with current userFirstDate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProfile = ref.read(userProfileNotifierProvider).value;
      if (userProfile != null) {
        setState(() {
          selectedDate = userProfile.userFirstDate;
          startingDateController.text = getDisplayDateTime(
            userProfile.userFirstDate,
            ref.read(localeNotifierProvider)?.languageCode ?? 'en',
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProfileNotifier = ref.read(userProfileNotifierProvider.notifier);
    final theme = AppTheme.of(context);
    final locale = ref.watch(localeNotifierProvider);

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context).translate('delete-my-data'),
                  style: TextStyles.h6,
                ),
                GestureDetector(
                  onTap: isLoading ? null : () => Navigator.of(context).pop(),
                  child: Icon(
                    LucideIcons.xCircle,
                    color: isLoading ? theme.grey[400] : null,
                  ),
                ),
              ],
            ),
            verticalSpace(Spacing.points24),
            Text(
              AppLocalizations.of(context).translate('reset-data-desc'),
              style: TextStyles.caption
                  .copyWith(color: theme.warn[800], height: 1.4),
            ),
            verticalSpace(Spacing.points24),
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
                  validator: (value) {
                    return null;
                  },
                  controller: startingDateController,
                  hint: AppLocalizations.of(context).translate('starting-date'),
                  prefixIcon: LucideIcons.calendar,
                  inputType: TextInputType.datetime,
                ),
              ),
            ),
            verticalSpace(Spacing.points8),
            WidgetsContainer(
              backgroundColor: theme.backgroundColor,
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              borderSide: BorderSide(color: theme.grey[600]!, width: 0.5),
              boxShadow: Shadows.mainShadows,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.bell),
                      horizontalSpace(Spacing.points16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)
                                .translate('reset-to-today'),
                            style: TextStyles.footnote.copyWith(
                              color: theme.grey[900],
                            ),
                          ),
                          verticalSpace(Spacing.points4),
                          if (userWantNowAsNewFirstDate)
                            Text(
                              getDisplayDateTime(
                                  DateTime.now(), locale!.languageCode),
                              style: TextStyles.footnote.copyWith(
                                color: theme.grey[400],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  Switch(
                    value: userWantNowAsNewFirstDate,
                    activeColor: theme.primary[600],
                    onChanged: isLoading
                        ? null
                        : (bool value) {
                            setState(() {
                              userWantNowAsNewFirstDate = value;
                              if (userWantNowAsNewFirstDate) {
                                final selectedStartingDateDisplay =
                                    DisplayDateTime(
                                        DateTime.now(), locale!.languageCode);
                                startingDateController.text =
                                    selectedStartingDateDisplay.displayDateTime;
                                selectedDate = selectedStartingDateDisplay.date;
                              }
                            });
                          },
                  ),
                ],
              ),
            ),
            verticalSpace(Spacing.points16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)
                            .translate('daily-follow-ups'),
                        style: TextStyles.body,
                      ),
                      Text(
                        AppLocalizations.of(context)
                            .translate('daily-follow-ups-delete-desc'),
                        style:
                            TextStyles.small.copyWith(color: theme.grey[600]),
                      ),
                    ],
                  ),
                ),
                horizontalSpace(Spacing.points32),
                Checkbox(
                  value: deleteFollowUps,
                  onChanged: isLoading
                      ? null
                      : (bool? value) {
                          setState(() {
                            deleteFollowUps = value ?? false;
                          });
                        },
                ),
              ],
            ),
            verticalSpace(Spacing.points16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).translate('emotions'),
                        style: TextStyles.body,
                      ),
                      Text(
                        AppLocalizations.of(context)
                            .translate('emotions-delete-desc'),
                        style:
                            TextStyles.small.copyWith(color: theme.grey[600]),
                      ),
                    ],
                  ),
                ),
                horizontalSpace(Spacing.points32),
                Checkbox(
                  value: deleteEmotions,
                  onChanged: isLoading
                      ? null
                      : (bool? value) {
                          setState(() {
                            deleteEmotions = value ?? false;
                          });
                        },
                ),
              ],
            ),
            verticalSpace(Spacing.points24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: isLoading
                        ? null
                        : () async {
                            setState(() {
                              isLoading = true;
                            });

                            try {
                              if (selectedDate != null) {
                                await userProfileNotifier
                                    .updateUserFirstDate(selectedDate!);
                              }
                              if (deleteFollowUps) {
                                await userProfileNotifier
                                    .deleteDailyFollowUps();
                              }
                              if (deleteEmotions) {
                                await userProfileNotifier.deleteEmotions();
                              }

                              // Refresh home screen providers after data deletion
                              ref.invalidate(streakNotifierProvider);
                              ref.invalidate(statisticsNotifierProvider);
                              ref.invalidate(calendarStreamProvider);
                              ref.invalidate(calendarNotifierProvider);
                              ref.invalidate(followUpsProvider);
                              ref.invalidate(detailedStreakProvider);

                              getSuccessSnackBar(
                                  context, 'data-updated-successfully');
                              Navigator.of(context).pop();
                            } catch (e) {
                              // Handle error if needed
                              setState(() {
                                isLoading = false;
                              });
                            }
                          },
                    child: WidgetsContainer(
                      backgroundColor:
                          isLoading ? theme.grey[100] : theme.backgroundColor,
                      boxShadow: isLoading ? [] : Shadows.mainShadows,
                      borderSide:
                          BorderSide(color: theme.grey[600]!, width: 0.5),
                      borderRadius: BorderRadius.circular(10.5),
                      child: Center(
                        child: isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: Spinner(
                                  strokeWidth: 2,
                                  valueColor: theme.primary[700],
                                ),
                              )
                            : Text(
                                AppLocalizations.of(context)
                                    .translate('confirm'),
                                style: TextStyles.h6.copyWith(
                                  color: theme.primary[700],
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                horizontalSpace(Spacing.points8),
                Expanded(
                  child: GestureDetector(
                    onTap: isLoading ? null : () => Navigator.of(context).pop(),
                    child: WidgetsContainer(
                      backgroundColor:
                          isLoading ? theme.grey[100] : theme.backgroundColor,
                      boxShadow: isLoading ? [] : Shadows.mainShadows,
                      borderSide:
                          BorderSide(color: theme.grey[600]!, width: 0.5),
                      borderRadius: BorderRadius.circular(10.5),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context).translate('cancel'),
                          style: TextStyles.h6.copyWith(
                            color:
                                isLoading ? theme.grey[400] : theme.grey[900],
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

  @override
  void dispose() {
    startingDateController.dispose();
    super.dispose();
  }
}
