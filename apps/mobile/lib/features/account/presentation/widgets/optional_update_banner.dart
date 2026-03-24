import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/app_startup.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

const _kDismissedAtKey = 'optional_update_dismissed_at';
const _kDismissedVersionKey = 'optional_update_dismissed_version';

/// Dismissible banner shown on the home screen when an optional update is available.
/// Respects admin-configured cooldown and resets when minimumVersion changes.
class OptionalUpdateBanner extends ConsumerStatefulWidget {
  const OptionalUpdateBanner({super.key});

  @override
  ConsumerState<OptionalUpdateBanner> createState() =>
      _OptionalUpdateBannerState();
}

class _OptionalUpdateBannerState extends ConsumerState<OptionalUpdateBanner> {
  bool _dismissed = false;
  bool _shouldShow = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _checkDismissalState();
  }

  Future<void> _checkDismissalState() async {
    final startupState = ref.read(appStartupProvider);
    final securityResult = startupState.valueOrNull;

    if (securityResult == null || !securityResult.hasUpdate) {
      if (mounted) setState(() { _checked = true; _shouldShow = false; });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final dismissedAt = prefs.getInt(_kDismissedAtKey);
    final dismissedVersion = prefs.getString(_kDismissedVersionKey);
    final currentMinVersion = securityResult.minimumVersion ?? '';
    final cooldownHours = securityResult.dismissCooldownHours ?? 24;

    // Reset dismissal if admin changed the minimum version
    if (dismissedVersion != null && dismissedVersion != currentMinVersion) {
      await prefs.remove(_kDismissedAtKey);
      await prefs.remove(_kDismissedVersionKey);
      if (mounted) setState(() { _checked = true; _shouldShow = true; });
      return;
    }

    // Check cooldown
    if (dismissedAt != null) {
      final dismissedTime =
          DateTime.fromMillisecondsSinceEpoch(dismissedAt);
      final cooldownEnd =
          dismissedTime.add(Duration(hours: cooldownHours));
      if (DateTime.now().isBefore(cooldownEnd)) {
        if (mounted) setState(() { _checked = true; _shouldShow = false; });
        return;
      }
    }

    if (mounted) setState(() { _checked = true; _shouldShow = true; });
  }

  Future<void> _dismiss() async {
    final securityResult = ref.read(appStartupProvider).valueOrNull;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        _kDismissedAtKey, DateTime.now().millisecondsSinceEpoch);
    await prefs.setString(
        _kDismissedVersionKey, securityResult?.minimumVersion ?? '');
    if (mounted) setState(() => _dismissed = true);
  }

  Future<void> _openStore(String? storeLink) async {
    if (storeLink == null || storeLink.isEmpty) return;
    final uri = Uri.parse(storeLink);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _getLocalizedText(Map<String, String>? localizedMap, String locale) {
    if (localizedMap == null) return '';
    return localizedMap[locale] ?? localizedMap['ar'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked || !_shouldShow || _dismissed) {
      return const SizedBox.shrink();
    }

    final startupState = ref.watch(appStartupProvider);
    final securityResult = startupState.valueOrNull;

    if (securityResult == null || !securityResult.hasUpdate) {
      return const SizedBox.shrink();
    }

    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeNotifierProvider);
    final localeCode = locale?.languageCode ?? 'ar';

    final title = _getLocalizedText(securityResult.updateTitle, localeCode);
    final message = _getLocalizedText(securityResult.updateMessage, localeCode);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: WidgetsContainer(
        padding: const EdgeInsets.all(16),
        backgroundColor: theme.primary[50],
        borderSide: BorderSide(color: theme.primary[200]!, width: 1),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.arrowUpCircle,
                  size: 24,
                  color: theme.primary[600],
                ),
                horizontalSpace(Spacing.points12),
                Expanded(
                  child: Text(
                    title.isNotEmpty
                        ? title
                        : l10n.translate('optional-update-title'),
                    style: TextStyles.h6.copyWith(
                      color: theme.primary[900],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Dismiss button
                IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _dismiss();
                  },
                  icon: Icon(
                    LucideIcons.x,
                    size: 18,
                    color: theme.grey[500],
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            if (message.isNotEmpty ||
                l10n.translate('optional-update-message').isNotEmpty) ...[
              verticalSpace(Spacing.points8),
              Text(
                message.isNotEmpty
                    ? message
                    : l10n.translate('optional-update-message'),
                style: TextStyles.small.copyWith(
                  color: theme.primary[800],
                  height: 1.4,
                ),
              ),
            ],
            verticalSpace(Spacing.points16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _openStore(securityResult.storeLink);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        l10n.translate('update-now'),
                        style: TextStyles.footnote.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                horizontalSpace(Spacing.points12),
                SizedBox(
                  height: 40,
                  child: TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _dismiss();
                    },
                    child: Text(
                      l10n.translate('not-now'),
                      style: TextStyles.footnote.copyWith(
                        color: theme.grey[600],
                        fontWeight: FontWeight.w500,
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
}
