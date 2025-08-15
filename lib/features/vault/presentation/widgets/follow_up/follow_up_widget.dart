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
      backgroundColor: theme.backgroundColor,
      padding: EdgeInsets.all(8),
      borderSide: BorderSide(
        color: isSelected ? theme.success[600]! : theme.grey[600]!,
        width: isSelected ? 1 : 0.5,
      ),
      boxShadow: Shadows.mainShadows,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: theme.primary[700]),
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
