import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/features/account/application/startup_security_service.dart';
import 'package:reboot_app_3/features/account/providers/clean_ban_warning_providers.dart';
import 'package:reboot_app_3/features/account/data/models/ban.dart';
import 'package:reboot_app_3/core/routing/app_startup.dart';

/// Widget to show when device or user is banned
class AppBannedWidget extends ConsumerWidget {
  final SecurityStartupResult securityResult;

  const AppBannedWidget({
    Key? key,
    required this.securityResult,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeNotifierProvider);

    // Create a proper MaterialApp with localization delegates
    return MaterialApp(
      locale: locale ?? const Locale('ar'),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      home: AppTheme(
        customThemeData: getLightCustomTheme(0), // Use default light theme
        child: _BannedScreenContent(securityResult: securityResult),
      ),
    );
  }
}

/// Internal widget for the banned screen content
class _BannedScreenContent extends ConsumerWidget {
  const _BannedScreenContent({required this.securityResult});
  final SecurityStartupResult securityResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _BannedScreenStateful(securityResult: securityResult);
  }
}

/// Stateful widget to handle async operations safely
class _BannedScreenStateful extends ConsumerStatefulWidget {
  const _BannedScreenStateful({required this.securityResult});
  final SecurityStartupResult securityResult;

  @override
  ConsumerState<_BannedScreenStateful> createState() =>
      _BannedScreenStatefulState();
}

class _BannedScreenStatefulState extends ConsumerState<_BannedScreenStateful> {
  bool _isLoggingOut = false;
  bool _isRefreshing = false;

  /// Translate security service messages to localized text
  String _translateSecurityMessage(BuildContext context, String message) {
    final l10n = AppLocalizations.of(context);

    // Map service messages to localization keys
    switch (message) {
      case 'Your account has been restricted from accessing the application.':
        return l10n.translate('account-restricted-message');
      case 'This device has been permanently restricted from accessing the application. Contact support if you believe this is an error.':
        return l10n.translate('device-permanently-restricted');
      case 'This device has been restricted from accessing the application for your account. Contact support if you believe this is an error.':
        return l10n.translate('device-restricted-for-account');
      case 'This device has been restricted from accessing the application. Device access has been revoked due to policy violations. Please contact support for more information.':
        return l10n.translate('device-access-revoked');
      case 'Security initialization completed successfully':
        return l10n.translate('security-initialization-success');
      case 'Security check failed, proceeding with limited functionality':
        return l10n.translate('security-check-failed');
      default:
        // For unknown messages, return the original message
        return message;
    }
  }

  /// Get localized text for ban type
  String _getBanTypeText(BanType banType, BuildContext context) {
    switch (banType) {
      case BanType.user_ban:
        return AppLocalizations.of(context).translate('user-ban');
      case BanType.device_ban:
        return AppLocalizations.of(context).translate('device-ban');
      case BanType.feature_ban:
        return AppLocalizations.of(context).translate('feature-ban');
    }
  }

  /// Format ban duration for display with localization
  String _formatBanDuration(Ban ban, BuildContext context) {
    if (ban.severity == BanSeverity.permanent) {
      return AppLocalizations.of(context).translate('permanent');
    }

    if (ban.expiresAt == null) {
      return AppLocalizations.of(context).translate('unknown');
    }

    final now = DateTime.now();
    final difference = ban.expiresAt!.difference(now);

    if (difference.isNegative) {
      return AppLocalizations.of(context).translate('expired');
    }

    final l10n = AppLocalizations.of(context);

    if (difference.inDays > 0) {
      final dayLabel = difference.inDays == 1
          ? l10n.translate('day')
          : l10n.translate('days');
      return '${difference.inDays} $dayLabel';
    } else if (difference.inHours > 0) {
      final hourLabel = difference.inHours == 1
          ? l10n.translate('hour')
          : l10n.translate('hours');
      return '${difference.inHours} $hourLabel';
    } else {
      final minuteLabel = difference.inMinutes == 1
          ? l10n.translate('minute')
          : l10n.translate('minutes');
      return '${difference.inMinutes} $minuteLabel';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access theme through the context now that we have AppTheme wrapper
    final theme = AppTheme.of(context);
    final locale = ref.watch(localeNotifierProvider);

    // DEVICE BANS have HIGHEST PRIORITY - they block ALL access
    final isDeviceBan =
        widget.securityResult.status == SecurityStartupStatus.deviceBanned;
    final isUserBan =
        widget.securityResult.status == SecurityStartupStatus.userBanned;

    return Scaffold(
      backgroundColor: theme.error[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon - Different for device vs user bans
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDeviceBan ? Colors.red[100] : theme.error[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDeviceBan ? Icons.phonelink_off : Icons.person_off,
                  size: 64,
                  color: isDeviceBan ? Colors.red[700] : theme.error[600],
                ),
              ),

              const SizedBox(height: 24),

              // Title - Different for device vs user bans
              Text(
                isDeviceBan
                    ? AppLocalizations.of(context)
                        .translate('device-restricted')
                    : AppLocalizations.of(context)
                        .translate('account-restricted'),
                style: TextStyles.h1.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDeviceBan ? Colors.red[700] : theme.error[800],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Message
              Text(
                _translateSecurityMessage(
                    context, widget.securityResult.message),
                style: TextStyles.body.copyWith(
                  color: theme.grey[700],
                ),
                textAlign: TextAlign.center,
              ),

              verticalSpace(Spacing.points24),

              // Show ban details for both device and user bans
              _buildBanDetails(context, ref, theme,
                  locale ?? const Locale('en'), isDeviceBan),

              const SizedBox(height: 24),

              // Refresh button for both user and device bans
              _buildRefreshButton(context, ref, theme),

              // Logout button ONLY for user bans (NOT for device bans)
              if (isUserBan) ...[
                const SizedBox(height: 16),
                _buildLogoutButton(context, ref, theme),
              ],

              // For device bans, show a message that logout won't help
              if (isDeviceBan) ...[
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)
                      .translate('device-ban-no-logout-message'),
                  style: TextStyles.small.copyWith(
                    color: Colors.red[600],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBanDetails(BuildContext context, WidgetRef ref,
      CustomThemeData theme, Locale locale, bool isDeviceBan) {
    if (isDeviceBan) {
      // For device bans, show device ban details
      return _buildDeviceBanDetails(context, ref, theme, locale);
    } else {
      // For user bans, show user ban details
      return _buildUserBanDetails(context, ref, theme, locale);
    }
  }

  Widget _buildDeviceBanDetails(BuildContext context, WidgetRef ref,
      CustomThemeData theme, Locale locale) {
    // For device bans, we need to fetch device bans from the ban service
    // Since we don't have a specific provider for device bans, we'll use the current user bans
    // and filter for device bans that apply to this device
    final userBansAsync = ref.watch(currentUserBansProvider);

    return userBansAsync.when(
      loading: () => WidgetsContainer(
        padding: const EdgeInsets.all(16),
        child: const CircularProgressIndicator(),
      ),
      error: (error, stack) => WidgetsContainer(
        padding: const EdgeInsets.all(16),
        backgroundColor: theme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.error[300]!),
        child: Column(
          children: [
            Icon(
              LucideIcons.alertTriangle,
              color: theme.error[600],
              size: 24,
            ),
            verticalSpace(Spacing.points8),
            Text(
              AppLocalizations.of(context)
                  .translate('unable-to-load-ban-details'),
              style: TextStyles.body.copyWith(
                color: theme.error[700],
              ),
            ),
            verticalSpace(Spacing.points4),
            Text(
              _translateSecurityMessage(context, widget.securityResult.message),
              style: TextStyles.small.copyWith(
                color: theme.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      data: (bans) {
        // Filter for device bans that apply to this device
        final currentDeviceId = widget.securityResult.deviceId;
        final deviceBans = bans
            .where((ban) =>
                ban.type == BanType.device_ban &&
                ban.isActive &&
                (ban.deviceIds?.contains(currentDeviceId) == true ||
                    ban.restrictedDevices?.contains(currentDeviceId) == true))
            .toList();

        if (deviceBans.isEmpty) {
          // If no specific device ban found, show a generic device restriction message
          return WidgetsContainer(
            padding: const EdgeInsets.all(16),
            backgroundColor: theme.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.error[300]!),
            child: Column(
              children: [
                Icon(
                  LucideIcons.smartphone,
                  color: theme.error[600],
                  size: 24,
                ),
                verticalSpace(Spacing.points8),
                Text(
                  AppLocalizations.of(context).translate('device-restricted'),
                  style: TextStyles.body.copyWith(
                    color: theme.error[700],
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                verticalSpace(Spacing.points8),
                Text(
                  _translateSecurityMessage(
                      context, widget.securityResult.message),
                  style: TextStyles.small.copyWith(
                    color: theme.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (currentDeviceId != null) ...[
                  verticalSpace(Spacing.points8),
                  Text(
                    '${AppLocalizations.of(context).translate('device-id')}: $currentDeviceId',
                    style: TextStyles.small.copyWith(
                      color: theme.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          );
        }

        // Show all device bans that apply to this device
        return Column(
          children: deviceBans
              .map((ban) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildBanDetailsCard(context, ban, theme, locale),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildUserBanDetails(BuildContext context, WidgetRef ref,
      CustomThemeData theme, Locale locale) {
    final userBansAsync = ref.watch(currentUserBansProvider);

    return userBansAsync.when(
      loading: () => WidgetsContainer(
        padding: const EdgeInsets.all(16),
        child: const CircularProgressIndicator(),
      ),
      error: (error, stack) => WidgetsContainer(
        padding: const EdgeInsets.all(16),
        backgroundColor: theme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.error[300]!),
        child: Column(
          children: [
            Icon(
              LucideIcons.alertTriangle,
              color: theme.error[600],
              size: 24,
            ),
            verticalSpace(Spacing.points8),
            Text(
              AppLocalizations.of(context)
                  .translate('unable-to-load-ban-details'),
              style: TextStyles.body.copyWith(
                color: theme.error[700],
              ),
            ),
            verticalSpace(Spacing.points4),
            Text(
              widget.securityResult.message,
              style: TextStyles.small.copyWith(
                color: theme.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      data: (bans) {
        // Show all active bans that are blocking the user
        final activeBans = bans.where((ban) => ban.isActive).toList();

        if (activeBans.isEmpty) {
          return WidgetsContainer(
            padding: const EdgeInsets.all(16),
            backgroundColor: theme.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.error[300]!),
            child: Text(
              widget.securityResult.message,
              style: TextStyles.body.copyWith(
                color: theme.error[700],
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        // Show all active bans
        return Column(
          children: activeBans
              .map((ban) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildBanDetailsCard(context, ban, theme, locale),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildBanDetailsCard(
      BuildContext context, Ban ban, CustomThemeData theme, Locale locale) {
    return WidgetsContainer(
      padding: const EdgeInsets.all(16),
      backgroundColor: theme.backgroundColor,
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.error[300]!, width: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ban header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.error[600],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.shieldOff,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              horizontalSpace(Spacing.points12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).translate('ban-details'),
                      style: TextStyles.body.copyWith(
                        color: theme.grey[900],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    verticalSpace(Spacing.points4),
                    Row(
                      children: [
                        // Ban scope badge
                        WidgetsContainer(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          backgroundColor: ban.scope == BanScope.app_wide
                              ? theme.error[600]
                              : theme.warn[600],
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide.none,
                          child: Text(
                            ban.scope == BanScope.app_wide
                                ? AppLocalizations.of(context)
                                    .translate('app-wide')
                                : AppLocalizations.of(context)
                                    .translate('feature-specific'),
                            style: TextStyles.small.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        horizontalSpace(Spacing.points8),
                        // Ban type badge
                        WidgetsContainer(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          backgroundColor: theme.grey[600],
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide.none,
                          child: Text(
                            _getBanTypeText(ban.type, context),
                            style: TextStyles.small.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          verticalSpace(Spacing.points16),

          // Reason
          _buildDetailRow(
            context,
            AppLocalizations.of(context).translate('reason'),
            ban.reason,
            LucideIcons.messageCircle,
            theme,
          ),

          if (ban.description != null) ...[
            verticalSpace(Spacing.points12),
            _buildDetailRow(
              context,
              AppLocalizations.of(context).translate('description'),
              ban.description!,
              LucideIcons.fileText,
              theme,
            ),
          ],

          verticalSpace(Spacing.points12),

          // Duration
          _buildDetailRow(
            context,
            AppLocalizations.of(context).translate('duration'),
            _formatBanDuration(ban, context),
            LucideIcons.clock,
            theme,
          ),

          verticalSpace(Spacing.points12),

          // Issue date
          _buildDetailRow(
            context,
            AppLocalizations.of(context).translate('issued-date'),
            getDisplayDate(ban.issuedAt, locale.languageCode),
            LucideIcons.calendar,
            theme,
          ),

          if (ban.expiresAt != null) ...[
            verticalSpace(Spacing.points12),
            _buildDetailRow(
              context,
              AppLocalizations.of(context).translate('expires-on'),
              getDisplayDate(ban.expiresAt!, locale.languageCode),
              LucideIcons.calendarX,
              theme,
            ),
          ],

          verticalSpace(Spacing.points12),

          // Ban ID
          _buildDetailRow(
            context,
            AppLocalizations.of(context).translate('ban-id'),
            ban.id,
            LucideIcons.hash,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value,
      IconData icon, CustomThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: theme.grey[500],
          size: 16,
        ),
        horizontalSpace(Spacing.points8),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyles.small.copyWith(
              color: theme.grey[600],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyles.small.copyWith(
              color: theme.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _logout(
      BuildContext context, WidgetRef ref, CustomThemeData theme) async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoggingOut = true;
      });

      await FirebaseAuth.instance.signOut();
      // Force the app to re-evaluate startup state, which will redirect to onboarding
      // since the user is no longer authenticated
      ref.invalidate(appStartupProvider);
    } catch (e) {
      // Handle logout error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('logout-error'),
              style: TextStyles.body.copyWith(color: Colors.white),
            ),
            backgroundColor: theme.error[600],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  Future<void> _refreshBanStatus(
      BuildContext context, WidgetRef ref, CustomThemeData theme) async {
    if (!mounted) return;

    try {
      setState(() {
        _isRefreshing = true;
      });

      // Invalidate the startup provider to re-check security status
      ref.invalidate(appStartupProvider);

      // Also invalidate the current user bans to get fresh data
      ref.invalidate(currentUserBansProvider);

      // Wait a moment for the providers to refresh
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Check the new startup state
      final startupState = ref.read(appStartupProvider);

      if (!mounted) return;

      startupState.when(
        data: (startup) {
          // If startup is successful, it means the user is no longer banned
          if (startup != null && mounted) {
            // Navigate to home or let the app handle the routing
            // The app startup will automatically handle the navigation
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context).translate('ban-status-updated'),
                  style: TextStyles.body.copyWith(color: Colors.white),
                ),
                backgroundColor: Colors.green[600],
              ),
            );
          }
        },
        loading: () {
          // Still loading, show a message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context).translate('checking-ban-status'),
                  style: TextStyles.body.copyWith(color: Colors.white),
                ),
                backgroundColor: theme.primary[600],
              ),
            );
          }
        },
        error: (error, stack) {
          // Still banned or error occurred
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context).translate('ban-still-active'),
                  style: TextStyles.body.copyWith(color: Colors.white),
                ),
                backgroundColor: theme.error[600],
              ),
            );
          }
        },
      );
    } catch (e) {
      // Handle refresh error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('refresh-error'),
              style: TextStyles.body.copyWith(color: Colors.white),
            ),
            backgroundColor: theme.error[600],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Widget _buildRefreshButton(
      BuildContext context, WidgetRef ref, CustomThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed:
            _isRefreshing ? null : () => _refreshBanStatus(context, ref, theme),
        icon: _isRefreshing
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(
                LucideIcons.refreshCw,
                color: Colors.white,
              ),
        label: Text(
          AppLocalizations.of(context).translate('check-ban-status'),
          style: TextStyles.body.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primary[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
              cornerRadius: 8,
              cornerSmoothing: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(
      BuildContext context, WidgetRef ref, CustomThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoggingOut ? null : () => _logout(context, ref, theme),
        icon: Icon(
          LucideIcons.logOut,
          color: Colors.white,
        ),
        label: Text(
          AppLocalizations.of(context).translate('logout'),
          style: TextStyles.body.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.error[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
              cornerRadius: 8,
              cornerSmoothing: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
