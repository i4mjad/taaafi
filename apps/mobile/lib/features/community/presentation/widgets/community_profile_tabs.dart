import 'package:flutter/material.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class CommunityProfileTabs extends StatefulWidget {
  final Function(int) onTabChanged;
  final int initialIndex;

  const CommunityProfileTabs({
    super.key,
    required this.onTabChanged,
    this.initialIndex = 0,
  });

  @override
  State<CommunityProfileTabs> createState() => _CommunityProfileTabsState();
}

class _CommunityProfileTabsState extends State<CommunityProfileTabs> {
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildTab(
            index: 0,
            title: localizations.translate('community-posts'),
            theme: theme,
          ),
          _buildTab(
            index: 1,
            title: localizations.translate('community-comments'),
            theme: theme,
          ),
          _buildTab(
            index: 2,
            title: localizations.translate('community-likes'),
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required int index,
    required String title,
    required CustomThemeData theme,
  }) {
    final isSelected = selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedIndex = index;
          });
          widget.onTabChanged(index);
        },
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? theme.grey[900]! : Colors.transparent,
                width: isSelected ? 2 : 0,
              ),
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyles.body.copyWith(
                color: isSelected ? theme.grey[900] : theme.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
