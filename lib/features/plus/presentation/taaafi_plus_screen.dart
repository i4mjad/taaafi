import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class TaaafiPlusScreen extends ConsumerWidget {
  const TaaafiPlusScreen({super.key});

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
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'asset/illustrations/plus-hero-image.svg',
                  ),
                  verticalSpace(Spacing.points24),
                  Text(
                    AppLocalizations.of(context).translate('taaafi-groups'),
                    style: TextStyles.h1,
                  ),
                  verticalSpace(Spacing.points12),
                  WidgetsContainer(
                    width: width / 2,
                    borderSide: BorderSide(color: theme.secondary[200]!),
                    backgroundColor: theme.secondary[700],
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context).translate('soon'),
                        style: TextStyles.h4.copyWith(
                          color: theme.backgroundColor,
                        ),
                      ),
                    ),
                  ),
                  verticalSpace(Spacing.points24),
                  Container(
                    padding: EdgeInsets.only(left: 32, right: 32),
                    child: Column(
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Icon(LucideIcons.users),
                            horizontalSpace(Spacing.points16),
                            Wrap(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "لست وحدك",
                                      style: TextStyles.h5.copyWith(
                                        color: theme.primary[600],
                                      ),
                                    ),
                                    verticalSpace(Spacing.points8),
                                    Text(
                                      "تعرف على التجارب المختلفة وشارك تجربتك مع مجموعة من المتعافين لتبادل الخبرات واكتشاف التحديات في رحلة التعافي",
                                      style: TextStyles.footnote.copyWith(
                                        color: theme.grey[700],
                                      ),
                                      softWrap:
                                          true, // Wrap text to the next line
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
