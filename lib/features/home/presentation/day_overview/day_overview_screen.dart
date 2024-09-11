import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/follow_up_sheet.dart';

class DayOverviewScreen extends ConsumerWidget {
  final DateTime date;

  const DayOverviewScreen({
    Key? key,
    required this.date,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeNotifierProvider);
    final theme = AppTheme.of(context);
    return Scaffold(
      appBar: plainAppBar(context, ref,
          getDisplayDate(date, locale!.languageCode), false, true),
      backgroundColor: theme.backgroundColor,
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width - 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).translate('day-overview'),
                  style: TextStyles.h6,
                ),
                verticalSpace(Spacing.points12),
                Container(
                  width: MediaQuery.of(context).size.width - 32,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context).translate('no-follow-ups'),
                        style: TextStyles.footnote,
                      )
                    ],
                  ),
                ),
                verticalSpace(Spacing.points12),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (BuildContext context) {
                          return FollowUpSheet(date);
                        });
                  },
                  child: WidgetsContainer(
                    backgroundColor: theme.primary[100],
                    borderSide: BorderSide(color: theme.primary[100]!),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)
                            .translate('add-follow-ups'),
                        style:
                            TextStyles.h6.copyWith(color: theme.primary[900]),
                      ),
                    ),
                  ),
                ),
                verticalSpace(Spacing.points32),
                Text(
                  AppLocalizations.of(context).translate('diaries'),
                  style: TextStyles.h6,
                ),
                verticalSpace(Spacing.points12),
                Container(
                  width: MediaQuery.of(context).size.width - 32,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context).translate('no-notes'),
                        style: TextStyles.footnote,
                      )
                    ],
                  ),
                ),
                verticalSpace(Spacing.points12),
                WidgetsContainer(
                  backgroundColor: theme.tint[100],
                  borderSide: BorderSide(color: theme.tint[100]!),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context).translate('add-note'),
                      style: TextStyles.h6.copyWith(color: theme.tint[900]),
                    ),
                  ),
                ),
                verticalSpace(Spacing.points32),
                Text(
                  AppLocalizations.of(context).translate('emotions'),
                  style: TextStyles.h6,
                ),
                verticalSpace(Spacing.points12),
                Container(
                  width: MediaQuery.of(context).size.width - 32,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context).translate('no-emotions'),
                        style: TextStyles.footnote,
                      )
                    ],
                  ),
                ),
                verticalSpace(Spacing.points16),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (BuildContext context) {
                          return FollowUpSheet(date);
                        });
                  },
                  child: WidgetsContainer(
                    backgroundColor: theme.secondary[100],
                    borderSide: BorderSide(color: theme.secondary[100]!),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context).translate('add-emotions'),
                        style: TextStyles.h6.copyWith(
                          color: theme.secondary[900],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
