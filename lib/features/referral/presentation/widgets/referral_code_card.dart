import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/shared_widgets/snackbar.dart';
import '../../../../core/theming/app-themes.dart';
import '../../../../core/theming/text_styles.dart';

class ReferralCodeCard extends ConsumerWidget {
  final String code;
  final VoidCallback? onShare;

  const ReferralCodeCard({
    super.key,
    required this.code,
    this.onShare,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return WidgetsContainer(
      padding: const EdgeInsets.all(20),
      backgroundColor: theme.backgroundColor,
      borderSide: BorderSide(width: 1, color: theme.primary[700]!),
      // boxShadow: Shadows.mainShadows,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('referral.dashboard.your_code'),
            style: TextStyles.body.copyWith(
              color: theme.primary[700]!,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // Code display with copy and share buttons
          Row(
            children: [
              Expanded(
                child: WidgetsContainer(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  borderSide: BorderSide(
                    color: theme.grey[100]!,
                    width: 1.5,
                  ),
                  child: Center(
                    child: Text(
                      code,
                      style: TextStyles.h4.copyWith(
                        color: theme.primary[600]!,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Copy button
              _ActionButton(
                icon: LucideIcons.copy,
                onTap: () => _copyToClipboard(context, l10n),
                theme: theme,
              ),
              const SizedBox(width: 8),

              // Share button
              Builder(
                builder: (buttonContext) => _ActionButton(
                  icon: LucideIcons.share2,
                  onTap: () => _shareCode(buttonContext, l10n),
                  theme: theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, AppLocalizations l10n) {
    Clipboard.setData(ClipboardData(text: code));
    getSuccessSnackBar(context, 'referral.dashboard.code_copied');
  }

  void _shareCode(BuildContext context, AppLocalizations l10n) {
    // Use generic share message
    final shareMessage = l10n
        .translate('referral.share.generic_message')
        .replaceAll('{code}', code)
        .replaceAll('{userName}', l10n.translate('referral.share.default_user'));

    // Get the position of the share button for iPad popover
    final box = context.findRenderObject() as RenderBox?;
    final sharePositionOrigin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;

    // Share using the system share sheet
    Share.share(
      shareMessage,
      subject: l10n.translate('referral.share.subject'),
      sharePositionOrigin: sharePositionOrigin,
    );

    // Track analytics
    FirebaseAnalytics.instance.logEvent(
      name: 'referral_code_shared',
      parameters: {
        'method': 'generic_share',
        'referral_code': code,
      },
    );

    // Callback for parent widget
    if (onShare != null) {
      onShare!();
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final dynamic theme;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: WidgetsContainer(
        padding: const EdgeInsets.all(14),
        borderSide: BorderSide(
          color: theme.grey[100]!,
          width: 1.5,
        ),
        child: Icon(
          icon,
          color: theme.primary[600]!,
          size: 22,
        ),
      ),
    );
  }
}
