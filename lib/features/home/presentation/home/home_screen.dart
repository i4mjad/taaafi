import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/calender_widget.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/follow_up_sheet.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/statistics_widget.dart';

class HomeScreen extends ConsumerWidget {
  HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, 'home', false, true),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              StatisticsWidget(),
              verticalSpace(Spacing.points16),
              CalenderWidget()
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.primary[600],
        onPressed: () {
          showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (BuildContext context) {
                return FollowUpSheet();
              });
        },
        label: Text(
          AppLocalizations.of(context).translate("daily-follow-up"),
          style: TextStyles.caption.copyWith(color: theme.grey[50]),
        ),
        icon: Icon(LucideIcons.pencil, color: theme.grey[50]),
      ),
    );
  }
}
