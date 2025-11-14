import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/localization/localization.dart';

/// Achievement badge widget
/// Sprint 4 - Feature 4.1: Enhanced Member Profiles
class AchievementBadgeWidget extends StatelessWidget {
  final String achievementType;
  final bool isEarned;
  final DateTime? earnedAt;
  final VoidCallback? onTap;

  const AchievementBadgeWidget({
    super.key,
    required this.achievementType,
    required this.isEarned,
    this.earnedAt,
    this.onTap,
  });

  IconData _getIcon(String type) {
    switch (type) {
      case 'welcome':
        return LucideIcons.userPlus;
      case 'first_message':
        return LucideIcons.messageCircle;
      case 'week_warrior':
        return LucideIcons.flame;
      case 'month_master':
        return LucideIcons.trophy;
      case 'helpful':
        return LucideIcons.heart;
      case 'top_contributor':
        return LucideIcons.star;
      default:
        return LucideIcons.award;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isEarned ? theme.tint[600]! : theme.grey[300]!,
            width: 2,
          ),
          color: isEarned
              ? theme.tint[50]
              : theme.grey[100],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              _getIcon(achievementType),
              size: 28,
              color: isEarned ? theme.tint[600] : theme.grey[400],
            ),
            if (!isEarned)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: theme.grey[500],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.lock,
                    size: 12,
                    color: theme.backgroundColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Achievement details modal
class AchievementDetailsModal extends StatelessWidget {
  final String achievementType;
  final String title;
  final String description;
  final bool isEarned;
  final DateTime? earnedAt;

  const AchievementDetailsModal({
    super.key,
    required this.achievementType,
    required this.title,
    required this.description,
    required this.isEarned,
    this.earnedAt,
  });

  IconData _getIcon(String type) {
    switch (type) {
      case 'welcome':
        return LucideIcons.userPlus;
      case 'first_message':
        return LucideIcons.messageCircle;
      case 'week_warrior':
        return LucideIcons.flame;
      case 'month_master':
        return LucideIcons.trophy;
      case 'helpful':
        return LucideIcons.heart;
      case 'top_contributor':
        return LucideIcons.star;
      default:
        return LucideIcons.award;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Badge
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isEarned ? theme.tint[600]! : theme.grey[300]!,
                width: 3,
              ),
              color: isEarned ? theme.tint[50] : theme.grey[100],
            ),
            child: Icon(
              _getIcon(achievementType),
              size: 42,
              color: isEarned ? theme.tint[600] : theme.grey[400],
            ),
          ),

          const SizedBox(height: 16),

          // Title
          Text(
            l10n.translate(title),
            style: TextStyles.h5.copyWith(
              color: theme.grey[900],
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Description
          Text(
            l10n.translate(description),
            style: TextStyles.body.copyWith(
              color: theme.grey[600],
            ),
            textAlign: TextAlign.center,
          ),

          if (isEarned && earnedAt != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.tint[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.calendar,
                    size: 16,
                    color: theme.tint[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(earnedAt!, l10n),
                    style: TextStyles.footnote.copyWith(
                      color: theme.tint[700],
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (!isEarned) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.lock,
                    size: 16,
                    color: theme.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.translate('not-earned-yet'),
                    style: TextStyles.footnote.copyWith(
                      color: theme.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Close button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.tint[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.translate('close'),
                style: TextStyles.h6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return l10n.translate('today');
    } else if (difference.inDays == 1) {
      return l10n.translate('yesterday');
    } else if (difference.inDays < 7) {
      return l10n.translate('days-ago').replaceAll('{days}', '${difference.inDays}');
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Show achievement details modal
void showAchievementDetails({
  required BuildContext context,
  required String achievementType,
  required String title,
  required String description,
  required bool isEarned,
  DateTime? earnedAt,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AchievementDetailsModal(
      achievementType: achievementType,
      title: title,
      description: description,
      isEarned: isEarned,
      earnedAt: earnedAt,
    ),
  );
}

