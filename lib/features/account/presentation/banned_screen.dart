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
import 'package:reboot_app_3/features/account/utils/ban_display_formatter.dart';
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
  _BannedScreenContent({required this.securityResult});
  final SecurityStartupResult securityResult;

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Access theme through the context now that we have AppTheme wrapper
    final theme = AppTheme.of(context);
    final locale = ref.watch(localeNotifierProvider);

    // DEVICE BANS have HIGHEST PRIORITY - they block ALL access
    final isDeviceBan =
        securityResult.status == SecurityStartupStatus.deviceBanned;
    final isUserBan = securityResult.status == SecurityStartupStatus.userBanned;

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
                _translateSecurityMessage(context, securityResult.message),
                style: TextStyles.body.copyWith(
                  color: theme.grey[700],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // For user bans, show actual ban details
              if (isUserBan) ...[
                _buildUserBanDetails(
                    context, ref, theme, locale ?? const Locale('en')),
              ],

              const SizedBox(height: 32),

              // Contact support information
              WidgetsContainer(
                backgroundColor: theme.backgroundColor,
                borderSide: BorderSide(color: theme.error[300]!),
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info,
                          color: theme.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isDeviceBan
                                ? AppLocalizations.of(context)
                                    .translate('device-ban-appeal-message')
                                : AppLocalizations.of(context)
                                    .translate('appeal-message'),
                            style: TextStyles.body.copyWith(
                              color: theme.grey[800],
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Contact details or reference ID
                    if (securityResult.deviceId != null ||
                        securityResult.userId != null) ...[
                      Text(
                        AppLocalizations.of(context).translate('reference-id') +
                            ': ${securityResult.deviceId ?? securityResult.userId}',
                        style: TextStyles.small.copyWith(
                          color: theme.grey[600],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Logout button ONLY for user bans (NOT for device bans)
              if (isUserBan) ...[
                const SizedBox(height: 24),
                _buildLogoutButton(context, ref, theme),
              ],

              // For device bans, show a message that logout won't help
              if (isDeviceBan) ...[
                const SizedBox(height: 24),
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
              securityResult.message,
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
        // Find the app-wide ban (the one blocking the user)
        Ban? appWideBan;
        try {
          appWideBan = bans.firstWhere(
            (ban) => ban.scope == BanScope.app_wide && ban.isActive,
          );
        } catch (e) {
          // No app-wide ban found, use the first ban if any
          appWideBan = bans.isNotEmpty ? bans.first : null;
        }

        if (appWideBan == null) {
          return WidgetsContainer(
            padding: const EdgeInsets.all(16),
            backgroundColor: theme.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.error[300]!),
            child: Text(
              securityResult.message,
              style: TextStyles.body.copyWith(
                color: theme.error[700],
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        return _buildBanDetailsCard(context, appWideBan, theme, locale);
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
                    WidgetsContainer(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      backgroundColor: theme.error[600],
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                      child: Text(
                        AppLocalizations.of(context).translate('app-wide'),
                        style: TextStyles.small.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
            BanDisplayFormatter.formatBanDuration(ban),
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

  bool _isLoggingOut = false;

  Future<void> _logout(
      BuildContext context, WidgetRef ref, CustomThemeData theme) async {
    try {
      _isLoggingOut = true;
      await FirebaseAuth.instance.signOut();
      // Force the app to re-evaluate startup state, which will redirect to onboarding
      // since the user is no longer authenticated
      ref.invalidate(appStartupProvider);
    } catch (e) {
      // Handle logout error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).translate('logout-error'),
            style: TextStyles.body.copyWith(color: Colors.white),
          ),
          backgroundColor: theme.error[600],
        ),
      );
    } finally {
      _isLoggingOut = false;
    }
  }
}
