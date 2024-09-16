import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class VaultScreen extends ConsumerWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
          child: Container(
            width: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              // mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SvgPicture.asset(
                  'asset/illustrations/vault-hero-image.svg',
                ),
                verticalSpace(Spacing.points24),
                Text(
                  AppLocalizations.of(context).translate('vault'),
                  style: TextStyles.h1,
                ),
                verticalSpace(Spacing.points12),
                Text(
                  AppLocalizations.of(context).translate('vault-p'),
                  style: TextStyles.footnoteSelected.copyWith(
                    color: theme.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: WidgetsContainer(
                        backgroundColor: theme.primary[50],
                        borderSide: BorderSide(color: theme.primary[100]!),
                        padding: EdgeInsets.all(14),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(LucideIcons.clipboardCheck,
                                color: theme.primary[900]),
                            verticalSpace(Spacing.points28),
                            Text(
                              AppLocalizations.of(context)
                                  .translate('activities'),
                              style: TextStyles.h3
                                  .copyWith(color: theme.primary[900]),
                            )
                          ],
                        ),
                      ),
                    ),
                    horizontalSpace(Spacing.points8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          context.goNamed(RouteNames.diaries.name);
                        },
                        child: WidgetsContainer(
                          backgroundColor: theme.secondary[50],
                          borderSide: BorderSide(color: theme.secondary[100]!),
                          padding: EdgeInsets.all(14),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(LucideIcons.pencil,
                                  color: theme.secondary[900]),
                              verticalSpace(Spacing.points28),
                              Text(
                                AppLocalizations.of(context)
                                    .translate('diaries'),
                                style: TextStyles.h3
                                    .copyWith(color: theme.secondary[900]),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                verticalSpace(Spacing.points8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          context.goNamed(RouteNames.library.name);
                        },
                        child: WidgetsContainer(
                          backgroundColor: theme.tint[50],
                          borderSide: BorderSide(color: theme.tint[400]!),
                          padding: EdgeInsets.all(14),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(LucideIcons.lamp, color: theme.tint[900]),
                              verticalSpace(Spacing.points28),
                              Text(
                                AppLocalizations.of(context)
                                    .translate('library'),
                                style: TextStyles.h3
                                    .copyWith(color: theme.tint[900]),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    horizontalSpace(Spacing.points8),
                    Expanded(
                      child: WidgetsContainer(
                        backgroundColor: theme.secondary[50],
                        borderSide: BorderSide(color: theme.primary[200]!),
                        padding: EdgeInsets.all(14),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              LucideIcons.settings2,
                              color: theme.primary[900],
                            ),
                            verticalSpace(Spacing.points28),
                            Text(
                              AppLocalizations.of(context)
                                  .translate('settings'),
                              style: TextStyles.h3.copyWith(
                                color: theme.primary[900],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
