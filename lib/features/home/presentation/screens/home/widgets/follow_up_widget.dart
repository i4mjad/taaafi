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
      backgroundColor: theme.primary[50],
      borderSide: BorderSide(
        color: isSelected ? theme.success[600]! : theme.primary[100]!,
        width: isSelected ? 2 : 1,
      ),
      padding: EdgeInsets.all(4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
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
