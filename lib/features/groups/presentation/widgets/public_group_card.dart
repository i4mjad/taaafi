import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';

/// Model for public groups that can be discovered and joined
class DiscoverableGroup {
  final String id;
  final String name;
  final String? description;
  final int memberCount;
  final int capacity;
  final String gender; // 'male' | 'female' | 'mixed'
  final String joinMethod; // 'any' | 'code_only'
  final DateTime createdAt;
  final bool isActive;
  final String? lastActivityTime; // e.g., "2 hours ago"
  final List<String> tags; // e.g., ['Recovery', 'Support', 'Arabic']
  final int challengesCount;

  const DiscoverableGroup({
    required this.id,
    required this.name,
    this.description,
    required this.memberCount,
    required this.capacity,
    required this.gender,
    required this.joinMethod,
    required this.createdAt,
    this.isActive = true,
    this.lastActivityTime,
    this.tags = const [],
    this.challengesCount = 0,
  });
}

class PublicGroupCard extends ConsumerWidget {
  final DiscoverableGroup group;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  final bool showJoinButton;

  const PublicGroupCard({
    super.key,
    required this.group,
    this.onTap,
    this.onJoin,
    this.showJoinButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return WidgetsContainer(
      backgroundColor: theme.backgroundColor,
      borderSide: BorderSide(
        color: theme.grey[200]!,
        width: 1,
      ),
      borderRadius: BorderRadius.circular(16),
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(Spacing.points16.value),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Group Icon, Name & Status
              Row(
                children: [
                  // Group Icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _getGenderColor(theme),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.users,
                      color: _getGenderIconColor(theme),
                      size: 28,
                    ),
                  ),

                  horizontalSpace(Spacing.points12),

                  // Group Name & Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                group.name,
                                style: TextStyles.h6.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.grey[900],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            horizontalSpace(Spacing.points8),
                            _buildStatusBadge(theme, l10n),
                          ],
                        ),
                        verticalSpace(Spacing.points4),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.users2,
                              size: 14,
                              color: theme.grey[500],
                            ),
                            horizontalSpace(Spacing.points4),
                            Text(
                              '${group.memberCount}/${group.capacity} ${l10n.translate('group-member-count')}',
                              style: TextStyles.caption.copyWith(
                                color: theme.grey[600],
                              ),
                            ),
                            const Spacer(),
                            _buildGenderBadge(theme, l10n),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              verticalSpace(Spacing.points12),

              // Description
              if (group.description != null) ...[
                Text(
                  group.description!,
                  style: TextStyles.body.copyWith(
                    color: theme.grey[700],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                verticalSpace(Spacing.points12),
              ],

              // Tags
              if (group.tags.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: group.tags.take(3).map((tag) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Spacing.points8.value,
                        vertical: Spacing.points4.value,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primary[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.primary[200]!,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextStyles.caption.copyWith(
                          color: theme.primary[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                verticalSpace(Spacing.points12),
              ],

              // Metadata Row
              Row(
                children: [
                  // Created time
                  Icon(
                    LucideIcons.clock,
                    size: 14,
                    color: theme.grey[500],
                  ),
                  horizontalSpace(Spacing.points4),
                  Text(
                    _formatCreatedTime(group.createdAt, l10n),
                    style: TextStyles.caption.copyWith(
                      color: theme.grey[600],
                    ),
                  ),

                  horizontalSpace(Spacing.points16),

                  // Challenges count
                  Icon(
                    LucideIcons.trophy,
                    size: 14,
                    color: theme.grey[500],
                  ),
                  horizontalSpace(Spacing.points4),
                  Text(
                    '${group.challengesCount} ${l10n.translate('group-challenge-count')}',
                    style: TextStyles.caption.copyWith(
                      color: theme.grey[600],
                    ),
                  ),

                  const Spacer(),

                  // Last activity
                  if (group.lastActivityTime != null) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Spacing.points8.value,
                        vertical: Spacing.points4.value,
                      ),
                      decoration: BoxDecoration(
                        color: theme.success[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: theme.success[500],
                              shape: BoxShape.circle,
                            ),
                          ),
                          horizontalSpace(Spacing.points4),
                          Text(
                            group.lastActivityTime!,
                            style: TextStyles.caption.copyWith(
                              color: theme.success[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              // Join Button
              if (showJoinButton) ...[
                verticalSpace(Spacing.points16),
                SizedBox(
                  width: double.infinity,
                  child: _buildJoinButton(theme, l10n),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(CustomThemeData theme, AppLocalizations l10n) {
    if (group.isActive) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: Spacing.points8.value,
          vertical: Spacing.points4.value,
        ),
        decoration: BoxDecoration(
          color: theme.success[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          l10n.translate('group-active'),
          style: TextStyles.caption.copyWith(
            color: theme.success[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    } else {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: Spacing.points8.value,
          vertical: Spacing.points4.value,
        ),
        decoration: BoxDecoration(
          color: theme.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          l10n.translate('group-inactive'),
          style: TextStyles.caption.copyWith(
            color: theme.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
  }

  Widget _buildGenderBadge(CustomThemeData theme, AppLocalizations l10n) {
    Color bgColor;
    Color textColor;
    String text;

    switch (group.gender.toLowerCase()) {
      case 'male':
        bgColor = theme.primary[100]!;
        textColor = theme.primary[700]!;
        text = l10n.translate('male-only');
        break;
      case 'female':
        bgColor = theme.secondary[100]!;
        textColor = theme.secondary[700]!;
        text = l10n.translate('female-only');
        break;
      default:
        bgColor = theme.grey[100]!;
        textColor = theme.grey[700]!;
        text = l10n.translate('mixed');
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Spacing.points8.value,
        vertical: Spacing.points4.value,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyles.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildJoinButton(CustomThemeData theme, AppLocalizations l10n) {
    final isCapacityFull = group.memberCount >= group.capacity;
    final needsCode = group.joinMethod == 'code_only';

    return GestureDetector(
      onTap: isCapacityFull ? null : onJoin,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: Spacing.points12.value),
        decoration: BoxDecoration(
          color: isCapacityFull
              ? theme.grey[200]
              : needsCode
                  ? theme.warn[500]
                  : theme.primary[600],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCapacityFull
                  ? LucideIcons.userX
                  : needsCode
                      ? LucideIcons.key
                      : LucideIcons.userPlus,
              size: 16,
              color: isCapacityFull ? theme.grey[500] : Colors.white,
            ),
            horizontalSpace(Spacing.points8),
            Text(
              isCapacityFull
                  ? l10n.translate('group-full')
                  : needsCode
                      ? l10n.translate('join-with-code')
                      : l10n.translate('join-group'),
              style: TextStyles.footnote.copyWith(
                color: isCapacityFull ? theme.grey[500] : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getGenderColor(CustomThemeData theme) {
    switch (group.gender.toLowerCase()) {
      case 'male':
        return theme.primary[100]!;
      case 'female':
        return theme.secondary[100]!;
      default:
        return theme.grey[100]!;
    }
  }

  Color _getGenderIconColor(CustomThemeData theme) {
    switch (group.gender.toLowerCase()) {
      case 'male':
        return theme.primary[600]!;
      case 'female':
        return theme.secondary[600]!;
      default:
        return theme.grey[600]!;
    }
  }

  String _formatCreatedTime(DateTime createdAt, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return l10n
          .translate('group-months-ago')
          .replaceAll('{months}', months.toString());
    } else if (difference.inDays > 0) {
      return l10n
          .translate('group-days-ago')
          .replaceAll('{days}', difference.inDays.toString());
    } else if (difference.inHours > 0) {
      return l10n
          .translate('group-hours-ago')
          .replaceAll('{hours}', difference.inHours.toString());
    } else {
      return l10n.translate('just-created');
    }
  }
}
