import 'package:flutter/cupertino.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class FollowUpWidget extends StatelessWidget {
  const FollowUpWidget({
    super.key,
    required this.icon,
    required this.translationKey,
    required this.isSelected,
  });

  final IconData icon;
  final String translationKey;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return WidgetsContainer(
      cornerSmoothing: 1,
      backgroundColor: theme.backgroundColor,
      padding: EdgeInsets.all(8),
      borderSide: BorderSide(
        color: isSelected ? theme.success[600]! : theme.grey[600]!,
      ),
      boxShadow: [
        BoxShadow(
          color: Color.fromRGBO(9, 30, 66, 0.25),
          blurRadius: 8,
          spreadRadius: -2,
          offset: Offset(
            0,
            4,
          ),
        ),
        BoxShadow(
          color: Color.fromRGBO(9, 30, 66, 0.08),
          blurRadius: 0,
          spreadRadius: 1,
          offset: Offset(
            0,
            0,
          ),
        ),
      ],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: theme.primary[600]),
          verticalSpace(Spacing.points8),
          Text(
            AppLocalizations.of(context).translate(translationKey),
            style: TextStyles.footnote,
          ),
        ],
      ),
    );
  }
}
