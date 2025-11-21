import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/shared_widgets/container.dart';
import '../../../../core/theming/app-themes.dart';
import '../../../../core/theming/text_styles.dart';

enum ShareMethod {
  whatsapp,
  sms,
  email,
  copyLink,
  more,
}

class ShareOptionsSheet extends ConsumerWidget {
  final String referralCode;
  final Function(ShareMethod) onShareMethodSelected;

  const ShareOptionsSheet({
    super.key,
    required this.referralCode,
    required this.onShareMethodSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.translate('referral.share.sheet_title'),
                  style: TextStyles.h5.copyWith(
                    color: theme.primary[900]!,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  LucideIcons.x,
                  color: theme.grey[400]!,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            l10n.translate('referral.share.sheet_subtitle'),
            style: TextStyles.body.copyWith(
              color: theme.grey[500]!,
            ),
          ),
          const SizedBox(height: 24),

          // Code display
          WidgetsContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            backgroundColor: theme.primary[50]!,
            borderSide: BorderSide(color: theme.primary[200]!, width: 1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.translate('referral.share.your_code'),
                  style: TextStyles.caption.copyWith(
                    color: theme.primary[600]!,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  referralCode,
                  style: TextStyles.h6.copyWith(
                    color: theme.primary[700]!,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Share options
          _ShareOption(
            icon: LucideIcons.messageCircle,
            iconColor: const Color(0xFF25D366), // WhatsApp green
            label: l10n.translate('referral.share.whatsapp'),
            onTap: () {
              Navigator.of(context).pop();
              onShareMethodSelected(ShareMethod.whatsapp);
            },
          ),
          const SizedBox(height: 12),

          _ShareOption(
            icon: LucideIcons.messageSquare,
            iconColor: theme.primary[600]!,
            label: l10n.translate('referral.share.sms'),
            onTap: () {
              Navigator.of(context).pop();
              onShareMethodSelected(ShareMethod.sms);
            },
          ),
          const SizedBox(height: 12),

          _ShareOption(
            icon: LucideIcons.mail,
            iconColor: theme.primary[600]!,
            label: l10n.translate('referral.share.email'),
            onTap: () {
              Navigator.of(context).pop();
              onShareMethodSelected(ShareMethod.email);
            },
          ),
          const SizedBox(height: 12),

          _ShareOption(
            icon: LucideIcons.copy,
            iconColor: theme.primary[600]!,
            label: l10n.translate('referral.share.copy_link'),
            onTap: () {
              Navigator.of(context).pop();
              onShareMethodSelected(ShareMethod.copyLink);
            },
          ),
          const SizedBox(height: 12),

          _ShareOption(
            icon: LucideIcons.share2,
            iconColor: theme.grey[600]!,
            label: l10n.translate('referral.share.more_options'),
            onTap: () {
              Navigator.of(context).pop();
              onShareMethodSelected(ShareMethod.more);
            },
          ),
        ],
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: WidgetsContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderSide: BorderSide(color: theme.grey[100]!, width: 1.5),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyles.body.copyWith(
                  color: theme.primary[900]!,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: theme.grey[400]!,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

