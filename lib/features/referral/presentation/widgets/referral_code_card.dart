import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/shared_widgets/snackbar.dart';
import '../../../../core/theming/app-themes.dart';
import '../../../../core/theming/spacing.dart';
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

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primary[500]!,
            theme.primary[700]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.primary[500]!.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('referral.dashboard.your_code'),
            style: TextStyles.body.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          
          // Code display with copy and share buttons
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      code,
                      style: TextStyles.h4.copyWith(
                        color: Colors.white,
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
              _ActionButton(
                icon: LucideIcons.share2,
                onTap: () => _shareCode(context, l10n),
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, AppLocalizations l10n) {
    Clipboard.setData(ClipboardData(text: code));
    showCustomSnackbar(
      context,
      l10n.translate('referral.dashboard.code_copied'),
      SnackbarType.success,
    );
  }

  void _shareCode(BuildContext context, AppLocalizations l10n) {
    final message = _buildShareMessage(code, l10n);
    
    Share.share(
      message,
      subject: l10n.translate('referral.dashboard.share_subject'),
    );

    if (onShare != null) {
      onShare!();
    }
  }

  String _buildShareMessage(String code, AppLocalizations l10n) {
    // Build localized share message
    return l10n.translate('referral.dashboard.share_message')
        .replaceAll('{code}', code);
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
    return Material(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

