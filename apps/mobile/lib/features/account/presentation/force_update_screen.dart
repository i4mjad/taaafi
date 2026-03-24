import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/routing/app_startup.dart';
import 'package:reboot_app_3/features/account/application/startup_security_service.dart';

/// Full-screen blocking widget shown when a forced app update is required.
/// User cannot dismiss or navigate away — must update via the store.
class ForceUpdateScreen extends ConsumerStatefulWidget {
  final SecurityStartupResult securityResult;

  const ForceUpdateScreen({
    Key? key,
    required this.securityResult,
  }) : super(key: key);

  @override
  ConsumerState<ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends ConsumerState<ForceUpdateScreen> {
  bool _isRefreshing = false;

  String _getLocalizedText(Map<String, String>? localizedMap, String locale) {
    if (localizedMap == null) return '';
    return localizedMap[locale] ?? localizedMap['ar'] ?? '';
  }

  Future<void> _openStore() async {
    final storeLink = widget.securityResult.storeLink;
    if (storeLink == null || storeLink.isEmpty) return;

    final uri = Uri.parse(storeLink);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    ref.invalidate(appStartupProvider);

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeNotifierProvider);
    final localeCode = locale?.languageCode ?? 'ar';

    final title = _getLocalizedText(
      widget.securityResult.updateTitle,
      localeCode,
    );
    final message = _getLocalizedText(
      widget.securityResult.updateMessage,
      localeCode,
    );

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.primary[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.arrowUpCircle,
                  size: 80,
                  color: theme.primary[600],
                ),
              ),

              verticalSpace(Spacing.points32),

              // Title
              Text(
                title.isNotEmpty
                    ? title
                    : l10n.translate('force-update-title'),
                style: TextStyles.h1.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primary[900],
                ),
                textAlign: TextAlign.center,
              ),

              verticalSpace(Spacing.points16),

              // Message
              Text(
                message.isNotEmpty
                    ? message
                    : l10n.translate('force-update-message'),
                style: TextStyles.body.copyWith(
                  color: theme.grey[700],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              verticalSpace(Spacing.points32),

              // Update Now button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _openStore();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.externalLink, size: 20),
                      horizontalSpace(Spacing.points8),
                      Text(
                        l10n.translate('update-now'),
                        style: TextStyles.body.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              verticalSpace(Spacing.points16),

              // Refresh button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _isRefreshing ? null : () {
                    HapticFeedback.lightImpact();
                    _refresh();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.primary[600],
                    side: BorderSide(color: theme.primary[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isRefreshing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: Spinner(strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.refreshCw, size: 18),
                            horizontalSpace(Spacing.points8),
                            Text(
                              l10n.translate('force-update-refresh'),
                              style: TextStyles.footnote.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
