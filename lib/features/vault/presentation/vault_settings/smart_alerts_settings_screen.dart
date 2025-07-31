import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:app_settings/app_settings.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/platform_time_picker.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/data/models/smart_alert_settings.dart';
import 'package:reboot_app_3/features/vault/data/smart_alerts/smart_alerts_notifier.dart';
import 'package:reboot_app_3/features/plus/data/notifiers/subscription_notifier.dart';

class SmartAlertsSettingsScreen extends ConsumerStatefulWidget {
  const SmartAlertsSettingsScreen({super.key});

  @override
  ConsumerState<SmartAlertsSettingsScreen> createState() =>
      _SmartAlertsSettingsScreenState();
}

class _SmartAlertsSettingsScreenState
    extends ConsumerState<SmartAlertsSettingsScreen> {
  bool _isLoading = false;

  String? _translateReason(String? reason) {
    if (reason == null) return null;

    if (reason.startsWith('need-followups-for-risk-hour:')) {
      final count = reason.split(':')[1];
      return AppLocalizations.of(context)
          .translate('need-followups-for-risk-hour')
          .replaceAll('{count}', count);
    } else if (reason.startsWith('need-weeks-for-vulnerability:')) {
      final weeks = reason.split(':')[1];
      return AppLocalizations.of(context)
          .translate('need-weeks-for-vulnerability')
          .replaceAll('{weeks}', weeks);
    }

    return reason;
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final settingsAsync = ref.watch(smartAlertSettingsProvider);
    final eligibilityAsync = ref.watch(smartAlertEligibilityProvider);
    final notificationsEnabledAsync = ref.watch(notificationsEnabledProvider);
    final hasSubscription = ref.watch(hasActiveSubscriptionProvider);

    return Scaffold(
      appBar: appBar(
        context,
        ref,
        "smart-alerts-settings",
        false,
        true,
      ),
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)
                    .translate('smart-alerts-description'),
                style: TextStyles.body.copyWith(
                  color: theme.grey[700],
                  height: 1.5,
                ),
              ),
              verticalSpace(Spacing.points16),

              // Beta Notice
              WidgetsContainer(
                padding: EdgeInsets.all(12),
                backgroundColor: theme.warn[50],
                borderSide: BorderSide(color: theme.warn[200]!),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.warn[500],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        AppLocalizations.of(context).translate('beta'),
                        style: TextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    horizontalSpace(Spacing.points8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)
                            .translate('smart-alerts-beta-notice'),
                        style: TextStyles.small.copyWith(
                          color: theme.warn[700],
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              verticalSpace(Spacing.points20),

              // Content
              Expanded(
                child: !hasSubscription
                    ? _buildSubscriptionRequired(theme)
                    : settingsAsync.when(
                        data: (settings) => eligibilityAsync.when(
                          data: (eligibility) => notificationsEnabledAsync.when(
                            data: (notificationsEnabled) =>
                                _buildSettingsContent(
                              theme,
                              settings,
                              eligibility,
                              notificationsEnabled,
                            ),
                            loading: () => Center(child: Spinner()),
                            error: (_, __) => _buildErrorState(theme),
                          ),
                          loading: () => Center(child: Spinner()),
                          error: (_, __) => _buildErrorState(theme),
                        ),
                        loading: () => Center(child: Spinner()),
                        error: (_, __) => _buildErrorState(theme),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionRequired(dynamic theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          WidgetsContainer(
            padding: EdgeInsets.all(24),
            backgroundColor: theme.primary[50],
            borderSide: BorderSide(color: theme.primary[200]!),
            child: Column(
              children: [
                Icon(
                  LucideIcons.crown,
                  color: theme.primary[600],
                  size: 48,
                ),
                verticalSpace(Spacing.points16),
                Text(
                  AppLocalizations.of(context)
                      .translate('smart-alerts-plus-required-title'),
                  style: TextStyles.h5.copyWith(
                    color: theme.primary[700],
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                verticalSpace(Spacing.points12),
                Text(
                  AppLocalizations.of(context)
                      .translate('smart-alerts-plus-required-description'),
                  style: TextStyles.body.copyWith(
                    color: theme.primary[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          verticalSpace(Spacing.points24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Navigate to Plus subscription screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary[600],
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                AppLocalizations.of(context).translate('upgrade-to-plus'),
                style: TextStyles.body.copyWith(
                  color: theme.grey[50],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent(
    dynamic theme,
    SmartAlertSettings? settings,
    SmartAlertEligibility eligibility,
    bool notificationsEnabled,
  ) {
    if (settings == null) {
      return _buildErrorState(theme);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notification permission banner
          if (!notificationsEnabled) ...[
            _buildPermissionBanner(theme),
            verticalSpace(Spacing.points16),
          ],

          // High-Risk Hour Alert
          _buildAlertCard(
            theme,
            SmartAlertType.highRiskHour,
            settings,
            eligibility,
            notificationsEnabled,
          ),
          verticalSpace(Spacing.points16),

          // Streak Vulnerability Alert
          _buildAlertCard(
            theme,
            SmartAlertType.streakVulnerability,
            settings,
            eligibility,
            notificationsEnabled,
          ),
          verticalSpace(Spacing.points24),

          // Action buttons
          if (eligibility.isEligibleForRiskHour ||
              eligibility.isEligibleForVulnerability) ...[
            _buildActionButtons(
                theme, settings, eligibility, notificationsEnabled),
          ],

          verticalSpace(Spacing.points16),
        ],
      ),
    );
  }

  Widget _buildPermissionBanner(dynamic theme) {
    return WidgetsContainer(
      padding: EdgeInsets.all(16),
      backgroundColor: theme.warn[50],
      borderSide: BorderSide(color: theme.warn[200]!),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.bellOff,
                color: theme.warn[600],
                size: 20,
              ),
              horizontalSpace(Spacing.points12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)
                      .translate('notifications-disabled-banner'),
                  style: TextStyles.footnote.copyWith(
                    color: theme.warn[700],
                  ),
                ),
              ),
            ],
          ),
          verticalSpace(Spacing.points12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () async {
                setState(() => _isLoading = true);
                await _openNotificationSettings();
                setState(() => _isLoading = false);
              },
              style: TextButton.styleFrom(
                backgroundColor: theme.warn[100],
                padding: EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                AppLocalizations.of(context).translate('enable-notifications'),
                style: TextStyles.footnote.copyWith(
                  color: theme.warn[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(
    dynamic theme,
    SmartAlertType type,
    SmartAlertSettings settings,
    SmartAlertEligibility eligibility,
    bool notificationsEnabled,
  ) {
    final isEnabled = type == SmartAlertType.highRiskHour
        ? settings.isHighRiskHourEnabled
        : settings.isStreakVulnerabilityEnabled;

    final isEligible = type == SmartAlertType.highRiskHour
        ? eligibility.isEligibleForRiskHour
        : eligibility.isEligibleForVulnerability;

    final reason = type == SmartAlertType.highRiskHour
        ? eligibility.riskHourReason
        : eligibility.vulnerabilityReason;

    final hasData = type == SmartAlertType.highRiskHour
        ? settings.hasEnoughDataForRiskHour
        : settings.hasEnoughDataForVulnerability;

    return WidgetsContainer(
      padding: EdgeInsets.all(16),
      backgroundColor: isEligible ? theme.backgroundColor : theme.grey[50],
      borderSide: BorderSide(
        color: isEligible ? theme.grey[200]! : theme.grey[300]!,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                type == SmartAlertType.highRiskHour
                    ? LucideIcons.clock
                    : LucideIcons.calendar,
                color: isEligible ? theme.primary[600] : theme.grey[400],
                size: 20,
              ),
              horizontalSpace(Spacing.points12),
              Expanded(
                child: Text(
                  type == SmartAlertType.highRiskHour
                      ? AppLocalizations.of(context)
                          .translate('high-risk-hour-alert')
                      : AppLocalizations.of(context)
                          .translate('streak-vulnerability-alert'),
                  style: TextStyles.body.copyWith(
                    color: isEligible ? theme.grey[900] : theme.grey[500],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isEligible && notificationsEnabled)
                Switch(
                  value: isEnabled,
                  onChanged:
                      _isLoading ? null : (value) => _toggleAlert(type, value),
                  activeColor: theme.primary[600],
                ),
            ],
          ),
          verticalSpace(Spacing.points8),
          Text(
            type == SmartAlertType.highRiskHour
                ? AppLocalizations.of(context)
                    .translate('high-risk-hour-description')
                : AppLocalizations.of(context)
                    .translate('vulnerability-alert-description'),
            style: TextStyles.small.copyWith(
              color: isEligible ? theme.grey[600] : theme.grey[500],
              height: 1.4,
            ),
          ),

          // Time picker for vulnerability alerts
          if (type == SmartAlertType.streakVulnerability &&
              isEligible &&
              isEnabled) ...[
            verticalSpace(Spacing.points12),
            PlatformTimePicker(
              label: AppLocalizations.of(context).translate('alert-time'),
              value:
                  TimeOfDay(hour: settings.vulnerabilityAlertHour, minute: 0),
              onChanged: _isLoading
                  ? null
                  : (newTime) => _updateVulnerabilityAlertTime(newTime),
              backgroundColor: theme.grey[50],
            ),
          ],

          // Status indicator
          if (!isEligible || !hasData) ...[
            verticalSpace(Spacing.points12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.info,
                    color: theme.grey[600],
                    size: 14,
                  ),
                  horizontalSpace(Spacing.points4),
                  Flexible(
                    child: Text(
                      _translateReason(reason) ??
                          AppLocalizations.of(context)
                              .translate('not-enough-data'),
                      style: TextStyles.caption.copyWith(
                        color: theme.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Next alert time
          if (isEligible && hasData && isEnabled) ...[
            verticalSpace(Spacing.points12),
            FutureBuilder<Map<SmartAlertType, DateTime?>>(
              future: ref.read(nextAlertTimesProvider.future),
              builder: (context, snapshot) {
                final nextTime = snapshot.data?[type];
                if (nextTime != null) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.success[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.bell,
                          color: theme.success[600],
                          size: 14,
                        ),
                        horizontalSpace(Spacing.points4),
                        Text(
                          '${AppLocalizations.of(context).translate('next-alert')}: ${_formatDateTime(nextTime)}',
                          style: TextStyles.caption.copyWith(
                            color: theme.success[700],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Container();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    dynamic theme,
    SmartAlertSettings settings,
    SmartAlertEligibility eligibility,
    bool notificationsEnabled,
  ) {
    return Column(
      children: [
        // Calculate patterns button
        if (!settings.hasEnoughDataForRiskHour ||
            !settings.hasEnoughDataForVulnerability)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _calculatePatterns,
              icon: _isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(LucideIcons.calculator, size: 18),
              label: Text(
                  AppLocalizations.of(context).translate('calculate-patterns')),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary[600],
                foregroundColor: theme.grey[50],
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

        verticalSpace(Spacing.points12),

        // Test notification buttons
        Row(
          children: [
            if (eligibility.isEligibleForRiskHour)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading || !notificationsEnabled
                      ? null
                      : () =>
                          _testCloudNotification(SmartAlertType.highRiskHour),
                  icon: Icon(LucideIcons.clock, size: 16),
                  label: Text(
                    AppLocalizations.of(context).translate('test-risk-alert'),
                    style: TextStyles.small,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            if (eligibility.isEligibleForRiskHour &&
                eligibility.isEligibleForVulnerability)
              horizontalSpace(Spacing.points8),
            if (eligibility.isEligibleForVulnerability)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading || !notificationsEnabled
                      ? null
                      : () => _testCloudNotification(
                          SmartAlertType.streakVulnerability),
                  icon: Icon(LucideIcons.calendar, size: 16),
                  label: Text(
                    AppLocalizations.of(context)
                        .translate('test-vulnerability-alert'),
                    style: TextStyles.small,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorState(dynamic theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.alertTriangle,
            color: theme.error[500],
            size: 32,
          ),
          verticalSpace(Spacing.points12),
          Text(
            AppLocalizations.of(context).translate('error-loading-settings'),
            style: TextStyles.body.copyWith(
              color: theme.error[600],
            ),
            textAlign: TextAlign.center,
          ),
          verticalSpace(Spacing.points16),
          TextButton(
            onPressed: () {
              ref.invalidate(smartAlertSettingsProvider);
              ref.invalidate(smartAlertEligibilityProvider);
            },
            child: Text(AppLocalizations.of(context).translate('retry')),
          ),
        ],
      ),
    );
  }

  Future<void> _openNotificationSettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
      // Refresh notification status after returning from settings
      ref.invalidate(notificationsEnabledProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)
                .translate('error-opening-settings')),
            backgroundColor: AppTheme.of(context).error[500],
          ),
        );
      }
    }
  }

  Future<void> _toggleAlert(SmartAlertType type, bool enabled) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      final notifier = ref.read(smartAlertsNotifierProvider.notifier);
      if (type == SmartAlertType.highRiskHour) {
        await notifier.toggleRiskHourAlert(enabled);
      } else {
        await notifier.toggleVulnerabilityAlert(enabled);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)
                .translate('error-updating-settings')),
            backgroundColor: AppTheme.of(context).error[500],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _calculatePatterns() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      await ref
          .read(smartAlertsNotifierProvider.notifier)
          .calculateRiskPatterns();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context).translate('patterns-calculated')),
            backgroundColor: AppTheme.of(context).success[500],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)
                .translate('error-calculating-patterns')),
            backgroundColor: AppTheme.of(context).error[500],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Test notification via Cloud Functions (NEW FCM APPROACH)
  Future<void> _testCloudNotification(SmartAlertType type) async {
    if (_isLoading) return;

    HapticFeedback.lightImpact();

    try {
      await ref
          .read(smartAlertsNotifierProvider.notifier)
          .sendTestNotificationViaCloud(type);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✅ Cloud Functions test notification sent!'),
                SizedBox(height: 4),
                Text(
                  '☁️ Notification sent via Firebase Cloud Functions + FCM',
                  style: TextStyle(fontSize: 12),
                ),
                Text(
                  '📱 Check your notification panel',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: AppTheme.of(context).success[500],
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('❌ Cloud Functions test failed'),
                SizedBox(height: 4),
                Text(
                  'Error: ${e.toString()}',
                  style: TextStyle(fontSize: 11),
                ),
              ],
            ),
            backgroundColor: AppTheme.of(context).error[500],
            duration: Duration(seconds: 6),
          ),
        );
      }
    }
  }

  Future<void> _updateVulnerabilityAlertTime(TimeOfDay? newTime) async {
    if (_isLoading || newTime == null) return;

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      await ref
          .read(smartAlertsNotifierProvider.notifier)
          .updateVulnerabilityAlertHour(newTime.hour);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context).translate('alert-time-updated')),
            backgroundColor: AppTheme.of(context).success[500],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)
                .translate('error-updating-alert-time')),
            backgroundColor: AppTheme.of(context).error[500],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dayText;
    if (targetDay == today) {
      dayText = AppLocalizations.of(context).translate('today');
    } else if (targetDay == today.add(Duration(days: 1))) {
      dayText = AppLocalizations.of(context).translate('tomorrow');
    } else {
      // Format weekday
      final weekdayKeys = [
        'weekday-mon',
        'weekday-tue',
        'weekday-wed',
        'weekday-thu',
        'weekday-fri',
        'weekday-sat',
        'weekday-sun'
      ];
      dayText = AppLocalizations.of(context)
          .translate(weekdayKeys[dateTime.weekday - 1]);
    }

    // Format time
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final amText = AppLocalizations.of(context).translate('am');
    final pmText = AppLocalizations.of(context).translate('pm');
    final timeText = hour == 0
        ? '12:${minute.toString().padLeft(2, '0')} $amText'
        : hour == 12
            ? '12:${minute.toString().padLeft(2, '0')} $pmText'
            : hour < 12
                ? '$hour:${minute.toString().padLeft(2, '0')} $amText'
                : '${hour - 12}:${minute.toString().padLeft(2, '0')} $pmText';

    return '$dayText $timeText';
  }
}
